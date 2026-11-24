import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tasks/data/live_changes.dart';
import '../data/contract_activity_entry.dart';
import '../data/contract_details.dart';
import '../data/contract_item.dart';
import '../data/contract_record.dart';
import '../data/contract_refs.dart';
import '../data/contract_save_failure.dart';
import '../data/contracts_repository.dart';

enum ContractDetailsLoad { loading, success, failure }

class ContractDetailsState extends Equatable {
  const ContractDetailsState({
    required this.contractId,
    this.load = ContractDetailsLoad.loading,
    this.details,
    this.record,
    this.activity = const [],
    this.children = const [],
    this.items = const [],
    this.busy = false,
    this.failure,
    this.itemFailure,
    this.revision = 0,
    this.deleted = false,
  });

  final String contractId;
  final ContractDetailsLoad load;

  /// The effective values (`contract_list`).
  final ContractDetails? details;

  /// The contract's own row, for «تعديل» and «حذف المسودة».
  final ContractRecord? record;

  /// Newest first.
  final List<ContractActivityEntry> activity;

  /// The annexes and storage contracts directly under it, in no order: the
  /// sections sort their own.
  final List<ContractRecord> children;

  /// «النواقص والمستندات»: the missing items on the contract and the rows
  /// under it, and the effective tenant's documents, oldest first.
  final List<ContractItem> items;

  /// An action is in flight; the buttons are inert.
  final bool busy;
  final ContractSaveFailure? failure;

  /// Why the last checklist write failed, shown in the checklist section.
  final ContractSaveFailure? itemFailure;

  /// Goes up after each action that changed the contract, so the list reloads.
  final int revision;

  /// «حذف المسودة» went through; the drawer closes.
  final bool deleted;

  ContractDetailsState copyWith({
    ContractDetailsLoad? load,
    ContractDetails? details,
    ContractRecord? record,
    List<ContractActivityEntry>? activity,
    List<ContractRecord>? children,
    List<ContractItem>? items,
    bool? busy,
    ContractSaveFailure? Function()? failure,
    ContractSaveFailure? Function()? itemFailure,
    int? revision,
    bool? deleted,
  }) =>
      ContractDetailsState(
        contractId: contractId,
        load: load ?? this.load,
        details: details ?? this.details,
        record: record ?? this.record,
        activity: activity ?? this.activity,
        children: children ?? this.children,
        items: items ?? this.items,
        busy: busy ?? this.busy,
        failure: failure == null ? this.failure : failure(),
        itemFailure: itemFailure == null ? this.itemFailure : itemFailure(),
        revision: revision ?? this.revision,
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props =>
      [contractId, load, details, record, activity, children, items, busy, failure, itemFailure, revision, deleted];
}

sealed class ContractDetailsEvent extends Equatable {
  const ContractDetailsEvent();

  @override
  List<Object?> get props => [];
}

final class ContractDetailsLoadRequested extends ContractDetailsEvent {
  const ContractDetailsLoadRequested();
}

/// A quiet read: live changes, midnight, and after the form saved.
final class ContractDetailsRefreshRequested extends ContractDetailsEvent {
  const ContractDetailsRefreshRequested();
}

/// «إنهاء العقد», after its dialog.
final class ContractDetailsTerminated extends ContractDetailsEvent {
  const ContractDetailsTerminated({required this.on, required this.reason});

  final DateTime on;
  final String reason;

  @override
  List<Object?> get props => [on, reason];
}

/// «إعادة تفعيل» (managers and admins).
final class ContractDetailsReopened extends ContractDetailsEvent {
  const ContractDetailsReopened();
}

/// «حذف المسودة», after its confirmation.
final class ContractDetailsDeleteConfirmed extends ContractDetailsEvent {
  const ContractDetailsDeleteConfirmed();
}

/// A checklist item's box was ticked or unticked.
final class ContractItemToggled extends ContractDetailsEvent {
  const ContractItemToggled(this.itemId, {required this.resolved});

  final String itemId;
  final bool resolved;

  @override
  List<Object?> get props => [itemId, resolved];
}

/// «إضافة» in a checklist group's inline row.
final class ContractItemAdded extends ContractDetailsEvent {
  const ContractItemAdded(this.input);

  final ContractItemInput input;

  @override
  List<Object?> get props => [input];
}

/// An item's ×, after «حذف البند؟».
final class ContractItemDeleted extends ContractDetailsEvent {
  const ContractItemDeleted(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

/// The contract drawer (DESIGN_SPEC §4 "Contract drawer"): a main
/// contract's effective values, its own row and its history, read together,
/// and the bottom actions.
///
/// Every action reads the contract back from the database: nothing is shown
/// before the server has it. A live change to any contract table (the
/// history isn't published, so it is read with them), to `tasks` (the
/// follow-up count) or a rejoin reads it again quietly; a read that a newer
/// read or an action overtook is dropped.
///
/// The checklist's tick is the one write shown before the server has it: the
/// box flips at once, and a refused write flips it back.
class ContractDetailsBloc extends Bloc<ContractDetailsEvent, ContractDetailsState> {
  ContractDetailsBloc({
    required String contractId,
    required this._repository,
    Stream<LiveChange> liveChanges = const Stream.empty(),
    this._liveDelay = const Duration(milliseconds: 500),
  }) : super(ContractDetailsState(contractId: contractId)) {
    on<ContractDetailsLoadRequested>(_onLoadRequested);
    on<ContractDetailsRefreshRequested>(_onRefreshRequested);
    on<ContractDetailsTerminated>(
      (event, emit) => _act(emit, () => _repository.terminate(state.contractId, on: event.on, reason: event.reason)),
    );
    on<ContractDetailsReopened>((event, emit) => _act(emit, () => _repository.reopen(state.contractId)));
    on<ContractDetailsDeleteConfirmed>(_onDeleteConfirmed);
    on<ContractItemToggled>(_onItemToggled);
    on<ContractItemAdded>((event, emit) => _act(emit, () => _repository.addItem(event.input), item: true));
    on<ContractItemDeleted>((event, emit) => _act(emit, () => _repository.deleteItem(event.itemId), item: true));
    _liveSubscription = liveChanges.where(_concernsContracts).listen(_onLiveChange);
  }

  final ContractsRepository _repository;
  final Duration _liveDelay;
  late final StreamSubscription<LiveChange> _liveSubscription;
  Timer? _liveTimer;

  /// Goes up when an action starts, so a quiet read already on its way is
  /// dropped: the action's own read-back is newer.
  int _writes = 0;

  /// Goes up with every quiet read, so only the latest one lands.
  int _refreshes = 0;

  /// Ticks whose write hasn't come back. Only the last one reads back, so an
  /// earlier read can't undo a later tick on screen.
  int _pendingTicks = 0;

  static bool _concernsContracts(LiveChange change) =>
      change.resync || change.table == LiveTable.tasks || LiveTable.contractTables.contains(change.table);

  void _onLiveChange(LiveChange _) {
    _liveTimer?.cancel();
    _liveTimer = Timer(_liveDelay, () {
      if (!isClosed) add(const ContractDetailsRefreshRequested());
    });
  }

  /// The checklist label field's suggestions (`suggest_values('item_label')`).
  Future<List<ValueSuggestion>> suggestItemLabels(String query) =>
      _repository.suggestValues(SuggestValueField.itemLabel, query);

  @override
  Future<void> close() async {
    _liveTimer?.cancel();
    await _liveSubscription.cancel();
    return super.close();
  }

  /// Everything the drawer shows, read together, as what it sets on a state.
  Future<ContractDetailsState Function(ContractDetailsState)> _readAll() async {
    final id = state.contractId;
    final (details, record, activity, children) = await (
      _repository.fetchDetails(id),
      _repository.fetchRecord(id),
      _repository.fetchActivity(id),
      _repository.fetchChildren(id),
    ).wait;
    // The documents follow the effective tenant (after a تنازل), so the
    // items wait for the details.
    final items = await _repository.fetchItems(
      contractIds: [id, for (final child in children) child.id],
      partyId: details.partyId,
    );
    return (ContractDetailsState state) =>
        state.copyWith(details: details, record: record, activity: activity, children: children, items: items);
  }

  Future<void> _onLoadRequested(ContractDetailsLoadRequested event, Emitter<ContractDetailsState> emit) async {
    emit(state.copyWith(load: ContractDetailsLoad.loading, failure: () => null));
    final refresh = ++_refreshes;
    try {
      final read = await _readAll();
      if (refresh != _refreshes) return;
      emit(read(state.copyWith(load: ContractDetailsLoad.success)));
    } catch (error, stackTrace) {
      log('Loading contract ${state.contractId} failed', name: 'contracts', error: error, stackTrace: stackTrace);
      if (refresh == _refreshes) emit(state.copyWith(load: ContractDetailsLoad.failure));
    }
  }

  Future<void> _onRefreshRequested(ContractDetailsRefreshRequested event, Emitter<ContractDetailsState> emit) async {
    if (state.load != ContractDetailsLoad.success || state.busy || state.deleted || _pendingTicks > 0) return;
    final writes = _writes;
    final refresh = ++_refreshes;
    try {
      final read = await _readAll();
      if (writes != _writes || refresh != _refreshes) return;
      emit(read(state));
    } catch (error, stackTrace) {
      // Keeps the last copy; a deleted contract (by someone else) lands here.
      log('Refreshing contract ${state.contractId} failed', name: 'contracts', error: error, stackTrace: stackTrace);
    }
  }

  /// [item]: a checklist write, whose failure shows in the checklist.
  Future<void> _act(Emitter<ContractDetailsState> emit, Future<void> Function() action, {bool item = false}) async {
    if (state.load != ContractDetailsLoad.success || state.busy || _pendingTicks > 0) return;
    _writes++;
    emit(state.copyWith(busy: true, failure: () => null, itemFailure: () => null));
    try {
      await action();
    } on ContractSaveException catch (error) {
      emit(item
          ? state.copyWith(busy: false, itemFailure: () => error.failure)
          : state.copyWith(busy: false, failure: () => error.failure));
      return;
    }
    await _readBack(emit, busy: false);
  }

  /// Reads everything after a write and raises [ContractDetailsState.revision]
  /// so the list reloads.
  Future<void> _readBack(Emitter<ContractDetailsState> emit, {bool? busy}) async {
    try {
      final read = await _readAll();
      emit(read(state.copyWith(busy: busy, revision: state.revision + 1)));
    } catch (error, stackTrace) {
      log('Reading contract ${state.contractId} back failed', name: 'contracts', error: error, stackTrace: stackTrace);
      emit(state.copyWith(busy: busy, load: ContractDetailsLoad.failure, revision: state.revision + 1));
    }
  }

  /// The tick shows at once; a refused write puts the box back. Several
  /// ticks may be in flight; the last to come back reads the contract again.
  Future<void> _onItemToggled(ContractItemToggled event, Emitter<ContractDetailsState> emit) async {
    if (state.load != ContractDetailsLoad.success || state.busy) return;
    if (!state.items.any((i) => i.id == event.itemId)) return;
    List<ContractItem> flipped(bool resolved) => [
          for (final i in state.items) i.id == event.itemId ? i.resolved(resolved) : i,
        ];
    _writes++;
    _pendingTicks++;
    emit(state.copyWith(items: flipped(event.resolved), itemFailure: () => null));
    try {
      await _repository.setItemResolved(event.itemId, resolved: event.resolved);
    } on ContractSaveException catch (error) {
      emit(state.copyWith(items: flipped(!event.resolved), itemFailure: () => error.failure));
    } finally {
      _pendingTicks--;
    }
    if (_pendingTicks == 0 && !isClosed) await _readBack(emit);
  }

  Future<void> _onDeleteConfirmed(ContractDetailsDeleteConfirmed event, Emitter<ContractDetailsState> emit) async {
    if (state.load != ContractDetailsLoad.success || state.busy) return;
    _writes++;
    emit(state.copyWith(busy: true, failure: () => null));
    try {
      await _repository.delete(state.contractId);
      emit(state.copyWith(busy: false, deleted: true, revision: state.revision + 1));
    } on ContractSaveException catch (error) {
      emit(state.copyWith(busy: false, failure: () => error.failure));
      // What hangs on it changed since the drawer read it: read it again so
      // «حذف العقد» goes away.
      if (error.failure == ContractSaveFailure.notEmpty) add(const ContractDetailsRefreshRequested());
    }
  }
}
