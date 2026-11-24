import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../bloc/ticket_action_cubit.dart';
import '../data/ticket_failure.dart';
import '../data/ticket_lookup.dart';
import '../data/ticket_repository.dart';
import 'ticket_action_dialog.dart';
import 'ticket_messages.dart';

/// The action dialog for the ticket with [code], from outside the lookup
/// screen (the order review's per-ticket buttons): the ticket is looked up
/// first, so the dialog shows what the server allows now. A failed lookup
/// shows its message and returns null.
Future<TicketActionOutcome?> openTicketActions(
  BuildContext context, {
  required String code,
  required TicketPrintSetup setup,
  required TicketAction initial,
}) async {
  final repository = context.read<TicketRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final navigator = Navigator.of(context);

  // A modal spinner while the ticket loads, so nothing else is pressed.
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  ));
  TicketLookup ticket;
  TicketActionSettings settings;
  try {
    ticket = await repository.lookup(code);
    settings = await repository.actionSettings();
  } on TicketFailure catch (e) {
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(ticketFailureMessage(l10n, e.kind))));
    return null;
  }
  navigator.pop();
  if (!context.mounted) return null;
  return TicketActionDialog.show(
    context,
    ticket: ticket,
    settings: settings,
    setup: setup,
    initial: initial,
  );
}
