import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/ticket_failure.dart';
import '../data/ticket_lookup.dart';
import '../data/ticket_repository.dart';
import 'ticket_action_cubit.dart';

class TicketLookupState extends Equatable {
  const TicketLookupState({
    this.code = '',
    this.loading = false,
    this.ticket,
    this.failure,
    this.settings,
    this.outcome,
  });

  /// The code last searched.
  final String code;
  final bool loading;
  final TicketLookup? ticket;
  final TicketFailureKind? failure;

  /// For the action dialog's limit texts; loaded with the first search.
  final TicketActionSettings? settings;

  /// The action just done on [ticket], for the screen's notice.
  final TicketActionOutcome? outcome;

  @override
  List<Object?> get props => [code, loading, ticket, failure, settings, outcome];
}

/// Ticket lookup (`TicketLookup.dc.html`): a code scanned or typed, then the
/// ticket with its scans and the actions the cashier can still do
/// (`lookup_ticket`, ADR-0014).
class TicketLookupCubit extends Cubit<TicketLookupState> {
  TicketLookupCubit(this._repository) : super(const TicketLookupState());

  final TicketRepository _repository;

  /// Readers often end a code with CR/LF; the server trims it too.
  Future<void> search(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty || state.loading) return;
    await _load(trimmed);
  }

  /// After an action: the ticket again, with [outcome] shown.
  Future<void> actionDone(TicketActionOutcome outcome) async {
    if (state.code.isEmpty) return;
    await _load(state.code, outcome: outcome);
  }

  Future<void> _load(String code, {TicketActionOutcome? outcome}) async {
    emit(TicketLookupState(code: code, loading: true, settings: state.settings, outcome: outcome));
    try {
      final settings = state.settings ?? await _repository.actionSettings();
      final ticket = await _repository.lookup(code);
      if (isClosed) return;
      emit(TicketLookupState(code: code, ticket: ticket, settings: settings, outcome: outcome));
    } on TicketFailure catch (e) {
      if (isClosed) return;
      emit(TicketLookupState(code: code, failure: e.kind, settings: state.settings, outcome: outcome));
    }
  }
}
