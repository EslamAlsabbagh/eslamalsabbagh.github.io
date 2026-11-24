
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/export/csv_export.dart';
import '../../../core/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../bloc/actions_log_cubit.dart';
import '../data/action_log_models.dart';
import '../data/actions_log_repository.dart';
import 'actions_log_messages.dart';

/// The actions log (task 4.3, `ActionsLog.dc.html`): what cashiers did without
/// approval (ADR-0009), its review flags, and "reviewed". Nobody reviews their
/// own action (ADR-0018), which the server enforces too. No gate code reaches
/// this page: a ticket shows its last 3 digits only.
class ActionsLogPage extends StatelessWidget {
  const ActionsLogPage({super.key, this.shiftId});

  /// Opens the log of one shift (the Shifts page's link).
  final String? shiftId;

  /// Where the CSV goes; tests point it at a temporary folder.
  @visibleForTesting
  static Directory? Function() exportFolder = downloadsFolder;

  @override
  Widget build(BuildContext context) {
    final badge = context.read<PendingReviewsCubit>();
    return BlocProvider(
      key: ValueKey('actions-log-${shiftId ?? ''}'),
      create: (context) => ActionsLogCubit(
        context.read<ActionsLogRepository>(),
        shiftId: shiftId,
        onPendingCount: badge.set,
      )..start(),
      child: const _ActionsLogView(),
    );
  }
}

class _ActionsLogView extends StatefulWidget {
  const _ActionsLogView();

  @override
  State<_ActionsLogView> createState() => _ActionsLogViewState();
}

class _ActionsLogViewState extends State<_ActionsLogView> {
  bool _exporting = false;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final cubit = context.read<ActionsLogCubit>();
    final log = cubit.state.log;
    if (log == null) return;
    void say(String text, {SnackBarAction? action}) =>
        messenger?.showSnackBar(SnackBar(content: Text(text), action: action));

    final folder = ActionsLogPage.exportFolder();
    if (folder == null) {
      say(l10n.actionsExportNoFolder);
      return;
    }
    setState(() => _exporting = true);
    try {
      final rows = await cubit.allRows();
      final csv = encodeCsv(actionsCsvRows(l10n, rows, log.rules, languageCode));
      final name = switch (log.shift) {
        final shift? => 'actions-log-shift-${shift.number}.csv',
        null => 'actions-log-${DateFormat('yyyy-MM-dd').format(log.day)}-${log.period}.csv',
      };
      final file = await saveCsv(folder, name, csv);
      say(
        l10n.actionsExported(file.path),
        action: SnackBarAction(label: l10n.actionsOpenFolder, onPressed: () => showInFolder(file)),
      );
    } on ActionsLogFailure catch (e) {
      say(actionsFailureMessage(l10n, e.kind));
    } on FileSystemException {
      say(l10n.actionsExportFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<ActionsLogCubit>().state;
    final cubit = context.read<ActionsLogCubit>();
    final log = state.log;

    final Widget body;
    if (log == null) {
      final failure = state.failure;
      body = failure == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Text(
                    actionsFailureMessage(l10n, failure),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (failure != ActionsLogFailureKind.notAllowed)
                    FilledButton(onPressed: cubit.refresh, child: Text(l10n.retry)),
                ],
              ),
            );
    } else {
      final rows = state.rows;
      body = SingleChildScrollView(
        key: const ValueKey('actions-scroll'),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Tiles(log: log),
            const SizedBox(height: 18),
            _FilterBar(state: state, log: log),
            if (log.truncated) ...[
              const SizedBox(height: 12),
              _Banner(
                key: const ValueKey('actions-truncated'),
                text: l10n.actionsTruncated(log.rows.length, log.total),
                bg: tokens.primaryTint,
                fg: tokens.onPrimaryTint,
              ),
            ],
            const SizedBox(height: 18),
            _Table(
              rows: rows,
              log: log,
              reviewing: state.reviewing,
              emptyText: state.period == ActionsPeriod.review
                  ? l10n.actionsEmptyReview
                  : l10n.actionsEmpty,
            ),
            const SizedBox(height: 18),
            _Rules(rules: log.rules),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.navActionsLog,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l10n.actionsSubtitle,
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.actionsRefresh,
                    onPressed: cubit.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: AppSizes.touchTarget,
                    child: OutlinedButton.icon(
                      key: const ValueKey('actions-export'),
                      onPressed: log == null || _exporting ? null : _export,
                      icon: _exporting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download, size: 18),
                      label: Text(
                        l10n.actionsExport,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (log != null && state.failure != null) ...[
            const SizedBox(height: 16),
            _Banner(
              text: actionsFailureMessage(l10n, state.failure!),
              bg: tokens.warningBg,
              fg: tokens.warningText,
              border: tokens.warningBorder,
            ),
          ],
          const SizedBox(height: 18),
          // Scrolls by wheel or drag, with no scrollbar (as the Shifts page).
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.log});

  final ActionsLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    Widget tile(String label, String value, {bool warn = false, Key? key}) => Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: warn ? tokens.warningBg : tokens.surface,
        border: Border.all(color: warn ? tokens.warningBorder : tokens.border),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: warn ? tokens.warningText : tokens.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: warn ? tokens.warningText : tokens.text,
            ),
          ),
        ],
      ),
    );
    final tiles = [
      tile(l10n.actionReprint, '${log.counts[LoggedAction.reprint] ?? 0}'),
      tile(l10n.actionReactivate, '${log.counts[LoggedAction.reactivate] ?? 0}'),
      tile(l10n.actionVoidRefund, refundTile(l10n, log.refundCount, log.refundPiastres)),
      tile(
        l10n.actionsTileReview,
        '${log.reviewCount}',
        warn: true,
        key: const ValueKey('actions-tile-review'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth >= 760 ? 4 : 2;
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}

/// A row of choices in a grey well (`ActionsLog.dc.html`'s filter buttons).
class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onPick,
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) label;
  final void Function(T value) onPick;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final v in values)
            Semantics(
              key: ValueKey('choice-$v'),
              selected: v == selected,
              button: true,
              child: Material(
                color: v == selected ? tokens.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onPick(v),
                  // Not a Container with an alignment: inside the bar's Wrap
                  // that would stretch each chip to the whole width.
                  child: SizedBox(
                    height: AppSizes.touchTarget,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          label(v),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: v == selected ? tokens.text : tokens.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state, required this.log});

  final ActionsLogState state;
  final ActionsLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<ActionsLogCubit>();
    final shift = log.shift;

    Widget dropdown({
      required Key key,
      required String allLabel,
      required String? value,
      required List<StaffOption> options,
      required void Function(String? id) onChanged,
    }) => Container(
      height: AppSizes.touchTarget,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.inputBorder),
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          key: key,
          value: options.any((o) => o.id == value) ? value : null,
          items: [
            DropdownMenuItem<String?>(child: Text(allLabel)),
            for (final o in options) DropdownMenuItem<String?>(value: o.id, child: Text(o.name)),
          ],
          onChanged: onChanged,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      // Two lines: what to show (period, cashier, counter), then the type.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.actionsShow,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
              if (shift != null)
                InputChip(
                  key: const ValueKey('actions-shift-chip'),
                  label: Text(
                    l10n.actionsShiftChip(shift.number, shift.cashierName, shift.counterName),
                  ),
                  onDeleted: cubit.clearShift,
                  deleteButtonTooltipMessage: l10n.actionsShiftClear,
                )
              else
                _Choices<ActionsPeriod>(
                  values: const [
                    ActionsPeriod.today,
                    ActionsPeriod.yesterday,
                    ActionsPeriod.week,
                    ActionsPeriod.review,
                  ],
                  selected: state.period,
                  label: (p) => switch (p) {
                    ActionsPeriod.today => l10n.shiftsPeriodToday,
                    ActionsPeriod.yesterday => l10n.shiftsPeriodYesterday,
                    ActionsPeriod.week => l10n.shiftsPeriodWeek,
                    ActionsPeriod.review => l10n.actionsPeriodReview(log.reviewCount),
                    ActionsPeriod.shift => '',
                  },
                  onPick: cubit.setPeriod,
                ),
              dropdown(
                key: const ValueKey('actions-cashier'),
                allLabel: l10n.actionsAllCashiers,
                value: state.actorId,
                options: log.staff,
                onChanged: cubit.setActor,
              ),
              dropdown(
                key: const ValueKey('actions-counter'),
                allLabel: l10n.actionsAllCounters,
                value: state.counterId,
                options: log.counters,
                onChanged: cubit.setCounter,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Choices<ActionsTypeFilter>(
            values: ActionsTypeFilter.values,
            selected: state.type,
            label: (t) => typeFilterName(l10n, t),
            onPick: cubit.setType,
          ),
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.rows,
    required this.log,
    required this.reviewing,
    required this.emptyText,
  });

  final List<ActionLogRow> rows;
  final ActionsLog log;
  final String? reviewing;
  final String emptyText;

  static const _flexes = [2, 4, 3, 4, 6, 3];

  static Widget cells(List<Widget> children) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < children.length; i++)
        Expanded(
          flex: _flexes[i],
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: children[i]),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final header = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: tokens.textSecondary,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: cells([
                Text(l10n.actionsColTime, style: header),
                Text(l10n.actionsColWho, style: header),
                Text(l10n.actionsColAction, style: header),
                Text(l10n.actionsColTicket, style: header),
                Text(l10n.actionsColReason, style: header),
                Text(l10n.actionsColReview, style: header),
              ]),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(emptyText, style: TextStyle(color: tokens.textSecondary)),
              ),
            for (final row in rows) _Row(row: row, log: log, reviewing: reviewing),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.log, required this.reviewing});

  final ActionLogRow row;
  final ActionsLog log;
  final String? reviewing;

  Future<void> _review(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failure = await context.read<ActionsLogCubit>().markReviewed(row.id);
    if (failure != null) {
      messenger?.showSnackBar(SnackBar(content: Text(actionsFailureMessage(l10n, failure))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final languageCode = Localizations.localeOf(context).languageCode;
    final auth = context.watch<AuthCubit>().state;
    final own = auth is AuthSignedIn && row.actorId != null && auth.staff.id == row.actorId;
    final small = TextStyle(fontSize: 12, color: tokens.textSecondary);

    final (chipBg, chipFg) = switch (row.action) {
      LoggedAction.reprint => (tokens.primaryTint, tokens.onPrimaryTint),
      LoggedAction.reactivate => (tokens.successBg, tokens.successText),
      LoggedAction.voidRefund => (tokens.dangerBg, tokens.dangerText),
      LoggedAction.cancelOrder ||
      LoggedAction.leftUnprinted => (tokens.warningBg, tokens.warningText),
      _ => (tokens.inset, tokens.text),
    };

    // Ticket: the code's last 3 digits, then type · copy or amount · order.
    final String? ticketTop;
    final List<String> ticketBottom;
    if (row.codeTail case final tail?) {
      ticketTop = '••• $tail';
      ticketBottom = [
        ?typeName(row, languageCode),
        if (row.copyNumber case final copy?) l10n.actionsCopy(copy),
        if (row.amountPiastres case final amount?) formatMoney(l10n, amount),
        if (row.orderNumber case final number?) l10n.actionDialogOrder(number),
      ];
    } else {
      ticketTop = switch (row.orderNumber) {
        final number? => l10n.actionDialogOrder(number),
        null => row.gateName,
      };
      ticketBottom = const [];
    }

    final who = [?row.counterName, if (row.shiftNumber case final n?) '#$n'].join(' · ');
    final reason = reasonLine(l10n, row, languageCode);
    final extra = [
      ...changeLines(l10n, row, languageCode),
      if (row.undoneGateName case final gate?) l10n.actionsUndoneGate(gate),
      ?offlineTimesLine(l10n, row, log.day),
      if (row.action == LoggedAction.voidRefund) ?paymentMethodName(l10n, row.paymentMethod),
    ];

    final Widget review;
    if (row.needsReview && own) {
      review = Text(
        l10n.actionsOwnAction,
        key: ValueKey('review-own-${row.id}'),
        style: TextStyle(fontSize: 13, color: tokens.textSecondary),
      );
    } else if (row.needsReview) {
      review = Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton(
          key: ValueKey('review-${row.id}'),
          onPressed: reviewing == null ? () => _review(context) : null,
          child: reviewing == row.id
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  l10n.actionsReviewButton,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
        ),
      );
    } else if (row.reviewed) {
      review = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.actionsReviewedBy(row.reviewedByName ?? '—'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.successText),
          ),
          Text(logTime(row.reviewedAt!, log.day), style: small),
        ],
      );
    } else {
      review = Text('—', style: TextStyle(fontSize: 13, color: tokens.textSecondary));
    }

    return DecoratedBox(
      key: ValueKey('action-row-${row.id}'),
      decoration: BoxDecoration(
        color: row.needsReview ? tokens.reviewRowBg : null,
        border: Border(top: BorderSide(color: tokens.rowDivider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: _Table.cells([
          Text(logTime(row.createdAt, log.day), style: const TextStyle(fontSize: 14)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.actorName ?? (row.actorId == null ? l10n.actionsSystem : '—'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (who.isNotEmpty) Text(who, style: small),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(999)),
              child: Text(
                loggedActionName(l10n, row),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: chipFg),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ticketTop != null)
                Text(
                  ticketTop,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              if (ticketBottom.isNotEmpty) Text(ticketBottom.join(' · '), style: small),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reason ?? '—', style: const TextStyle(fontSize: 14)),
              for (final line in extra) Text(line, style: small),
              if (row.flagged) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(Icons.flag_outlined, size: 14, color: tokens.flagText),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        flagsLine(l10n, row, log.rules),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.flagText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          review,
        ]),
      ),
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules({required this.rules});

  final FlagRules rules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final lines = [
      if (rules.otherReason) l10n.ruleOtherReason,
      l10n.ruleTooManyActions(rules.actionsPerShift),
      l10n.ruleReactivatedOtherGate,
      l10n.ruleTooManyPrints(rules.printsPerTicket),
      l10n.ruleUnprinted,
      l10n.ruleOffline,
    ];
    return Container(
      key: const ValueKey('actions-rules'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.actionsRulesTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $line', style: TextStyle(fontSize: 14, color: tokens.textMuted)),
            ),
          const SizedBox(height: 4),
          Text(
            l10n.actionsRulesFootnote,
            style: TextStyle(fontSize: 14, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.text, required this.bg, required this.fg, this.border});

  final String text;
  final Color bg;
  final Color fg;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: bg,
      border: border == null ? null : Border.all(color: border!),
      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
    ),
    child: Text(text, style: TextStyle(fontSize: 14, color: fg)),
  );
}
