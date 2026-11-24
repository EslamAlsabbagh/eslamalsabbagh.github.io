import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/clock.dart';
import '../../../core/venue_day.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ticket_types/view/peak_time_dialog.dart';
import '../../ticket_types/view/ticket_types_messages.dart'
    show peakTimeText, peakWeekOrder, weekdayName;
import '../../tickets/view/ticket_messages.dart' show dayTime;
import '../bloc/settings_cubit.dart';
import '../data/settings_models.dart';
import '../data/settings_repository.dart';
import 'counter_dialog.dart';
import 'settings_messages.dart';

/// Settings (task 4.8, `Settings.dc.html`): the venue, ticket rules, cashier
/// action limits and review flags, tips and quick amounts, offline and network
/// timings, the counters with their printer and home gate, and the backup
/// status. Admins only; every change is logged (ADR-0037).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => SettingsCubit(context.read<SettingsRepository>())..start(),
    child: const _SettingsView(),
  );
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    final overview = state.overview;

    final Widget body;
    if (overview == null) {
      final failure = state.loadFailure;
      body = failure == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.settingsLoading, style: TextStyle(color: tokens.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Text(
                    settingsFailureMessage(l10n, failure),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (failure != SettingsFailureKind.notAllowed)
                    FilledButton(onPressed: cubit.refresh, child: Text(l10n.retry)),
                ],
              ),
            );
    } else {
      // A new save (here or by another admin) starts the form from it; a
      // counter save or a refresh with the same settings keeps the edits.
      body = _SettingsForm(
        key: ValueKey('settings-form-${overview.updatedAt.toIso8601String()}'),
        overview: overview,
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
              Text(
                l10n.navSettings,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.settingsLogNote,
                    style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.actionsRefresh,
                    onPressed: state.loading ? null : cubit.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// The settings sections and the bottom bar. Holds the typed values; Save
/// sends only what differs from [overview] (`settingsChanges`).
class _SettingsForm extends StatefulWidget {
  const _SettingsForm({super.key, required this.overview});

  final SettingsOverview overview;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _texts = <String, TextEditingController>{};
  late int _dayStartSeconds;
  late int _closingSeconds;
  late String _language;
  late Map<String, bool> _switches;

  /// The server's refusal: on its field ([_refusedField], as [_refusedAs])
  /// or in the bar.
  String? _refusedField;
  SettingError _refusedAs = SettingError.refused;
  SettingsFailure? _failure;

  AdminSettings get _loaded => widget.overview.settings;

  static const _textKeys = ['venue_name', ...amountListSettings];

  @override
  void initState() {
    super.initState();
    for (final key in [..._textKeys, ...settingRanges.keys]) {
      _texts[key] = TextEditingController()..addListener(_changed);
    }
    _fill();
  }

  @override
  void dispose() {
    for (final c in _texts.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// The fields from the loaded settings: on start and on Undo.
  void _fill() {
    final s = _loaded;
    _texts['venue_name']!.text = s.venueName;
    for (final key in amountListSettings) {
      _texts[key]!.text = amountListText(s.amountLists[key]!);
    }
    for (final key in settingRanges.keys) {
      _texts[key]!.text = '${s.numbers[key]}';
    }
    _dayStartSeconds = s.dayStartSeconds;
    _closingSeconds = s.closingSeconds;
    _language = s.defaultLanguage;
    _switches = Map.of(s.switches);
    _refusedField = null;
    _failure = null;
  }

  void _changed() => setState(() {
    _refusedField = null;
    _failure = null;
  });

  /// The typed values as settings, and what keeps any from being saved.
  ({AdminSettings? edited, Map<String, SettingError> errors}) _parse() {
    final errors = <String, SettingError>{};
    final venue = _texts['venue_name']!.text.trim();
    if (venue.isEmpty) errors['venue_name'] = SettingError.required;
    final numbers = <String, int>{};
    for (final key in settingRanges.keys) {
      final parsed = parseSettingNumber(key, _texts[key]!.text);
      if (parsed.value case final v?) numbers[key] = v;
      if (parsed.error case final e?) errors[key] = e;
    }
    final lists = <String, List<int>>{};
    for (final key in amountListSettings) {
      final parsed = parseAmountList(key, _texts[key]!.text);
      if (parsed.value case final v?) lists[key] = v;
      if (parsed.error case final e?) errors[key] = e;
    }
    // The daily peak hours must stay inside opening hours (ADR-0038): under the
    // start when they'd cross it, else under the closing time that cuts them.
    final overview = widget.overview;
    if ((overview.peakFromSeconds, overview.peakToSeconds) case (final from?, final to?)) {
      final day = VenueDay(
        start: VenueTime.ofSeconds(_dayStartSeconds),
        closing: VenueTime.ofSeconds(_closingSeconds),
      );
      if (!day.rangeFits(from, to)) {
        errors['venue_day_starts_at'] = SettingError.crossesPeakHours;
      } else if (!day.hoursFit(from, to)) {
        errors[_closingSeconds != _loaded.closingSeconds
            ? 'closing_time'
            : 'venue_day_starts_at'] = _closingSeconds != _loaded.closingSeconds
            ? SettingError.cutsPeakHours
            : SettingError.crossesPeakHours;
      }
    }
    if (_refusedField case final key?) errors[key] = _refusedAs;
    if (errors.isNotEmpty) return (edited: null, errors: errors);
    return (
      edited: AdminSettings(
        venueName: venue,
        dayStartSeconds: _dayStartSeconds,
        closingSeconds: _closingSeconds,
        defaultLanguage: _language,
        numbers: numbers,
        switches: Map.of(_switches),
        amountLists: lists,
      ),
      errors: errors,
    );
  }

  /// Something differs from the loaded settings as typed (not only after
  /// normalizing), so Undo has something to undo.
  bool get _touched {
    final s = _loaded;
    if (_texts['venue_name']!.text != s.venueName) return true;
    for (final key in amountListSettings) {
      if (_texts[key]!.text != amountListText(s.amountLists[key]!)) return true;
    }
    for (final key in settingRanges.keys) {
      if (_texts[key]!.text != '${s.numbers[key]}') return true;
    }
    return _dayStartSeconds != s.dayStartSeconds ||
        _closingSeconds != s.closingSeconds ||
        _language != s.defaultLanguage ||
        switchSettings.any((k) => _switches[k] != s.switches[k]);
  }

  Future<void> _save(AdminSettings edited) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (!await _confirmTimes(edited) || !mounted) return;
    final failure = await context.read<SettingsCubit>().save(edited);
    if (!mounted) return;
    if (failure == null) {
      // The page is rebuilt from the saved settings (a new updated_at).
      messenger?.showSnackBar(SnackBar(content: Text(l10n.typesSaved)));
      return;
    }
    setState(() {
      if (failure.kind == SettingsFailureKind.invalidSetting && failure.field != null) {
        _refusedField = failure.field;
        _refusedAs = SettingError.refused;
      } else if (failure.kind == SettingsFailureKind.peakHoursOutsideOpening) {
        _refusedField = failure.field;
        _refusedAs = failure.field == 'closing_time'
            ? SettingError.cutsPeakHours
            : SettingError.crossesPeakHours;
      } else {
        _failure = failure;
      }
    });
  }

  /// A changed day start or closing time whose closing for today has already
  /// passed stops same-day sales at once (the reason ADR-0038 was found):
  /// asks first. On the PC's clock, whose zone is the venue's.
  Future<bool> _confirmTimes(AdminSettings edited) async {
    final timesChanged =
        edited.dayStartSeconds != _loaded.dayStartSeconds ||
        edited.closingSeconds != _loaded.closingSeconds;
    if (!timesChanged) return true;
    final now = context.read<Clock>().now();
    if (now.isBefore(edited.venueDay.closingFor(now))) return true;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('settings-closed-now'),
        title: Text(l10n.settingsClosedNowTitle),
        content: Text(
          l10n.settingsClosedNowBody(
            peakTimeText(edited.closingSeconds),
            peakTimeText(edited.dayStartSeconds),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.back)),
          FilledButton(
            key: const ValueKey('settings-closed-now-save'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsClosedNowSave),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// The time dialog for [key] (`venue_day_starts_at` or `closing_time`).
  Future<void> _pickTime(String key) async {
    final l10n = AppLocalizations.of(context);
    final start = key == 'venue_day_starts_at';
    final picked = await showPeakTimeDialog(
      context,
      title: settingLabel(l10n, key),
      initialSeconds: start ? _dayStartSeconds : _closingSeconds,
    );
    if (picked != null && mounted) {
      setState(() {
        if (start) {
          _dayStartSeconds = picked;
        } else {
          _closingSeconds = picked;
        }
        _refusedField = null;
        _failure = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final saving = context.select((SettingsCubit c) => c.state.saving);
    final parsed = _parse();
    final edited = parsed.edited;
    final changes = edited == null ? const <String, Object>{} : settingsChanges(_loaded, edited);
    final touched = _touched;

    String? error(String key) => switch (parsed.errors[key]) {
      final e? => settingErrorText(l10n, key, e),
      null => null,
    };

    InputDecoration decoration({String? error, String? hint}) => InputDecoration(
      isDense: true,
      errorText: error,
      errorMaxLines: 2,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: BorderSide(color: tokens.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: BorderSide(color: tokens.inputBorder),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

    Widget field(String label, Widget input) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        input,
      ],
    );

    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );

    Widget number(String key) {
      final max = settingRanges[key]!.max;
      return field(
        settingLabel(l10n, key),
        TextField(
          key: ValueKey('setting-$key'),
          controller: _texts[key],
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter('$max'.length),
          ],
          decoration: decoration(error: error(key)),
        ),
      );
    }

    Widget amounts(String key, {String? note}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        field(
          settingLabel(l10n, key),
          TextField(
            key: ValueKey('setting-$key'),
            controller: _texts[key],
            textDirection: TextDirection.ltr,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,، ]')),
              LengthLimitingTextInputFormatter(120),
            ],
            decoration: decoration(error: error(key), hint: '5, 10, 20'),
          ),
        ),
        if (note != null) _Hint(note),
      ],
    );

    Widget toggle(String key, String help) => _SwitchRow(
      key: ValueKey('setting-$key'),
      label: settingLabel(l10n, key),
      help: help,
      value: _switches[key]!,
      onChanged: (value) => setState(() {
        _switches[key] = value;
        _refusedField = null;
        _failure = null;
      }),
    );

    // A time of day, picked with the time dialog (15-minute steps), with its
    // error under it.
    Widget timeButton(String key, int seconds) => OutlinedButton(
      key: ValueKey('setting-$key'),
      onPressed: () => _pickTime(key),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.inputHeight + 2),
        alignment: AlignmentDirectional.centerStart,
        side: BorderSide(
          color: parsed.errors.containsKey(key) ? tokens.dangerAction : tokens.inputBorder,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.inputRadius)),
      ),
      child: Text(
        peakTimeText(seconds),
        textDirection: TextDirection.ltr,
        style: TextStyle(fontSize: 15, color: tokens.text),
      ),
    );
    Widget time(String key, int seconds) => field(
      settingLabel(l10n, key),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          timeButton(key, seconds),
          if (error(key) case final text?)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                key: ValueKey('setting-$key-error'),
                style: TextStyle(fontSize: 12, color: tokens.dangerText),
              ),
            ),
        ],
      ),
    );
    final closesNextDate = _closingSeconds <= _dayStartSeconds;

    final venue = _Section(
      title: l10n.settingsVenueSection,
      children: [
        field(
          settingLabel(l10n, 'venue_name'),
          TextField(
            key: const ValueKey('setting-venue_name'),
            controller: _texts['venue_name'],
            inputFormatters: [LengthLimitingTextInputFormatter(maxVenueName)],
            decoration: decoration(error: error('venue_name')),
          ),
        ),
        pair(time('venue_day_starts_at', _dayStartSeconds), time('closing_time', _closingSeconds)),
        _Hint(
          key: const ValueKey('settings-closing-hint'),
          closesNextDate
              ? l10n.settingsClosingNextDay(peakTimeText(_closingSeconds))
              : l10n.settingsClosingNote,
        ),
        _Hint(l10n.settingsDayStartNote),
        pair(
          field(
            settingLabel(l10n, 'default_language'),
            DropdownButtonFormField<String>(
              key: const ValueKey('setting-default_language'),
              initialValue: _language,
              isExpanded: true,
              decoration: decoration(error: error('default_language')),
              items: [
                for (final lang in const ['ar', 'en'])
                  DropdownMenuItem(value: lang, child: Text(languageName(l10n, lang))),
              ],
              onChanged: (value) => setState(() {
                _language = value ?? _language;
                _refusedField = null;
                _failure = null;
              }),
            ),
          ),
          const SizedBox.shrink(),
        ),
        _ReadOnlyRow(
          key: const ValueKey('settings-timezone'),
          label: l10n.settingsTimezone,
          value: widget.overview.timezone,
          help: l10n.settingsTimezoneNote,
        ),
      ],
    );

    final tickets = _Section(
      title: l10n.settingsTicketsSection,
      children: [
        pair(number('gate_code_length'), number('unpaid_order_timeout_min')),
        _Note(l10n.settingsWiegandNote, bg: tokens.primaryTint, fg: tokens.onPrimaryTint),
        _LinkRow(
          key: const ValueKey('settings-validity-link'),
          text: l10n.settingsValidityNote,
          action: l10n.navTicketTypes,
          onTap: () => context.go(AppRoutes.adminTicketTypes),
        ),
      ],
    );

    final actions = _Section(
      title: l10n.settingsActionsSection,
      children: [
        pair(number('reactivation_window_min'), number('reactivation_max')),
        pair(number('flag_actions_per_shift'), number('flag_prints_per_ticket')),
        toggle('refund_before_scan_only', l10n.settingsRefundBeforeScanHelp),
        toggle('refund_same_shift_only', l10n.settingsRefundSameShiftHelp),
        toggle('flag_other_reason', l10n.settingsFlagOtherHelp),
      ],
    );

    final tips = _Section(
      title: l10n.settingsTipsSection,
      children: [
        toggle('tips_enabled', l10n.settingsTipsEnabledHelp),
        amounts('tip_quick_amounts_piastres', note: l10n.settingsTipQuickNote),
        amounts('opening_float_quick_amounts_piastres', note: l10n.settingsFloatQuickNote),
        amounts('received_quick_amounts_piastres', note: l10n.settingsReceivedQuickNote),
        amounts('cash_denominations_piastres', note: l10n.settingsDenominationsNote),
      ],
    );

    final offline = _Section(
      title: l10n.settingsOfflineSection,
      children: [
        pair(number('offline_pool_size'), number('offline_health_check_seconds')),
        _Hint(l10n.settingsOfflineNote),
        pair(number('gate_offline_after_seconds'), number('test_open_timeout_seconds')),
        _Hint(l10n.settingsGateTimingNote),
      ],
    );

    final left = [venue, actions, _PeakCard(overview: widget.overview), const _BackupCard()];
    final right = [tickets, tips, offline, _CountersCard(overview: widget.overview)];

    final banner = _failure == null ? null : settingsFailureMessage(l10n, _failure!.kind);
    final now = context.read<Clock>().now();
    final lastChange = widget.overview.updatedByName == null
        ? null
        : l10n.settingsLastChange(
            widget.overview.updatedByName!,
            dayTime(l10n, widget.overview.updatedAt, now),
          );

    Widget column(List<Widget> cards) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(height: 18), cards[i]],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              key: const ValueKey('settings-scroll'),
              padding: const EdgeInsets.only(bottom: 18),
              child: constraints.maxWidth < 900
                  ? column([...left, ...right])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: column(left)),
                        const SizedBox(width: 18),
                        Expanded(child: column(right)),
                      ],
                    ),
            ),
          ),
        ),
        Container(
          key: const ValueKey('settings-bar'),
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  banner ??
                      (touched ? l10n.settingsUnsaved : lastChange ?? l10n.settingsNoChangeYet),
                  key: const ValueKey('settings-bar-note'),
                  style: TextStyle(
                    fontSize: 13,
                    color: banner != null ? tokens.dangerText : tokens.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  key: const ValueKey('settings-undo'),
                  onPressed: touched && !saving ? () => setState(_fill) : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: tokens.inputBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                    ),
                  ),
                  child: Text(
                    l10n.settingsUndo,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: FilledButton(
                  key: const ValueKey('settings-save'),
                  onPressed: edited != null && changes.isNotEmpty && !saving
                      ? () => _save(edited)
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                    ),
                  ),
                  child: saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n.settingsSave,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          for (final child in children) ...[const SizedBox(height: 14), child],
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(text, style: TextStyle(fontSize: 12, color: context.tokens.textSecondary)),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text, {required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSizes.inputRadius)),
    child: Text(text, style: TextStyle(fontSize: 13, color: fg)),
  );
}

/// The design's switch rows: a label, a help line, the switch.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    super.key,
    required this.label,
    required this.help,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String help;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.inset,
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(help, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({super.key, required this.label, required this.value, required this.help});

  final String label;
  final String value;
  final String help;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.inset,
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(help, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

/// A line that points to the page where something is set.
class _LinkRow extends StatelessWidget {
  const _LinkRow({super.key, required this.text, required this.action, required this.onTap});

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: tokens.inset,
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(minimumSize: const Size(0, AppSizes.touchTarget)),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

/// The peak schedule, read only: it is set on the Ticket types page and
/// switched for the day on the dashboard (4.5, ADR-0033).
class _PeakCard extends StatelessWidget {
  const _PeakCard({required this.overview});

  final SettingsOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final days = [
      for (final d in peakWeekOrder)
        if (overview.peakWeekdays.contains(d)) weekdayName(language, d),
    ];
    final from = overview.peakFromSeconds;
    final to = overview.peakToSeconds;
    return _Section(
      title: l10n.settingsPeakSection,
      children: [
        Column(
          key: const ValueKey('settings-peak'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              days.isEmpty ? l10n.settingsPeakNoDays : l10n.settingsPeakDays(days.join('، ')),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              from == null || to == null
                  ? l10n.peakNoHours
                  : l10n.settingsPeakHours(peakTimeText(from), peakTimeText(to)),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        _LinkRow(
          key: const ValueKey('settings-peak-link'),
          text: l10n.settingsPeakNote,
          action: l10n.navTicketTypes,
          onTap: () => context.go(AppRoutes.adminTicketTypes),
        ),
      ],
    );
  }
}

/// Backups come with the server install (6.2); until then the card says so.
class _BackupCard extends StatelessWidget {
  const _BackupCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return _Section(
      title: l10n.settingsBackupSection,
      children: [_Note(l10n.settingsBackupNotYet, bg: tokens.warningBg, fg: tokens.warningText)],
    );
  }
}

class _CountersCard extends StatelessWidget {
  const _CountersCard({required this.overview});

  final SettingsOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<SettingsCubit>();

    Future<void> edit(AdminCounter? counter) =>
        showCounterDialog(context, cubit: cubit, entryGates: overview.entryGates, counter: counter);

    return Container(
      key: const ValueKey('settings-counters'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.settingsCountersSection,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('settings-add-counter'),
                onPressed: () => edit(null),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.counterNew),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (overview.counters.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.settingsCountersEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
          for (final c in overview.counters) ...[
            _CounterRow(counter: c, onTap: () => edit(c)),
            const SizedBox(height: 8),
          ],
          Text(
            l10n.settingsCountersNote,
            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({required this.counter, required this.onTap});

  final AdminCounter counter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final (label, bg, fg) = switch (counter) {
      AdminCounter(active: false) => (l10n.counterOff, tokens.bg, tokens.textMuted),
      AdminCounter(hasOpenShift: true) => (
        l10n.counterOpenShift,
        tokens.primaryTint,
        tokens.onPrimaryTint,
      ),
      AdminCounter(entryGateId: null) => (
        l10n.counterNoHomeGate,
        tokens.dangerBg,
        tokens.dangerText,
      ),
      _ => (l10n.counterOn, tokens.successBg, tokens.successText),
    };
    // An IP reads left to right in both languages.
    final printer = counter.printerIp == null
        ? l10n.counterNoPrinter
        : '\u2066${counter.printerIp}:${counter.printerPort}\u2069';

    return Material(
      color: tokens.inset,
      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      child: InkWell(
        key: ValueKey('counter-${counter.id}'),
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      counter.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      [
                        printer,
                        l10n.counterPaperMm(counter.paperWidthMm),
                        l10n.counterHomeGateIs(counter.entryGateName ?? l10n.counterNoHomeGate),
                      ].join(' · '),
                      style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
                ),
              ),
              IconButton(
                key: ValueKey('counter-copy-${counter.id}'),
                tooltip: l10n.counterCopyId,
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  await Clipboard.setData(ClipboardData(text: counter.id));
                  messenger?.showSnackBar(SnackBar(content: Text(l10n.counterIdCopied)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
