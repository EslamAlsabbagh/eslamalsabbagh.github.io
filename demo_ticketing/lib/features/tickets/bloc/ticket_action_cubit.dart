import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/printer/print_service.dart';
import '../../../core/printer/printer_client.dart';
import '../../../core/printer/printer_target.dart';
import '../data/ticket_failure.dart';
import '../data/ticket_lookup.dart';
import '../data/ticket_repository.dart';

/// What a reprint needs that the server doesn't return: the venue's name and
/// this counter's printer (null: none set, so the print fails).
class TicketPrintSetup extends Equatable {
  const TicketPrintSetup({required this.venueName, required this.printer});

  final String venueName;
  final PrinterTarget? printer;

  @override
  List<Object?> get props => [venueName, printer];
}

/// The copy of a logged reprint, on paper or not.
enum ReprintPrint { none, printing, printed, failed }

/// An action that went through, for the screen that opened the dialog.
class TicketActionOutcome extends Equatable {
  const TicketActionOutcome(this.action, {this.refund, this.printed = false});

  final TicketAction action;

  /// [TicketAction.voidRefund]: what to hand back, and how.
  final RefundResult? refund;

  /// [TicketAction.reprint]: the copy came out.
  final bool printed;

  @override
  List<Object?> get props => [action, refund, printed];
}

class TicketActionState extends Equatable {
  const TicketActionState({
    required this.action,
    required this.reason,
    this.text = '',
    this.textMissing = false,
    this.submitting = false,
    this.failure,
    this.reprinted,
    this.print = ReprintPrint.none,
    this.outcome,
  });

  final TicketAction action;
  final ActionReason reason;

  /// The note; required for [ActionReason.other].
  final String text;
  final bool textMissing;
  final bool submitting;
  final TicketFailureKind? failure;

  /// Set once `reprint_ticket` went through: the action is logged, whatever
  /// happens to the paper.
  final ReprintedTicket? reprinted;
  final ReprintPrint print;

  /// Set when the dialog is done.
  final TicketActionOutcome? outcome;

  /// The action is logged: no going back to pick another.
  bool get logged => reprinted != null || outcome != null;

  TicketActionState copyWith({
    TicketAction? action,
    ActionReason? reason,
    String? text,
    bool? textMissing,
    bool? submitting,
    Object? failure = _keep,
    ReprintedTicket? reprinted,
    ReprintPrint? print,
    TicketActionOutcome? outcome,
  }) =>
      TicketActionState(
        action: action ?? this.action,
        reason: reason ?? this.reason,
        text: text ?? this.text,
        textMissing: textMissing ?? this.textMissing,
        submitting: submitting ?? this.submitting,
        failure: failure == _keep ? this.failure : failure as TicketFailureKind?,
        reprinted: reprinted ?? this.reprinted,
        print: print ?? this.print,
        outcome: outcome ?? this.outcome,
      );

  static const _keep = Object();

  @override
  List<Object?> get props =>
      [action, reason, text, textMissing, submitting, failure, reprinted, print, outcome];
}

/// The ticket action dialog (`Approval.dc.html`): one action, a reason
/// (required; "other" needs text), no approval (ADR-0009). The limits are
/// checked by the server; the dialog only offers what `lookup_ticket` said
/// is allowed.
///
/// A reprint prints its copy at once. If that print fails, Retry prints the
/// same copy again without another call: it was never on paper (as
/// ADR-0023's retry).
///
/// With [_queuedReprint], the reprint goes in the counter's offline queue
/// instead of to the server (ADR-0026): logged first, then printed, the same.
class TicketActionCubit extends Cubit<TicketActionState> {
  TicketActionCubit({
    required this._repository,
    required this._printer,
    required this.ticket,
    required this.setup,
    required TicketAction initial,
    this._queuedReprint,
  }) : super(TicketActionState(action: initial, reason: ActionReason.forAction(initial).first));

  final TicketRepository _repository;
  final PrintService _printer;
  final TicketLookup ticket;
  final TicketPrintSetup setup;
  final ReprintedTicket Function(ActionReason reason, String? text)? _queuedReprint;

  void pickAction(TicketAction action) {
    if (state.submitting || state.logged || action == state.action || !ticket.can(action)) return;
    emit(TicketActionState(action: action, reason: ActionReason.forAction(action).first));
  }

  void pickReason(ActionReason reason) {
    if (state.submitting || state.logged || !ActionReason.forAction(state.action).contains(reason)) {
      return;
    }
    emit(state.copyWith(reason: reason, textMissing: false));
  }

  void setText(String text) {
    if (state.logged) return;
    emit(state.copyWith(text: text, textMissing: false));
  }

  Future<void> submit() async {
    if (state.submitting || state.logged) return;
    final text = state.text.trim();
    if (state.reason == ActionReason.other && text.isEmpty) {
      return emit(state.copyWith(textMissing: true));
    }
    final note = text.isEmpty ? null : text;
    emit(state.copyWith(submitting: true, failure: null));
    try {
      switch (state.action) {
        case TicketAction.reprint:
          final reprinted = _queuedReprint?.call(state.reason, note) ??
              await _repository.reprint(ticket.ticketId, state.reason, reasonText: note);
          if (isClosed) return;
          emit(state.copyWith(submitting: false, reprinted: reprinted));
          await _printCopy();
        case TicketAction.reactivate:
          await _repository.reactivate(ticket.ticketId, state.reason, reasonText: note);
          if (isClosed) return;
          emit(state.copyWith(
            submitting: false,
            outcome: const TicketActionOutcome(TicketAction.reactivate),
          ));
        case TicketAction.voidRefund:
          final refund = await _repository.voidRefund(ticket.ticketId, state.reason, reasonText: note);
          if (isClosed) return;
          emit(state.copyWith(
            submitting: false,
            outcome: TicketActionOutcome(TicketAction.voidRefund, refund: refund),
          ));
      }
    } on TicketFailure catch (e) {
      if (!isClosed) emit(state.copyWith(submitting: false, failure: e.kind));
    }
  }

  /// The logged copy's print failed: the same copy again, no call.
  Future<void> retryPrint() async {
    if (state.print != ReprintPrint.failed) return;
    await _printCopy();
  }

  /// Closes after a failed copy: the reprint stays logged.
  void giveUpPrint() {
    if (state.print != ReprintPrint.failed) return;
    emit(state.copyWith(outcome: const TicketActionOutcome(TicketAction.reprint)));
  }

  Future<void> _printCopy() async {
    final reprinted = state.reprinted;
    if (reprinted == null) return;
    emit(state.copyWith(print: ReprintPrint.printing));
    var printed = false;
    final target = setup.printer;
    if (target != null) {
      try {
        await _printer.printTicket(
          target,
          reprinted.printed(
            venueName: setup.venueName,
            languageCode: PrintService.ticketLocale.languageCode,
          ),
        );
        printed = true;
      } on PrinterException {
        printed = false;
      }
    }
    if (isClosed) return;
    emit(printed
        ? state.copyWith(
            print: ReprintPrint.printed,
            outcome: const TicketActionOutcome(TicketAction.reprint, printed: true),
          )
        : state.copyWith(print: ReprintPrint.failed));
  }
}
