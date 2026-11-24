import 'package:intl/intl.dart' show DateFormat;

import '../../../core/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../actions_log/data/action_log_models.dart' show SettingsChange;
import '../../gates/view/gates_messages.dart' show gateChangeText;
import '../../settings/view/settings_messages.dart' show settingsSubjectChangeText;
import '../../users/view/users_messages.dart' show userChangeText;
import '../data/admin_ticket_type.dart';
import '../../sell/data/peak_schedule.dart';
import '../data/peak_state.dart';
import '../data/ticket_types_repository.dart';

/// The Ticket types page's texts, shared with the actions log's change lines.

String typesFailureMessage(AppLocalizations l10n, TicketTypesFailureKind kind) => switch (kind) {
  TicketTypesFailureKind.notAllowed => l10n.typesNotAllowed,
  TicketTypesFailureKind.invalidName => l10n.typesInvalidName,
  TicketTypesFailureKind.invalidPrice => l10n.typesInvalidPrice,
  TicketTypesFailureKind.invalidEntries => l10n.typesInvalidEntries,
  TicketTypesFailureKind.invalidValidityHours => l10n.typesInvalidHours,
  TicketTypesFailureKind.nameArTaken || TicketTypesFailureKind.nameEnTaken => l10n.typesNameTaken,
  TicketTypesFailureKind.notFound => l10n.typesNotFound,
  TicketTypesFailureKind.invalidWeekdays => l10n.typesInvalidWeekdays,
  TicketTypesFailureKind.invalidPeakHours => l10n.peakInvalidHours,
  TicketTypesFailureKind.peakHoursAfterClosing => l10n.peakHoursAfterClosing,
  TicketTypesFailureKind.serverUnreachable => l10n.errorServerUnreachable,
  TicketTypesFailureKind.unexpected => l10n.typesUnexpected,
};

/// "مرة واحدة", "5 مرات".
String entriesText(AppLocalizations l10n, int entries) => l10n.typesEntries(entries);

/// "يوم البيع", "3 ساعات من البيع".
String validityText(AppLocalizations l10n, TicketValidity validity, int? hours) =>
    switch (validity) {
      TicketValidity.sameDay => l10n.typesValiditySameDay,
      TicketValidity.hoursFromSale => l10n.typesValidityHours(hours ?? 0),
    };

String salePeriodText(AppLocalizations l10n, SalePeriod period) => switch (period) {
  SalePeriod.always => l10n.typesSaleAlways,
  SalePeriod.offPeak => l10n.typesSaleOffPeak,
  SalePeriod.peak => l10n.typesSalePeak,
};

String activeText(AppLocalizations l10n, bool active) =>
    active ? l10n.typesStatusActive : l10n.typesStatusInactive;

/// The days in the order an Egyptian week is read: Saturday first.
const peakWeekOrder = [6, 7, 1, 2, 3, 4, 5];

/// An ISO weekday's name in [locale]: 2026-11-09 is a Monday.
String weekdayName(String locale, int isoDay) =>
    DateFormat.EEEE(locale).format(DateTime(2026, 11, 8 + isoDay));

/// "16:00" from seconds after midnight.
String peakTimeText(int seconds) =>
    '${(seconds ~/ 3600).toString().padLeft(2, '0')}:'
    '${(seconds % 3600 ~/ 60).toString().padLeft(2, '0')}';

String peakSourceText(AppLocalizations l10n, PeakSource source) => switch (source) {
  PeakSource.manualOn => l10n.peakSourceManualOn,
  PeakSource.manualOff => l10n.peakSourceManualOff,
  PeakSource.weekend => l10n.peakSourceWeekend,
  PeakSource.hours => l10n.peakSourceHours,
  PeakSource.none => l10n.peakSourceNone,
};

String peakModeText(AppLocalizations l10n, PeakMode mode) => switch (mode) {
  PeakMode.auto => l10n.peakModeAuto,
  PeakMode.on => l10n.peakModeOn,
  PeakMode.off => l10n.peakModeOff,
};

TicketValidity? _validityOf(Object? key) => switch (key) {
  'same_day' => TicketValidity.sameDay,
  'hours_from_sale' => TicketValidity.hoursFromSale,
  _ => null,
};

int? _intOf(Object? value) => value is num ? value.toInt() : null;

/// A settings_change row for the actions log: a title ("نوع التذكرة كبار" or
/// "نوع جديد: كبار") and one line per changed value ("السعر: من 100 ج.م لـ
/// 120 ج.م"). Null for a subject this app doesn't know.
({String title, List<String> lines})? settingsChangeText(
  AppLocalizations l10n,
  SettingsChange? change,
  String languageCode,
) {
  if (change == null) return null;
  if (change.subject == 'peak_times') return _peakTimesText(l10n, change, languageCode);
  if (change.subject == 'peak_override') return _peakOverrideText(l10n, change);
  if (change.subject == 'gate' || change.subject == 'controller') {
    return gateChangeText(l10n, change);
  }
  if (change.subject == 'staff') return userChangeText(l10n, change);
  if (change.subject == 'settings' || change.subject == 'counter') {
    return settingsSubjectChangeText(l10n, change);
  }
  if (change.subject != 'ticket_type') return null;
  final name =
      (languageCode == 'ar' ? change.nameAr ?? change.nameEn : change.nameEn ?? change.nameAr) ??
      '—';
  final c = change.changes;

  String text(Object? value) => value is String && value.isNotEmpty ? value : '—';
  String money(Object? value) => switch (_intOf(value)) {
    final piastres? => formatMoney(l10n, piastres),
    null => '—',
  };
  String entries(Object? value) => switch (_intOf(value)) {
    final n? => entriesText(l10n, n),
    null => '—',
  };
  String validity(Object? kind, Object? hours) => switch (_validityOf(kind)) {
    final k? => validityText(l10n, k, _intOf(hours)),
    null => '—',
  };
  String active(Object? value) => value is bool ? activeText(l10n, value) : '—';
  String period(Object? value) => value is String
      ? switch (value) {
          'always' || 'off_peak' || 'peak' => salePeriodText(l10n, SalePeriod.fromKey(value)),
          _ => '—',
        }
      : '—';

  final kind = c['validity_kind'];
  final hours = c['validity_hours'];

  if (change.created) {
    return (
      title: l10n.changeNewType(name),
      lines: [
        [
          money(c['price_piastres']?.to),
          entries(c['entries_allowed']?.to),
          validity(kind?.to, hours?.to),
          if (c['sale_period']?.to case final p? when p != 'always') period(p),
          if (c['active']?.to == false) activeText(l10n, false),
        ].join(' · '),
      ],
    );
  }

  return (
    title: l10n.changeTypeName(name),
    lines: [
      if (c['name_ar'] case final v?) l10n.changeField(l10n.typesNameAr, text(v.from), text(v.to)),
      if (c['name_en'] case final v?) l10n.changeField(l10n.typesNameEn, text(v.from), text(v.to)),
      if (c['price_piastres'] case final v?)
        l10n.changeField(l10n.typesColPrice, money(v.from), money(v.to)),
      if (c['entries_allowed'] case final v?)
        l10n.changeField(l10n.typesEntriesLabel, entries(v.from), entries(v.to)),
      // Only the hours changed: the kind is hours from sale on both sides
      // (same day stores no hours).
      if (kind != null || hours != null)
        l10n.changeField(
          l10n.typesValidityLabel,
          validity(kind != null ? kind.from : 'hours_from_sale', hours?.from),
          validity(kind != null ? kind.to : 'hours_from_sale', hours?.to),
        ),
      if (c['sale_period'] case final v?)
        l10n.changeField(l10n.typesSalePeriodLabel, period(v.from), period(v.to)),
      if (c['active'] case final v?)
        l10n.changeField(l10n.typesActiveLabel, active(v.from), active(v.to)),
    ],
  );
}

/// "السبت، الأحد" in the week's order, or "ولا يوم".
String _daysText(AppLocalizations l10n, Object? value, String languageCode) {
  if (value is! List) return '—';
  final days = {
    for (final d in value)
      if (d is num) d.toInt(),
  };
  if (days.isEmpty) return l10n.peakNoDays;
  return [
    for (final d in peakWeekOrder)
      if (days.contains(d)) weekdayName(languageCode, d),
  ].join('، ');
}

String _timeText(Object? value) {
  try {
    final seconds = PeakSchedule.parseTime(value);
    return seconds == null ? '—' : peakTimeText(seconds);
  } on FormatException {
    return '—';
  }
}

({String title, List<String> lines}) _peakTimesText(
  AppLocalizations l10n,
  SettingsChange change,
  String languageCode,
) {
  final c = change.changes;
  return (
    title: l10n.changePeakTimes,
    lines: [
      if (c['weekdays'] case final v?)
        l10n.changeField(
          l10n.peakWeekdaysLabel,
          _daysText(l10n, v.from, languageCode),
          _daysText(l10n, v.to, languageCode),
        ),
      if (c['from'] case final v?)
        l10n.changeField(l10n.peakFrom, _timeText(v.from), _timeText(v.to)),
      if (c['to'] case final v?) l10n.changeField(l10n.peakTo, _timeText(v.from), _timeText(v.to)),
    ],
  );
}

({String title, List<String> lines}) _peakOverrideText(
  AppLocalizations l10n,
  SettingsChange change,
) {
  String mode(Object? value) => value is String && PeakMode.values.any((m) => m.key == value)
      ? peakModeText(l10n, PeakMode.fromKey(value))
      : '—';
  final day = change.day;
  return (
    title: l10n.changePeakOverride(day == null ? '—' : DateFormat('dd/MM').format(day)),
    lines: [
      if (change.changes['mode'] case final v?)
        l10n.changeField(l10n.changePeakMode, mode(v.from), mode(v.to)),
    ],
  );
}
