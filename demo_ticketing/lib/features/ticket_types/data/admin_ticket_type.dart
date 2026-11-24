import 'package:equatable/equatable.dart';

import '../../sell/data/ticket_type.dart';

export '../../sell/data/ticket_type.dart' show SalePeriod, TicketValidity;

/// A `ticket_types` row as the admin page shows it: every type, on sale or
/// not. The sell screen's `TicketType` stays separate, because its row
/// format is the offline copy.
class AdminTicketType extends Equatable {
  const AdminTicketType({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.pricePiastres,
    required this.entriesAllowed,
    required this.validity,
    this.validityHours,
    required this.active,
    required this.sortOrder,
    this.salePeriod = SalePeriod.always,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final int pricePiastres;
  final int entriesAllowed;
  final TicketValidity validity;

  /// Only for [TicketValidity.hoursFromSale].
  final int? validityHours;

  /// On sale: shown on the sell screen.
  final bool active;
  final int sortOrder;

  /// When it is on sale (peak times, ADR-0033).
  final SalePeriod salePeriod;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  TicketTypeDraft get draft => TicketTypeDraft(
    nameAr: nameAr,
    nameEn: nameEn,
    pricePiastres: pricePiastres,
    entriesAllowed: entriesAllowed,
    validity: validity,
    validityHours: validityHours,
    active: active,
    salePeriod: salePeriod,
  );

  /// A `ticket_types` row, or `save_ticket_type`'s answer.
  factory AdminTicketType.fromRow(Map<String, dynamic> row) => AdminTicketType(
    id: row['id'] as String,
    nameAr: row['name_ar'] as String,
    nameEn: row['name_en'] as String,
    pricePiastres: row['price_piastres'] as int,
    entriesAllowed: row['entries_allowed'] as int,
    validity: validityFromKey(row['validity_kind'] as String),
    validityHours: row['validity_hours'] as int?,
    active: row['active'] as bool,
    sortOrder: row['sort_order'] as int,
    salePeriod: SalePeriod.fromKey(row['sale_period'] as String?),
  );

  @override
  List<Object?> get props => [
    id,
    nameAr,
    nameEn,
    pricePiastres,
    entriesAllowed,
    validity,
    validityHours,
    active,
    sortOrder,
    salePeriod,
  ];
}

/// What the edit panel saves: `save_ticket_type`'s values.
class TicketTypeDraft extends Equatable {
  const TicketTypeDraft({
    required this.nameAr,
    required this.nameEn,
    required this.pricePiastres,
    required this.entriesAllowed,
    required this.validity,
    this.validityHours,
    required this.active,
    this.salePeriod = SalePeriod.always,
  });

  final String nameAr;
  final String nameEn;
  final int pricePiastres;
  final int entriesAllowed;
  final TicketValidity validity;

  /// Ignored by the server for [TicketValidity.sameDay].
  final int? validityHours;
  final bool active;
  final SalePeriod salePeriod;

  /// Equal to [other] as the server would store it: trimmed names, and no
  /// hours on a same-day type.
  bool sameAs(TicketTypeDraft other) =>
      nameAr.trim() == other.nameAr.trim() &&
      nameEn.trim() == other.nameEn.trim() &&
      pricePiastres == other.pricePiastres &&
      entriesAllowed == other.entriesAllowed &&
      validity == other.validity &&
      (validity == TicketValidity.sameDay || validityHours == other.validityHours) &&
      active == other.active &&
      salePeriod == other.salePeriod;

  @override
  List<Object?> get props => [
    nameAr,
    nameEn,
    pricePiastres,
    entriesAllowed,
    validity,
    validityHours,
    active,
    salePeriod,
  ];
}

String validityKey(TicketValidity validity) => switch (validity) {
  TicketValidity.sameDay => 'same_day',
  TicketValidity.hoursFromSale => 'hours_from_sale',
};

TicketValidity validityFromKey(String key) => switch (key) {
  'same_day' => TicketValidity.sameDay,
  'hours_from_sale' => TicketValidity.hoursFromSale,
  _ => throw FormatException('Unknown validity_kind: $key'),
};
