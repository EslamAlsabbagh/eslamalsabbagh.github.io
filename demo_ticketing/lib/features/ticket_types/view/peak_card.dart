import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/peak_cubit.dart';
import '../data/peak_state.dart';
import '../data/ticket_types_repository.dart';
import 'peak_time_dialog.dart';
import 'ticket_types_messages.dart';

/// Peak time (ADR-0033): peak now and why, and today's switch (supervisors
/// and admins). With [editSchedule] (the Ticket types page, admins) it also
/// edits the schedule: peak days, and the daily hours on the other days.
class PeakCard extends StatelessWidget {
  const PeakCard({super.key, this.editSchedule = false});

  final bool editSchedule;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => PeakCubit(context.read<TicketTypesRepository>())..start(),
    child: _PeakCardView(editSchedule: editSchedule),
  );
}

class _PeakCardView extends StatelessWidget {
  const _PeakCardView({required this.editSchedule});

  final bool editSchedule;

  Future<void> _setMode(BuildContext context, PeakMode mode) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failure = await context.read<PeakCubit>().setMode(mode);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(failure == null ? l10n.peakSwitched : typesFailureMessage(l10n, failure)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<PeakCubit>().state;
    final peak = state.peak;

    final Widget content;
    if (peak == null) {
      final failure = state.loadFailure;
      content = failure == null
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            )
          : Row(
              children: [
                Expanded(child: Text(typesFailureMessage(l10n, failure))),
                TextButton(onPressed: context.read<PeakCubit>().refresh, child: Text(l10n.retry)),
              ],
            );
    } else {
      final reason = peakSourceText(l10n, peak.source);
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                peak.peak ? Icons.local_fire_department : Icons.schedule,
                size: 20,
                color: peak.peak ? tokens.warningText : tokens.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  peak.peak ? l10n.peakNowOn(reason) : l10n.peakNowOff(reason),
                  key: const ValueKey('peak-now'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in PeakMode.values)
                ChoiceChip(
                  key: ValueKey('peak-mode-${mode.key}'),
                  label: Text(peakModeText(l10n, mode)),
                  selected: peak.mode == mode,
                  onSelected: state.busy || peak.mode == mode
                      ? null
                      : (_) => _setMode(context, mode),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            switch (peak.switchDay) {
              final day? => l10n.peakModeHelpDay(
                DateFormat('dd/MM').format(day),
                peakTimeText(peak.dayStartSeconds),
              ),
              null => l10n.peakModeHelp,
            },
            key: const ValueKey('peak-mode-help'),
            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
          ),
          if (editSchedule) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: tokens.rowDivider),
            const SizedBox(height: 16),
            // A new editor when the saved schedule changes, so it starts from it.
            _ScheduleEditor(
              key: ValueKey('peak-schedule-${peak.weekdays}-${peak.fromSeconds}-${peak.toSeconds}'),
              peak: peak,
              busy: state.busy,
            ),
          ],
        ],
      );
    }

    return DecoratedBox(
      key: const ValueKey('peak-card'),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.peakTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }
}

class _ScheduleEditor extends StatefulWidget {
  const _ScheduleEditor({super.key, required this.peak, required this.busy});

  final PeakState peak;
  final bool busy;

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  /// A new range starts at the usual evening peak.
  static const _defaultFrom = 16 * 3600;
  static const _defaultTo = 22 * 3600;

  late final Set<int> _days = {...widget.peak.weekdays};
  late bool _hoursOn = widget.peak.fromSeconds != null;
  late int _from = widget.peak.fromSeconds ?? _defaultFrom;
  late int _to = widget.peak.toSeconds ?? _defaultTo;

  int? get _fromSeconds => _hoursOn ? _from : null;
  int? get _toSeconds => _hoursOn ? _to : null;

  /// The range inside opening hours (ADR-0038): past midnight is fine, across
  /// the day start or after closing isn't.
  bool get _hoursValid => !_hoursOn || widget.peak.venueDay.hoursFit(_from, _to);

  /// Why the range can't be saved: across the start, or after closing.
  String _hoursError(AppLocalizations l10n) => widget.peak.venueDay.rangeFits(_from, _to)
      ? l10n.peakHoursAfterClosing
      : l10n.peakInvalidHours;

  bool get _changedFromSaved =>
      _days.length != widget.peak.weekdays.length ||
      !_days.containsAll(widget.peak.weekdays) ||
      _fromSeconds != widget.peak.fromSeconds ||
      _toSeconds != widget.peak.toSeconds;

  Future<void> _pick({required bool start}) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showPeakTimeDialog(
      context,
      title: start ? l10n.peakFrom : l10n.peakTo,
      initialSeconds: start ? _from : _to,
    );
    if (picked == null || !mounted) return;
    setState(() => start ? _from = picked : _to = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failure = await context.read<PeakCubit>().saveTimes(
      weekdays: _days,
      fromSeconds: _fromSeconds,
      toSeconds: _toSeconds,
    );
    messenger?.showSnackBar(
      SnackBar(
        content: Text(failure == null ? l10n.peakSaved : typesFailureMessage(l10n, failure)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).languageCode;

    Widget time(String key, String label, int seconds, {required bool start}) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
        const SizedBox(height: 4),
        SizedBox(
          height: AppSizes.touchTarget,
          child: OutlinedButton.icon(
            key: ValueKey(key),
            onPressed: () => _pick(start: start),
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(
              peakTimeText(seconds),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(side: BorderSide(color: tokens.inputBorder)),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.peakWeekdaysLabel,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in peakWeekOrder)
              FilterChip(
                key: ValueKey('peak-day-$day'),
                label: Text(weekdayName(locale, day)),
                selected: _days.contains(day),
                onSelected: (on) => setState(() => on ? _days.add(day) : _days.remove(day)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.peakHoursLabel,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Switch(
              key: const ValueKey('peak-hours-on'),
              value: _hoursOn,
              onChanged: (on) => setState(() => _hoursOn = on),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_hoursOn) ...[
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              time('peak-from', l10n.peakFrom, _from, start: true),
              time('peak-to', l10n.peakTo, _to, start: false),
            ],
          ),
          const SizedBox(height: 6),
          if (!_hoursValid)
            Text(
              _hoursError(l10n),
              key: const ValueKey('peak-hours-error'),
              style: TextStyle(fontSize: 12, color: tokens.dangerText),
            )
          else
            Text(
              l10n.peakHoursPastMidnight(peakTimeText(widget.peak.closingSeconds)),
              key: const ValueKey('peak-hours-hint'),
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
        ] else
          Text(
            l10n.peakNoHours,
            key: const ValueKey('peak-no-hours'),
            style: TextStyle(fontSize: 13, color: tokens.textSecondary),
          ),
        const SizedBox(height: 14),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            height: AppSizes.touchTarget,
            child: FilledButton(
              key: const ValueKey('peak-save'),
              onPressed: widget.busy || !_hoursValid || !_changedFromSaved ? null : _save,
              child: Text(l10n.peakSave),
            ),
          ),
        ),
      ],
    );
  }
}
