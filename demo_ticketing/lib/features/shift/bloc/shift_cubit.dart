import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../offline/data/offline_store.dart';
import '../data/open_shift.dart';
import '../data/shift_repository.dart';

sealed class ShiftState extends Equatable {
  const ShiftState();

  @override
  List<Object?> get props => [];
}

/// Signed out, or still loading.
final class ShiftUnknown extends ShiftState {
  const ShiftUnknown();
}

final class ShiftNone extends ShiftState {
  const ShiftNone();
}

final class ShiftOpen extends ShiftState {
  const ShiftOpen(this.shift, {required this.atThisCounter, this.fromCopy = false});

  final OpenShift shift;

  /// False when the shift was opened on another counter's PC: selling here
  /// would go to that counter's shift.
  final bool atThisCounter;

  /// The app started with the server out of reach, so this is the copy kept
  /// on this PC (ADR-0026). The first answer from the server replaces it.
  final bool fromCopy;

  @override
  List<Object?> get props => [shift, atThisCounter, fromCopy];
}

final class ShiftLoadFailed extends ShiftState {
  const ShiftLoadFailed(this.kind);

  final ShiftFailureKind kind;

  @override
  List<Object?> get props => [kind];
}

/// The signed-in staff member's open shift, for the whole app. The router
/// sends someone with an open shift at this counter on to selling.
///
/// A counter PC restarted while the server is down opens the shift from a copy
/// kept on this PC, tied to the saved session's user (ADR-0026). It can't open
/// one: the copy only ever holds what the server last said.
class ShiftCubit extends Cubit<ShiftState> {
  ShiftCubit(
    this._repository, {
    required this._counterId,
    required this._store,
    this._serverWait = const Duration(seconds: 5),
  }) : super(const ShiftUnknown());

  final ShiftRepository _repository;
  final String? _counterId;
  final OfflineStore _store;

  /// How long a start waits for the server when it has a copy to fall back on.
  final Duration _serverWait;

  static const _copyKey = 'open_shift';

  /// Bumped by every change, so a load still running from before is dropped.
  int _generation = 0;

  /// Reads the open shift again. An open shift stays shown while it's read,
  /// and stays open when the server can't be reached: selling goes on
  /// offline inside it (ADR-0015).
  ///
  /// With [preferCopy] (sign-in just found the server out of reach) the copy is
  /// used at once rather than after a second wait.
  Future<void> load({bool preferCopy = false}) async {
    final generation = ++_generation;
    final open = state is ShiftOpen ? state as ShiftOpen : null;
    if (open == null) emit(const ShiftUnknown());
    final copy = open == null ? _readCopy() : null;
    if (preferCopy && copy != null) return emit(_open(copy, fromCopy: true));
    try {
      final read = _repository.myOpenShift();
      final shift = await (copy == null ? read : read.timeout(_serverWait));
      if (generation != _generation || isClosed) return;
      _saveCopy(shift);
      emit(shift == null ? const ShiftNone() : _open(shift));
    } on TimeoutException {
      if (generation != _generation || isClosed) return;
      emit(_open(copy!, fromCopy: true));
    } on ShiftFailure catch (e) {
      if (generation != _generation || isClosed) return;
      if (e.kind == ShiftFailureKind.serverUnreachable) {
        if (open != null) return emit(open);
        if (copy != null) return emit(_open(copy, fromCopy: true));
      }
      emit(ShiftLoadFailed(e.kind));
    }
  }

  /// The server answered: reads the shift again if this one came from the copy
  /// (it may have been closed meanwhile), or if it couldn't be read at all.
  Future<void> confirm() async {
    final current = state;
    final unread = switch (current) {
      ShiftOpen(:final fromCopy) => fromCopy,
      ShiftLoadFailed(:final kind) => kind == ShiftFailureKind.serverUnreachable,
      _ => false,
    };
    if (unread) await load();
  }

  /// A shift the open-shift screen just opened.
  void opened(OpenShift shift) {
    _generation++;
    _saveCopy(shift);
    emit(_open(shift));
  }

  /// `close_shift` went through: a restart must not sell into it.
  void forgetCopy() => _store.deleteCache(_copyKey);

  /// Signed out.
  void clear() {
    _generation++;
    forgetCopy();
    emit(const ShiftUnknown());
  }

  ShiftOpen _open(OpenShift shift, {bool fromCopy = false}) =>
      ShiftOpen(shift, atThisCounter: shift.counterId == _counterId, fromCopy: fromCopy);

  OpenShift? _readCopy() {
    final userId = _repository.currentUserId;
    final json = _store.readCache(_copyKey);
    if (userId == null || json is! Map<String, dynamic> || json['user_id'] != userId) return null;
    try {
      return OpenShift.fromOpenShiftResult(json);
    } on Object {
      // From an older app version: as if none.
      return null;
    }
  }

  void _saveCopy(OpenShift? shift) {
    final userId = _repository.currentUserId;
    if (shift == null || userId == null) return forgetCopy();
    _store.writeCache(_copyKey, {...shift.toJson(), 'user_id': userId}, now: DateTime.now());
  }
}
