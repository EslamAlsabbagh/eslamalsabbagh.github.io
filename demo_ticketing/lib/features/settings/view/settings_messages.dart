import '../../../core/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../actions_log/data/action_log_models.dart' show SettingsChange;
import '../data/settings_models.dart';
import '../data/settings_repository.dart';

/// The Settings page's texts, shared with the actions log's change lines.

String settingsFailureMessage(AppLocalizations l10n, SettingsFailureKind kind) => switch (kind) {
  SettingsFailureKind.notAllowed => l10n.settingsNotAllowed,
  SettingsFailureKind.invalidSetting => l10n.settingsInvalidValue,
  SettingsFailureKind.invalidName => l10n.counterInvalidName,
  SettingsFailureKind.nameTaken => l10n.counterNameTaken,
  SettingsFailureKind.invalidIp => l10n.gatesInvalidIp,
  SettingsFailureKind.invalidPort => l10n.gatesInvalidPort,
  SettingsFailureKind.invalidPaperWidth => l10n.counterInvalidPaper,
  SettingsFailureKind.homeGateRequired => l10n.counterHomeGateRequired,
  SettingsFailureKind.homeGateNotEntry => l10n.counterHomeGateNotEntry,
  SettingsFailureKind.gateNotFound => l10n.counterGateNotFound,
  SettingsFailureKind.counterHasOpenShift => l10n.counterHasOpenShift,
  SettingsFailureKind.notFound => l10n.counterNotFound,
  SettingsFailureKind.peakHoursOutsideOpening => l10n.settingsStartCrossesPeak,
  SettingsFailureKind.serverUnreachable => l10n.errorServerUnreachable,
  SettingsFailureKind.unexpected => l10n.settingsUnexpected,
};

/// Under a setting's field.
String settingErrorText(AppLocalizations l10n, String key, SettingError error) => switch (error) {
  SettingError.required => l10n.settingsRequired,
  SettingError.outOfRange => switch (settingRanges[key]) {
    final range? => l10n.settingsOutOfRange(range.min, range.max),
    null => l10n.settingsInvalidValue,
  },
  SettingError.badList => l10n.settingsInvalidList,
  SettingError.tooMany => l10n.settingsTooManyAmounts(maxAmountsFor[key] ?? 0),
  SettingError.tooBig => l10n.settingsAmountTooBig,
  SettingError.duplicate => l10n.settingsDuplicateAmount,
  SettingError.empty => l10n.settingsNeedOneDenomination,
  SettingError.refused => l10n.settingsInvalidValue,
  SettingError.crossesPeakHours => l10n.settingsStartCrossesPeak,
  SettingError.cutsPeakHours => l10n.settingsClosingCutsPeak,
};

/// A setting's name, as its field and the actions log show it.
String settingLabel(AppLocalizations l10n, String key) => switch (key) {
  'venue_name' => l10n.settingsVenueName,
  'venue_day_starts_at' => l10n.settingsDayStart,
  'closing_time' => l10n.settingsClosingTime,
  'default_language' => l10n.settingsDefaultLanguage,
  'gate_code_length' => l10n.settingsGateCodeLength,
  'unpaid_order_timeout_min' => l10n.settingsUnpaidTimeout,
  'reactivation_window_min' => l10n.settingsReactivationWindow,
  'reactivation_max' => l10n.settingsReactivationMax,
  'refund_before_scan_only' => l10n.settingsRefundBeforeScan,
  'refund_same_shift_only' => l10n.settingsRefundSameShift,
  'flag_actions_per_shift' => l10n.settingsFlagActions,
  'flag_prints_per_ticket' => l10n.settingsFlagPrints,
  'flag_other_reason' => l10n.settingsFlagOther,
  'tips_enabled' => l10n.settingsTipsEnabled,
  'tip_quick_amounts_piastres' => l10n.settingsTipQuick,
  'opening_float_quick_amounts_piastres' => l10n.settingsFloatQuick,
  'received_quick_amounts_piastres' => l10n.settingsReceivedQuick,
  'cash_denominations_piastres' => l10n.settingsDenominations,
  'offline_pool_size' => l10n.settingsPoolSize,
  'offline_health_check_seconds' => l10n.settingsHealthCheck,
  'gate_offline_after_seconds' => l10n.settingsGateOffline,
  'test_open_timeout_seconds' => l10n.settingsTestOpenTimeout,
  _ => key,
};

String languageName(AppLocalizations l10n, Object? key) => switch (key) {
  'ar' => l10n.settingsLanguageAr,
  'en' => l10n.settingsLanguageEn,
  _ => '—',
};

int? _intOf(Object? value) => value is num ? value.toInt() : null;

/// A logged value as a reader of the log knows it.
String settingValueText(AppLocalizations l10n, String key, Object? value) {
  if (value == null) return '—';
  if (amountListSettings.contains(key)) {
    if (value is! List) return '—';
    final amounts = [for (final a in value) ?_intOf(a)];
    return amounts.isEmpty
        ? l10n.settingsNoAmounts
        : l10n.moneyAmount(amounts.map(piastresText).join('، '));
  }
  if (switchSettings.contains(key)) {
    return switch (value) {
      true => l10n.settingsOn,
      false => l10n.settingsOff,
      _ => '—',
    };
  }
  return switch (key) {
    'default_language' => languageName(l10n, value),
    'venue_day_starts_at' || 'closing_time' when value is String => () {
      try {
        final seconds = parseTimeOfDay(value);
        return timeOfDayText(seconds).substring(0, 5);
      } on FormatException {
        return '—';
      }
    }(),
    'venue_name' => value is String && value.isNotEmpty ? value : '—',
    _ => switch (_intOf(value)) {
      final n? => '$n',
      null => '—',
    },
  };
}

/// A settings or counter settings_change for the actions log, as
/// `settingsChangeText` gives a ticket type's. Null for another subject.
({String title, List<String> lines})? settingsSubjectChangeText(
  AppLocalizations l10n,
  SettingsChange change,
) {
  final c = change.changes;

  if (change.subject == 'settings') {
    return (
      title: l10n.changeSettings,
      lines: [
        for (final key in settingsOrder)
          if (c[key] case final v?)
            l10n.changeField(
              settingLabel(l10n, key),
              settingValueText(l10n, key, v.from),
              settingValueText(l10n, key, v.to),
            ),
      ],
    );
  }

  if (change.subject != 'counter') return null;
  final name = change.name ?? '—';
  String text(Object? value) => value is String && value.isNotEmpty ? value : '—';
  String ip(Object? value) => value is String && value.isNotEmpty ? '\u2066$value\u2069' : '—';
  String number(Object? value) => switch (_intOf(value)) {
    final n? => '$n',
    null => '—',
  };
  String paper(Object? value) => switch (_intOf(value)) {
    final n? => l10n.counterPaperMm(n),
    null => '—',
  };
  String gate(Object? value) =>
      value is String && value.isNotEmpty ? value : l10n.counterNoHomeGate;
  String active(Object? value) => switch (value) {
    true => l10n.counterOn,
    false => l10n.counterOff,
    _ => '—',
  };

  if (change.created) {
    return (
      title: l10n.changeNewCounter(name),
      lines: [
        [
          if (c['printer_ip']?.to case final String address when address.isNotEmpty)
            '\u2066$address:${number(c['printer_port']?.to)}\u2069'
          else
            l10n.counterNoPrinter,
          paper(c['paper_width_mm']?.to),
          l10n.counterHomeGateIs(gate(c['home_gate']?.to)),
          if (c['active']?.to == false) l10n.counterOff,
        ].join(' · '),
      ],
    );
  }
  return (
    title: l10n.changeCounterName(name),
    lines: [
      if (c['name'] case final v?) l10n.changeField(l10n.gatesName, text(v.from), text(v.to)),
      if (c['printer_ip'] case final v?)
        l10n.changeField(l10n.counterPrinterIp, ip(v.from), ip(v.to)),
      if (c['printer_port'] case final v?)
        l10n.changeField(l10n.counterPrinterPort, number(v.from), number(v.to)),
      if (c['paper_width_mm'] case final v?)
        l10n.changeField(l10n.counterPaperWidth, paper(v.from), paper(v.to)),
      if (c['home_gate'] case final v?)
        l10n.changeField(l10n.counterHomeGate, gate(v.from), gate(v.to)),
      if (c['active'] case final v?)
        l10n.changeField(l10n.counterActive, active(v.from), active(v.to)),
    ],
  );
}
