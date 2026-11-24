/// Why a lookup or a ticket action failed, or why an action is blocked
/// (`lookup_ticket`'s `blocked_by`: the same keys the actions raise).
enum TicketFailureKind {
  ticketNotFound('ticket_not_found'),
  noOpenShift('no_open_shift'),
  ticketVoided('ticket_voided'),
  ticketUsed('ticket_used'),
  ticketExpired('ticket_expired'),
  notScanned('not_scanned'),
  alreadyReactivated('already_reactivated'),
  reactivationLimitReached('reactivation_limit_reached'),
  reactivationWindowPassed('reactivation_window_passed'),
  ticketNotPaid('ticket_not_paid'),
  ticketAlreadyScanned('ticket_already_scanned'),
  notSameShift('not_same_shift'),
  invalidReason('invalid_reason'),
  reasonTextRequired('reason_text_required'),
  serverUnreachable(null),

  /// The app's own: reactivate and refund can't be done from the offline queue.
  needsServer(null),
  unexpected(null);

  const TicketFailureKind(this.key);

  /// The server's error key; null for the app's own kinds.
  final String? key;

  /// An unknown key is [unexpected].
  static TicketFailureKind fromKey(String key) {
    for (final kind in values) {
      if (kind.key == key) return kind;
    }
    return unexpected;
  }
}

class TicketFailure implements Exception {
  const TicketFailure(this.kind);

  final TicketFailureKind kind;

  @override
  String toString() => 'TicketFailure(${kind.name})';
}
