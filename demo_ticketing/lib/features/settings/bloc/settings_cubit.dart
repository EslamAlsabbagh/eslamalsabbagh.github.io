import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/settings_models.dart';
import '../data/settings_repository.dart';

class SettingsState extends Equatable {
  const SettingsState({this.overview, this.loadFailure, this.loading = false, this.saving = false});

  /// Null until the first good read; kept when a later one fails.
  final SettingsOverview? overview;
  final SettingsFailureKind? loadFailure;
  final bool loading;
  final bool saving;

  SettingsState copyWith({
    SettingsOverview? Function()? overview,
    SettingsFailureKind? Function()? loadFailure,
    bool? loading,
    bool? saving,
  }) => SettingsState(
    overview: overview != null ? overview() : this.overview,
    loadFailure: loadFailure != null ? loadFailure() : this.loadFailure,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
  );

  @override
  List<Object?> get props => [overview, loadFailure, loading, saving];
}

/// The Settings page (4.8): the settings, the counters, saving both. Reads on
/// entry, after a counter is saved, and on Refresh; a settings save answers
/// with the page itself.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  int _request = 0;

  Future<void> start() => refresh();

  Future<void> refresh() async {
    final request = ++_request;
    emit(state.copyWith(loading: true));
    try {
      final overview = await _repository.overview();
      if (isClosed || request != _request) return;
      emit(state.copyWith(overview: () => overview, loadFailure: () => null, loading: false));
    } on SettingsFailure catch (e) {
      if (isClosed || request != _request) return;
      emit(state.copyWith(loadFailure: () => e.kind, loading: false));
    }
  }

  /// Saves what differs between the page's settings and [edited]; nothing to
  /// send is no call. Null when saved, else why not.
  Future<SettingsFailure?> save(AdminSettings edited) async {
    final overview = state.overview;
    if (state.saving || overview == null) return null;
    final changes = settingsChanges(overview.settings, edited);
    if (changes.isEmpty) return null;
    emit(state.copyWith(saving: true));
    // A read started before the save would bring back the old values.
    final request = ++_request;
    try {
      final saved = await _repository.saveSettings(changes);
      if (isClosed) return null;
      emit(
        state.copyWith(
          overview: () => saved,
          loadFailure: () => null,
          saving: false,
          loading: request == _request ? false : state.loading,
        ),
      );
      return null;
    } on SettingsFailure catch (e) {
      if (isClosed) return null;
      emit(state.copyWith(saving: false, loading: false));
      return e;
    }
  }

  /// Adds a counter ([id] null) or changes one. Null when saved, else why not.
  Future<SettingsFailure?> saveCounter(String? id, CounterDraft draft) async {
    try {
      await _repository.saveCounter(id: id, draft: draft);
      if (!isClosed) await refresh();
      return null;
    } on SettingsFailure catch (e) {
      if (!isClosed && e.kind == SettingsFailureKind.notFound) await refresh();
      return e;
    }
  }
}
