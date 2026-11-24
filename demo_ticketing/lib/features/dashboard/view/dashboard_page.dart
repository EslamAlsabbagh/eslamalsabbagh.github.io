import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/clock.dart';
import '../../../core/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ticket_types/view/peak_card.dart';
import '../../tickets/view/ticket_messages.dart';
import '../bloc/dashboard_cubit.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_snapshot.dart';
import 'hourly_chart.dart';

/// The live dashboard (task 4.1, `Dashboard.dc.html`, ADR-0030).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        DashboardCubit(context.read<DashboardRepository>(), clock: context.read<Clock>())..start(),
    child: const _DashboardView(),
  );
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<DashboardCubit>().state;
    final snapshot = state.snapshot;

    if (snapshot == null) {
      final failure = state.failure;
      if (failure == null) return const Center(child: CircularProgressIndicator());
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _failureText(l10n, failure),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (failure != DashboardFailureKind.notAllowed)
              FilledButton(
                onPressed: () => context.read<DashboardCubit>().refresh(),
                child: Text(l10n.retry),
              ),
          ],
        ),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    final date = DateFormat.MMMMEEEEd(locale).format(snapshot.day);
    final now = context.read<Clock>().now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                    l10n.navDashboard,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    state.live
                        ? l10n.dashboardDateLive(date)
                        : l10n.dashboardDatePolling(date, DashboardCubit.pollEvery.inSeconds),
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                ],
              ),
              state.live
                  ? _Pill(
                      label: l10n.dashboardLive,
                      bg: tokens.successBg,
                      fg: tokens.successText,
                      dot: tokens.successDot,
                    )
                  : _Pill(
                      label: l10n.dashboardNotLive,
                      bg: tokens.warningBg,
                      fg: tokens.warningText,
                      dot: tokens.warningBorder,
                    ),
            ],
          ),
          if (state.failure case final failure?) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.warningBg,
                border: Border.all(color: tokens.warningBorder),
                borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              ),
              child: Text(
                failure == DashboardFailureKind.serverUnreachable
                    ? l10n.dashboardStale(DateFormat('HH:mm:ss').format(state.updatedAt ?? now))
                    : _failureText(l10n, failure),
                style: TextStyle(fontSize: 14, color: tokens.warningText),
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Today's peak switch (ADR-0033): supervisors are the ones on site.
          const PeakCard(),
          const SizedBox(height: 20),
          _Grid(minWidth: 200, children: _kpis(l10n, snapshot)),
          const SizedBox(height: 20),
          Text(l10n.navGates, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (snapshot.gates.isEmpty)
            Text(l10n.dashboardNoGates, style: TextStyle(color: tokens.textSecondary))
          else
            _Grid(
              minWidth: 240,
              children: [
                for (final gate in snapshot.gates)
                  _GateCardView(gate: gate, serverNow: state.serverNow ?? snapshot.now, now: now),
              ],
            ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final chart = _Section(
                title: l10n.dashboardHourlyTitle,
                child: HourlyChart(
                  hours: snapshot.hours,
                  currentHour: snapshot.currentHour,
                  startHour: snapshot.dayStartHour,
                ),
              );
              final feed = _Section(
                title: l10n.dashboardFeedTitle,
                child: _Feed(scans: snapshot.feed, now: now),
              );
              if (constraints.maxWidth < 760) {
                return Column(children: [chart, const SizedBox(height: 20), feed]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: feed),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static List<Widget> _kpis(AppLocalizations l10n, DashboardSnapshot s) {
    final count = NumberFormat('#,##0', l10n.localeName);
    final reasons = s.rejectedByReason.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [
      _Kpi(
        label: l10n.dashboardEntriesToday,
        value: count.format(s.entries),
        note: switch (s.firstEntryAt) {
          final first? => l10n.dashboardSince(DateFormat('HH:mm').format(first.toLocal())),
          null => l10n.dashboardNoEntriesYet,
        },
      ),
      _Kpi(
        label: l10n.dashboardSalesToday,
        value: formatMoney(l10n, s.salesPiastres),
        note: l10n.dashboardOpenCounters(s.openCounters),
      ),
      _Kpi(
        label: l10n.dashboardTicketsSold,
        value: count.format(s.ticketsSold),
        note: l10n.dashboardNotEntered(s.ticketsNotEntered),
      ),
      _Kpi(
        label: l10n.dashboardRejected,
        value: count.format(s.rejected),
        note: reasons.isEmpty
            ? l10n.dashboardNoRejections
            : [
                for (final reason in reasons.take(2))
                  l10n.dashboardReasonCount(reason.value, scanReasonName(l10n, reason.key)),
              ].join(' · '),
        danger: s.rejected > 0,
      ),
    ];
  }
}

String _failureText(AppLocalizations l10n, DashboardFailureKind kind) => switch (kind) {
  DashboardFailureKind.notAllowed => l10n.dashboardNotAllowed,
  DashboardFailureKind.serverUnreachable => l10n.dashboardUnreachable,
  DashboardFailureKind.unexpected => l10n.dashboardUnexpected,
};

/// The design's `repeat(auto-fit, minmax(minWidth, 1fr))` with a 14 px gap.
class _Grid extends StatelessWidget {
  const _Grid({required this.minWidth, required this.children});

  final double minWidth;
  final List<Widget> children;

  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = ((constraints.maxWidth + _gap) ~/ (minWidth + _gap)).clamp(
        1,
        children.length,
      );
      final width = (constraints.maxWidth - _gap * (columns - 1)) / columns;
      return Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    },
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg, required this.dot});

  final String label;
  final Color bg;
  final Color fg;
  final Color dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
        ),
      ],
    ),
  );
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.note, this.danger = false});

  final String label;
  final String value;
  final String note;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: tokens.textSecondary)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              note,
              style: TextStyle(
                fontSize: 13,
                color: danger ? tokens.dangerText : tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GateCardView extends StatelessWidget {
  const _GateCardView({required this.gate, required this.serverNow, required this.now});

  final GateCard gate;

  /// The server's time now, for the last scan's age.
  final DateTime serverNow;

  /// This PC's time now, to say "today" in a time.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final (status, bg, fg, dot) = switch (gate.status) {
      GateLiveStatus.online => (
        l10n.gateOnline,
        tokens.successBg,
        tokens.successText,
        tokens.successDot,
      ),
      GateLiveStatus.offline => (
        l10n.gateOffline,
        tokens.dangerBg,
        tokens.dangerText,
        tokens.dangerAction,
      ),
      GateLiveStatus.neverSeen => (
        l10n.gateNeverSeen,
        tokens.dangerBg,
        tokens.dangerText,
        tokens.dangerAction,
      ),
      GateLiveStatus.disabled => (
        l10n.gateDisabled,
        tokens.inset,
        tokens.textSecondary,
        tokens.inputBorder,
      ),
    };
    final down = gate.status == GateLiveStatus.offline || gate.status == GateLiveStatus.neverSeen;
    final note = switch (gate.status) {
      GateLiveStatus.online => _lastScan(l10n),
      GateLiveStatus.offline => l10n.gateOfflineSince(
        gate.lastSeenAt == null ? '—' : dayTime(l10n, gate.lastSeenAt!, now),
      ),
      GateLiveStatus.neverSeen => l10n.gateNeverSeenNote,
      GateLiveStatus.disabled => l10n.gateDisabledNote,
    };
    final row = TextStyle(fontSize: 14, color: tokens.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: down ? tokens.dangerBorder : tokens.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  gate.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              _Pill(label: status, bg: bg, fg: fg, dot: dot),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(l10n.gateEntriesToday, style: row)),
              Text('${gate.entries}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(l10n.gateRejected, style: row)),
              Text('${gate.rejected}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: TextStyle(fontSize: 13, color: down ? tokens.dangerText : tokens.textSecondary),
          ),
        ],
      ),
    );
  }

  String _lastScan(AppLocalizations l10n) {
    final at = gate.lastScanAt;
    if (at == null) return l10n.gateNoScans;
    final age = serverNow.difference(at);
    if (age < const Duration(minutes: 1)) {
      return l10n.gateLastScanSeconds(age.inSeconds < 1 ? 1 : age.inSeconds);
    }
    if (age < const Duration(hours: 1)) return l10n.gateLastScanMinutes(age.inMinutes);
    return l10n.gateLastScanAt(dayTime(l10n, at, now));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _Feed extends StatelessWidget {
  const _Feed({required this.scans, required this.now});

  /// How many scans fit before the feed scrolls.
  static const _visibleRows = 5;

  /// One row: two text lines plus the 8px top and bottom padding they had.
  static const _rowHeight = 60.0;

  final List<FeedScan> scans;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    if (scans.isEmpty) {
      return Text(l10n.dashboardFeedEmpty, style: TextStyle(color: tokens.textSecondary));
    }
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    // Every row has the same fixed height, so the list shows about
    // [_visibleRows] scans and scrolls for the rest. Scaled with the text so
    // a larger system font doesn't clip the two lines.
    final rowHeight = MediaQuery.textScalerOf(context).scale(_rowHeight);
    return SizedBox(
      height: rowHeight * (scans.length < _visibleRows ? scans.length : _visibleRows),
      child: ScrollConfiguration(
        // Scrolls with the wheel or a drag, without the desktop scrollbar.
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          itemCount: scans.length,
          itemExtent: rowHeight,
          itemBuilder: (context, i) {
            final scan = scans[i];
            return Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: tokens.rowDivider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${scan.gateName} · ${(arabic ? scan.typeNameAr : scan.typeNameEn) ?? (scan.poolCode ? l10n.feedPoolCode : '—')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          dayTime(l10n, scan.scannedAt, now, seconds: true),
                          maxLines: 1,
                          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: scan.accepted ? tokens.successBg : tokens.dangerBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      scan.accepted ? l10n.feedAccepted : scanReasonName(l10n, scan.reason),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scan.accepted ? tokens.successText : tokens.dangerText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
