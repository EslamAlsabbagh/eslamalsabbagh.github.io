import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tasks/data/live_changes.dart';
import '../../tasks/data/task_file.dart';
import '../data/contract_list_item.dart';
import '../data/contracts_repository.dart';
import 'contract_filters.dart';
import 'contract_groups.dart';

export 'contract_filters.dart';
export 'contract_groups.dart';

part 'contracts_event.dart';
part 'contracts_state.dart';

/// The «العقود» view (DESIGN_SPEC §4 "View 4 — العقود"). Provided by the
/// shell and created the first time the tab opens, so its search and filters
/// last while someone is signed in, and nobody who never opens the tab reads
/// the contracts.
///
/// It follows other people's changes like the task lists (ADR-0007): a
/// contracts-table change, a `tasks` change (the follow-up counts), a
/// membership change or a rejoin reads the list again quietly.
class ContractsBloc extends Bloc<ContractsEvent, ContractsState> {
  ContractsBloc({
    required this._repository,
    Stream<LiveChange> liveChanges = const Stream.empty(),
    this._searchDelay = const Duration(milliseconds: 300),
    this._liveDelay = const Duration(milliseconds: 500),
  }) : super(const ContractsState()) {
    on<ContractsLoadRequested>(_onLoadRequested);
    on<ContractsRefreshRequested>(_onRefreshRequested);
    on<ContractsSearchChanged>(_onSearchChanged);
    on<ContractsFiltersChanged>(_onFiltersChanged);
    on<ContractsTerminatedToggled>(_onTerminatedToggled);
    _liveSubscription = liveChanges.where(_concernsContracts).listen(_onLiveChange);
  }

  final ContractsRepository _repository;

  /// The pause in typing before a search is sent.
  final Duration _searchDelay;

  /// How long a burst of changes is gathered into one read.
  final Duration _liveDelay;

  late final StreamSubscription<LiveChange> _liveSubscription;
  Timer? _liveTimer;

  /// Reads are numbered, so an older one that lands after a newer one is
  /// dropped instead of putting stale rows back.
  int _fetchesStarted = 0;
  int _fetchApplied = 0;

  /// The tables the list is read from or counts, and who sees which file.
  /// File and topic names come from the shell's lists, which follow those.
  static bool _concernsContracts(LiveChange change) =>
      change.resync ||
      LiveTable.contractTables.contains(change.table) ||
      change.table == LiveTable.tasks ||
      change.table == LiveTable.fileMembers;

  /// Nothing is read before the first load has landed: that load, or its
  /// retry, reads everything anyway.
  void _onLiveChange(LiveChange _) {
    _liveTimer?.cancel();
    _liveTimer = Timer(_liveDelay, () {
      if (!isClosed && state.status == ContractsStatus.success) add(const ContractsRefreshRequested());
    });
  }

  @override
  Future<void> close() async {
    _liveTimer?.cancel();
    await _liveSubscription.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(ContractsLoadRequested event, Emitter<ContractsState> emit) async {
    emit(state.copyWith(status: ContractsStatus.loading));
    try {
      await _fetch(emit);
    } catch (error, stackTrace) {
      log('Loading contracts failed', name: 'contracts', error: error, stackTrace: stackTrace);
      emit(state.copyWith(status: ContractsStatus.failure));
      return;
    }
    await _researchIfActive(emit);
  }

  /// Keeps the last list on a failure: the next change or rejoin reads again.
  /// Before the first load has landed there is nothing to refresh.
  Future<void> _onRefreshRequested(ContractsRefreshRequested event, Emitter<ContractsState> emit) async {
    if (state.status != ContractsStatus.success) return;
    try {
      await _fetch(emit);
    } catch (error, stackTrace) {
      log('Refreshing contracts failed', name: 'contracts', error: error, stackTrace: stackTrace);
      return;
    }
    await _researchIfActive(emit);
  }

  Future<void> _fetch(Emitter<ContractsState> emit) async {
    final generation = ++_fetchesStarted;
    final contracts = await _repository.fetchContracts();
    if (generation < _fetchApplied) return;
    _fetchApplied = generation;
    emit(state.copyWith(status: ContractsStatus.success, contracts: contracts));
  }

  void _onFiltersChanged(ContractsFiltersChanged event, Emitter<ContractsState> emit) {
    emit(state.copyWith(filters: event.filters));
  }

  void _onTerminatedToggled(ContractsTerminatedToggled event, Emitter<ContractsState> emit) {
    final open = {...state.openTerminated};
    if (!open.remove(event.fileId)) open.add(event.fileId);
    emit(state.copyWith(openTerminated: open));
  }

  Future<void> _onSearchChanged(ContractsSearchChanged event, Emitter<ContractsState> emit) async {
    if (event.query.trim().length < ContractsState.minSearchLength) {
      emit(state.copyWith(
        searchQuery: event.query,
        searchStatus: ContractsSearchStatus.idle,
        searchIds: () => null,
        searchedTerm: '',
      ));
      return;
    }
    emit(state.copyWith(searchQuery: event.query, searchStatus: ContractsSearchStatus.loading));
    await Future<void>.delayed(_searchDelay);
    // Typed again during the pause: that later event searches instead.
    if (state.searchQuery != event.query) return;
    await _search(emit);
  }

  /// Searches for the current term. A response that arrives after the term
  /// has changed is dropped.
  Future<void> _search(Emitter<ContractsState> emit) async {
    final term = state.searchTerm;
    try {
      final ids = await _repository.searchContractIds(term);
      if (state.searchTerm != term) return;
      emit(state.copyWith(
        searchStatus: ContractsSearchStatus.success,
        searchIds: () => ids,
        searchedTerm: term,
      ));
    } catch (error, stackTrace) {
      log('Searching contracts failed', name: 'contracts', error: error, stackTrace: stackTrace);
      if (state.searchTerm != term) return;
      emit(state.copyWith(
        searchStatus: ContractsSearchStatus.failure,
        searchIds: () => null,
        searchedTerm: '',
      ));
    }
  }

  /// After a reload a brand, tenant or unit may have changed, so an active
  /// search runs again.
  Future<void> _researchIfActive(Emitter<ContractsState> emit) async {
    if (state.searchStatus == ContractsSearchStatus.idle) return;
    await _search(emit);
  }
}
