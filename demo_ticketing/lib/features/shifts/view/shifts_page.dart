import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../app/router.dart';
import '../../../core/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../sell/view/sell_messages.dart';
import '../../tickets/data/ticket_lookup.dart';
import '../../tickets/view/ticket_messages.dart';
import '../bloc/shifts_cubit.dart';
import '../data/shift_models.dart';
import '../data/shifts_repository.dart';

/// Shifts and cash reconciliation (task 4.2, `Shifts.dc.html`). Expected cash
/// shows here only (ADR-0008); nobody approves or clears their own shift
/// (ADR-0017, ADR-0026), which the server enforces too.
class ShiftsPage extends StatelessWidget {
  const ShiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final badge = context.read<PendingShiftsCubit>();
    return BlocProvider(
      create: (context) =>
          ShiftsCubit(context.read<ShiftsRepository>(), onPendingCount: badge.set)..start(),
      child: const _ShiftsView(),
    );
  }
}

String shiftsFailureMessage(AppLocalizations l10n, ShiftsFailureKind kind) => switch (kind) {
  ShiftsFailureKind.notAllowed => l10n.shiftsNotAllowed,
  ShiftsFailureKind.serverUnreachable => l10n.errorServerUnreachable,
  ShiftsFailureKind.commentRequired => l10n.shiftFailureCommentRequired,
  ShiftsFailureKind.ownShift => l10n.shiftFailureOwnShift,
  ShiftsFailureKind.alreadyApproved => l10n.shiftFailureAlreadyApproved,
  ShiftsFailureKind.notClosed => l10n.shiftFailureNotClosed,
  ShiftsFailureKind.refusalAlreadyClosed => l10n.shiftFailureRefusalClosed,
  ShiftsFailureKind.notFound => l10n.shiftFailureNotFound,
  ShiftsFailureKind.unexpected => l10n.shiftsUnexpected,
};

/// A difference as the design writes it: "0", "− 50 ج.م", "+ 20 ج.م".
String differenceText(AppLocalizations l10n, int piastres) => switch (piastres) {
  0 => '0',
  < 0 => '− ${formatMoney(l10n, -piastres)}',
  _ => '+ ${formatMoney(l10n, piastres)}',
};

/// A time on this PC's clock ("17:04"), with the date when it isn't [day]
/// ("27/10 17:04"). The PC's zone should be the venue's.
String _time(DateTime at, DateTime day) {
  final local = at.toLocal();
  final sameDay = local.year == day.year && local.month == day.month && local.day == day.day;
  return DateFormat(sameDay ? 'HH:mm' : 'dd/MM HH:mm').format(local);
}

/// Opened → closed. The range is isolated left to right, so it reads the same
/// next to Arabic names in either language.
String _span(AppLocalizations l10n, ShiftRow s, DateTime day) => switch (s.closedAt) {
  final closed? => '\u2066${_time(s.openedAt, day)} → ${_time(closed, day)}\u2069',
  null => l10n.shiftUntilOpen(_time(s.openedAt, day)),
};

class _ShiftsView extends StatelessWidget {
  const _ShiftsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<ShiftsCubit>().state;
    final overview = state.overview;
    final cubit = context.read<ShiftsCubit>();

    // The header stays put; what's under it scrolls.
    const bottom = EdgeInsets.only(bottom: 24);
    final Widget body;
    if (overview == null) {
      final failure = state.failure;
      body = failure == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Text(
                    shiftsFailureMessage(l10n, failure),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (failure != ShiftsFailureKind.notAllowed)
                    FilledButton(onPressed: cubit.refresh, child: Text(l10n.retry)),
                ],
              ),
            );
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final list = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ShiftTable(overview: overview, selectedId: state.selectedId),
              if (overview.orphanEntries.isNotEmpty) ...[
                const SizedBox(height: 18),
                _Orphans(entries: overview.orphanEntries, day: overview.day),
              ],
            ],
          );
          final detail = _Detail(state: state, day: overview.day);
          if (constraints.maxWidth < 900) {
            // Too narrow for two columns: one scroll, the detail under the list.
            return SingleChildScrollView(
              padding: bottom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [list, const SizedBox(height: 18), detail],
              ),
            );
          }
          // Each column scrolls on its own, so a long list never pushes the
          // selected shift's detail out of view.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  key: const ValueKey('shifts-list-scroll'),
                  padding: bottom,
                  child: list,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  key: const ValueKey('shift-detail-scroll'),
                  padding: bottom,
                  child: detail,
                ),
              ),
            ],
          );
        },
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
                    l10n.shiftsTitle,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l10n.shiftsSubtitle,
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PeriodChips(
                    period: state.period,
                    pendingCount: overview?.pendingCount ??
                        context.watch<PendingShiftsCubit>().state,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.shiftsRefresh,
                    onPressed: cubit.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ),
          if (overview != null && state.failure != null) ...[
            const SizedBox(height: 16),
            _Banner(
              text: shiftsFailureMessage(l10n, state.failure!),
              bg: tokens.warningBg,
              fg: tokens.warningText,
              border: tokens.warningBorder,
            ),
          ],
          const SizedBox(height: 18),
          // Scrolls by wheel or drag, with no scrollbar (asked for in review).
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

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.period, required this.pendingCount});

  final ShiftsPeriod period;
  final int? pendingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    String label(ShiftsPeriod p) => switch (p) {
      ShiftsPeriod.today => l10n.shiftsPeriodToday,
      ShiftsPeriod.yesterday => l10n.shiftsPeriodYesterday,
      ShiftsPeriod.week => l10n.shiftsPeriodWeek,
      ShiftsPeriod.pending => l10n.shiftsPeriodPending(pendingCount ?? 0),
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final p in ShiftsPeriod.values)
            Semantics(
              selected: p == period,
              button: true,
              child: Material(
                color: p == period ? tokens.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.read<ShiftsCubit>().setPeriod(p),
                  child: Container(
                    height: AppSizes.touchTarget,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    child: Text(
                      label(p),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p == period ? tokens.surface : tokens.text,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ShiftStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final (text, bg, fg) = switch (status) {
      ShiftStatus.open => (l10n.shiftStatusOpen, tokens.primaryTint, tokens.onPrimaryTint),
      ShiftStatus.closed => (l10n.shiftStatusNeedsApproval, tokens.warningBg, tokens.warningText),
      ShiftStatus.approved => (l10n.shiftStatusApproved, tokens.successBg, tokens.successText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

Color _differenceColor(AppTokens tokens, int? piastres) => switch (piastres) {
  null || 0 => tokens.successText,
  < 0 => tokens.dangerText,
  _ => tokens.warningText,
};

class _ShiftTable extends StatelessWidget {
  const _ShiftTable({required this.overview, required this.selectedId});

  final ShiftsOverview overview;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    const flexes = [3, 4, 3, 3, 3, 4];
    Widget cells(List<Widget> children) => Row(
      children: [
        for (var i = 0; i < children.length; i++)
          Expanded(
            flex: flexes[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: children[i],
            ),
          ),
      ],
    );
    final header = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: cells([
                Text(l10n.shiftsColShift, style: header),
                Text(l10n.shiftsColCashier, style: header),
                Text(l10n.shiftsColExpected, style: header),
                Text(l10n.shiftsColCounted, style: header),
                Text(l10n.shiftsColDifference, style: header),
                Text(l10n.shiftsColStatus, style: header),
              ]),
            ),
            if (overview.shifts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  overview.period == ShiftsPeriod.pending ? l10n.shiftsEmptyPending : l10n.shiftsEmpty,
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ),
            for (final s in overview.shifts)
              DecoratedBox(
                key: ValueKey('shift-row-${s.id}'),
                decoration: BoxDecoration(
                  color: s.id == selectedId ? tokens.primaryTint : null,
                  border: Border(top: BorderSide(color: tokens.rowDivider)),
                ),
                child: Semantics(
                  selected: s.id == selectedId,
                  button: true,
                  child: InkWell(
                    onTap: () => context.read<ShiftsCubit>().select(s.id),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: cells([
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${s.number}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                _span(l10n, s, overview.day),
                                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.cashierName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                s.counterName,
                                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                              ),
                            ],
                          ),
                          Text(s.isOpen ? '—' : formatMoney(l10n, s.expectedCashPiastres)),
                          Text(switch (s.countedCashPiastres) {
                            final counted? => formatMoney(l10n, counted),
                            null => '—',
                          }),
                          Text(
                            switch (s.differencePiastres) {
                              final d? => differenceText(l10n, d),
                              null => '—',
                            },
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _differenceColor(tokens, s.differencePiastres),
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _StatusChip(status: s.status),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Orphans extends StatelessWidget {
  const _Orphans({required this.entries, required this.day});

  final List<OrphanEntry> entries;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.warningBg,
        border: Border.all(color: tokens.warningBorder),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l10n.orphansTitle} (${entries.length})',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tokens.warningText),
          ),
          const SizedBox(height: 4),
          Text(l10n.orphansHint, style: TextStyle(fontSize: 13, color: tokens.warningText)),
          const SizedBox(height: 10),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${e.counterName} · ${e.gateName} · ${_time(e.scannedAt, day)}',
                style: TextStyle(fontSize: 14, color: tokens.warningText),
              ),
            ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.state, required this.day});

  final ShiftsState state;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final s = state.selected;
    if (s == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Text(l10n.shiftsPickOne, style: TextStyle(color: tokens.textSecondary)),
        ),
      );
    }
    final auth = context.watch<AuthCubit>().state;
    final ownShift = auth is AuthSignedIn && auth.staff.id == s.cashierId;
    final difference = s.differencePiastres;

    Widget line(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: bold
                  ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)
                  : TextStyle(fontSize: 14, color: tokens.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
          ),
        ],
      ),
    );

    return Card(
      key: ValueKey('shift-detail-${s.id}'),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.shiftTitle(s.number),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${s.cashierName} · ${s.counterName} · ${_span(l10n, s, day)}',
                        style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusChip(status: s.status),
              ],
            ),
            const SizedBox(height: 14),
            line(l10n.shiftOpeningFloat, formatMoney(l10n, s.openingCashPiastres)),
            line(l10n.shiftCashSales, formatMoney(l10n, s.cashSalesPiastres)),
            line(l10n.shiftTips(s.tipCount), formatMoney(l10n, s.tipsPiastres)),
            line(
              l10n.shiftCashRefunds,
              s.cashRefundsPiastres == 0 ? formatMoney(l10n, 0) : '− ${formatMoney(l10n, s.cashRefundsPiastres)}',
            ),
            Divider(color: tokens.border, height: 16),
            line(l10n.shiftExpected, formatMoney(l10n, s.expectedCashPiastres), bold: true),
            line(
              l10n.shiftCounted,
              switch (s.countedCashPiastres) {
                final c? => formatMoney(l10n, c),
                null => '—',
              },
              bold: true,
            ),
            if (difference != null) ...[
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('shift-difference'),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: switch (difference) {
                    0 => tokens.successBg,
                    < 0 => tokens.dangerBg,
                    _ => tokens.warningBg,
                  },
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        switch (difference) {
                          0 => l10n.shiftBalanced,
                          < 0 => l10n.shiftShortage,
                          _ => l10n.shiftSurplus,
                        },
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _differenceColor(tokens, difference),
                        ),
                      ),
                    ),
                    Text(
                      differenceText(l10n, difference),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _differenceColor(tokens, difference),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.shiftNonCash(
                      formatMoney(l10n, s.cardSalesPiastres),
                      formatMoney(l10n, s.walletSalesPiastres),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.shiftPaidOrders(s.paidOrders)),
                  const SizedBox(height: 4),
                  // The design's link to the log, filtered by this shift (4.3).
                  InkWell(
                    key: const ValueKey('shift-actions-link'),
                    onTap: () => context.go(AppRoutes.actionsOfShift(s.id)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        s.flaggedActionCount > 0
                            ? l10n.shiftActionsFlagged(s.actionCount, s.flaggedActionCount)
                            : l10n.shiftActions(s.actionCount),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: tokens.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: tokens.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (s.offlineOrders > 0 || s.unsyncedEntries > 0 || s.refusedOfflineOrders > 0) ...[
              const SizedBox(height: 12),
              _Banner(
                key: const ValueKey('shift-offline'),
                text: [
                  if (s.offlineOrders > 0) l10n.shiftOfflineOrders(s.offlineOrders),
                  if (s.unsyncedEntries > 0) l10n.shiftUnsyncedEntries(s.unsyncedEntries),
                  if (s.refusedOfflineOrders > 0) l10n.shiftRefusedOrders(s.refusedOfflineOrders),
                ].join('\n'),
                bg: tokens.warningBg,
                fg: tokens.warningText,
                border: tokens.warningBorder,
              ),
            ],
            if (state.detailFailure case final failure?) ...[
              const SizedBox(height: 12),
              _Banner(
                text: '${l10n.shiftDetailFailed} ${shiftsFailureMessage(l10n, failure)}',
                bg: tokens.dangerBg,
                fg: tokens.dangerText,
                border: tokens.dangerBorder,
              ),
            ],
            _Refusals(refusals: state.refusals, ownShift: ownShift, day: day, busy: state.busy),
            const SizedBox(height: 14),
            switch (s.status) {
              ShiftStatus.open => _Banner(
                text: l10n.shiftOpenNote,
                bg: tokens.primaryTint,
                fg: tokens.onPrimaryTint,
              ),
              ShiftStatus.approved => _Banner(
                text: [
                  l10n.shiftApprovedBy(
                    s.approvedByName ?? '—',
                    s.approvedAt == null ? '—' : _time(s.approvedAt!, day),
                  ),
                  if (s.approvalComment case final comment?) l10n.shiftApprovalComment(comment),
                ].join('\n'),
                bg: tokens.successBg,
                fg: tokens.successText,
              ),
              ShiftStatus.closed when ownShift => _Banner(
                key: const ValueKey('shift-own'),
                text: l10n.shiftOwnShift,
                bg: tokens.inset,
                fg: tokens.text,
              ),
              ShiftStatus.closed => _ApproveBox(
                key: ValueKey('approve-${s.id}'),
                shift: s,
                busy: state.busy,
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _ApproveBox extends StatefulWidget {
  const _ApproveBox({super.key, required this.shift, required this.busy});

  final ShiftRow shift;
  final bool busy;

  @override
  State<_ApproveBox> createState() => _ApproveBoxState();
}

class _ApproveBoxState extends State<_ApproveBox> {
  final _comment = TextEditingController();
  ShiftsFailureKind? _failure;

  @override
  void initState() {
    super.initState();
    _comment.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _required => (widget.shift.differencePiastres ?? 0) != 0;

  Future<void> _approve() async {
    final number = widget.shift.number;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    final failure = await context.read<ShiftsCubit>().approve(_comment.text);
    if (failure == null) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.shiftApprovedDone(number))));
    } else if (mounted) {
      setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final canApprove = !widget.busy && (!_required || _comment.text.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _required ? l10n.shiftNoteRequired : l10n.shiftNoteOptional,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('approve-comment'),
          controller: _comment,
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: FilledButton(
            key: const ValueKey('approve-button'),
            onPressed: canApprove ? _approve : null,
            child: widget.busy
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    l10n.shiftApprove,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        if (_failure case final failure?) ...[
          const SizedBox(height: 8),
          Text(shiftsFailureMessage(l10n, failure), style: TextStyle(color: tokens.dangerText)),
        ],
      ],
    );
  }
}

class _Refusals extends StatelessWidget {
  const _Refusals({
    required this.refusals,
    required this.ownShift,
    required this.day,
    required this.busy,
  });

  final List<OfflineRefusal>? refusals;
  final bool ownShift;
  final DateTime day;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final list = refusals;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l10n.refusalsTitle} (${list.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          for (final r in list)
            _RefusalCard(refusal: r, ownShift: ownShift, day: day, busy: busy),
        ],
      ),
    );
  }
}

class _RefusalCard extends StatelessWidget {
  const _RefusalCard({
    required this.refusal,
    required this.ownShift,
    required this.day,
    required this.busy,
  });

  final OfflineRefusal refusal;
  final bool ownShift;
  final DateTime day;
  final bool busy;

  String _summary(AppLocalizations l10n, String locale) {
    final sent = refusal.sent;
    if (refusal.kind == RefusalKind.order) {
      final types = [
        for (final t in sent.ticketsByType)
          '${(locale == 'ar' ? t.nameAr : t.nameEn) ?? l10n.refusalUnknownType} ${t.count}',
      ];
      final count = sent.ticketCount;
      final tickets = [
        if (count != null) l10n.refusalTicketCount(count),
        if (types.isNotEmpty) '(${types.join(locale == 'ar' ? '، ' : ', ')})',
      ].join(' ');
      final method = switch (sent.paymentMethod) {
        'cash' => l10n.paymentCash,
        'card' => l10n.paymentCard,
        'wallet' => l10n.paymentWallet,
        final other => other ?? '—',
      };
      return [
        l10n.refusalOrderSummary(
          sent.soldAt == null ? '—' : _time(sent.soldAt!, day),
          method,
          tickets.isEmpty ? '—' : tickets,
        ),
        if ((sent.tipPiastres ?? 0) > 0) l10n.refusalTip(formatMoney(l10n, sent.tipPiastres!)),
      ].join(' · ');
    }
    final action = switch (sent.action) {
      'reprint' => l10n.actionReprint,
      'left_unprinted' => l10n.refusalLeftUnprinted,
      final other => other ?? '—',
    };
    final reason = switch (sent.reason) {
      'other' when sent.reasonText != null => sent.reasonText!,
      final key? => switch (ActionReason.fromKey(key)) {
        final r? => actionReasonName(l10n, r),
        null => sent.reasonText ?? key,
      },
      null => sent.reasonText,
    };
    return [
      action,
      if (sent.at != null) _time(sent.at!, day),
      ?reason,
    ].join(' · ');
  }

  Future<void> _clear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final cubit = context.read<ShiftsCubit>();
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => const _ClearDialog(),
    );
    if (comment == null) return;
    final failure = await cubit.resolveRefusal(refusal.id, comment);
    if (failure != null) {
      messenger?.showSnackBar(SnackBar(content: Text(shiftsFailureMessage(l10n, failure))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).languageCode;
    final open = refusal.isOpen;
    return Container(
      key: ValueKey('refusal-${refusal.id}'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: open ? tokens.dangerBg : tokens.inset,
        border: Border.all(color: open ? tokens.dangerBorder : tokens.border),
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${refusal.kind == RefusalKind.order ? l10n.refusalKindOrder : l10n.refusalKindAction}'
            ' · ${offlineRefusalMessage(l10n, refusal.error)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: open ? tokens.dangerText : tokens.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(_summary(l10n, locale), style: const TextStyle(fontSize: 13)),
          Text(
            l10n.refusalReportedAt(_time(refusal.reportedAt, day)),
            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
          ),
          const SizedBox(height: 6),
          if (refusal.resolvedAt != null)
            Text(
              l10n.refusalCleared(
                refusal.resolvedByName ?? '—',
                _time(refusal.resolvedAt!, day),
                refusal.resolutionComment ?? '',
              ),
              style: TextStyle(fontSize: 13, color: tokens.successText),
            )
          else if (refusal.acceptedAt != null)
            Text(l10n.refusalAccepted, style: TextStyle(fontSize: 13, color: tokens.successText))
          else ...[
            Text(l10n.refusalOpen, style: TextStyle(fontSize: 13, color: tokens.dangerText)),
            const SizedBox(height: 8),
            if (ownShift)
              Text(l10n.refusalOwnShift, style: TextStyle(fontSize: 13, color: tokens.textSecondary))
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(
                  key: ValueKey('refusal-clear-${refusal.id}'),
                  onPressed: busy ? null : () => _clear(context),
                  child: Text(l10n.refusalClear),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Asks for the required comment; pops it, or null on Back.
class _ClearDialog extends StatefulWidget {
  const _ClearDialog();

  @override
  State<_ClearDialog> createState() => _ClearDialogState();
}

class _ClearDialogState extends State<_ClearDialog> {
  final _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _comment.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = _comment.text.trim();
    return AlertDialog(
      title: Text(l10n.refusalClearTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.refusalClearBody),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('refusal-comment'),
              controller: _comment,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.refusalCommentLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.back)),
        FilledButton(
          key: const ValueKey('refusal-clear-confirm'),
          onPressed: text.isEmpty ? null : () => Navigator.of(context).pop(text),
          child: Text(l10n.refusalClear),
        ),
      ],
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
