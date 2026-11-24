import 'package:equatable/equatable.dart';

/// The report's periods (`sales_report`'s `p_period`). The server works out
/// the venue-day bounds; [range] sends its own venue dates.
enum ReportPeriod {
  today('today'),
  yesterday('yesterday'),
  week('week'),
  month('month'),
  lastMonth('last_month'),
  range('range');

  const ReportPeriod(this.key);

  final String key;
}

/// What the table groups by. Every grouping comes in one answer, so switching
/// it never calls the server.
enum ReportGroup {
  type('type'),
  cashier('cashier'),
  gate('gate'),
  method('method'),
  day('day');

  const ReportGroup(this.key);

  final String key;
}

/// Sales (gross), refunds, tips and net of one row or of the whole period.
class ReportFigures extends Equatable {
  const ReportFigures({
    required this.tickets,
    required this.salesPiastres,
    required this.refundCount,
    required this.refundPiastres,
    required this.netPiastres,
    this.tipsPiastres,
  });

  factory ReportFigures.fromJson(Map<String, dynamic> json) => ReportFigures(
    tickets: json['tickets'] as int,
    salesPiastres: json['sales_piastres'] as int,
    refundCount: json['refund_count'] as int,
    refundPiastres: json['refund_piastres'] as int,
    tipsPiastres: json['tips_piastres'] as int?,
    netPiastres: json['net_piastres'] as int,
  );

  /// Tickets sold (refunded ones included).
  final int tickets;
  final int salesPiastres;
  final int refundCount;
  final int refundPiastres;

  /// Tips recorded in the period. Null on a ticket type's row: a tip belongs
  /// to an order or a shift, never to a type.
  final int? tipsPiastres;

  /// Sales − refunds + tips; negative on a day with refunds only.
  final int netPiastres;

  @override
  List<Object?> get props => [
    tickets,
    salesPiastres,
    refundCount,
    refundPiastres,
    tipsPiastres,
    netPiastres,
  ];
}

/// A counter a cashier sold at, with the home gate printed on those tickets
/// (null on a ticket from before counters had one).
class ReportCounter extends Equatable {
  const ReportCounter({required this.name, this.gate});

  factory ReportCounter.fromJson(Map<String, dynamic> json) =>
      ReportCounter(name: json['name'] as String, gate: json['gate'] as String?);

  final String name;
  final String? gate;

  @override
  List<Object?> get props => [name, gate];
}

/// One row of a grouping. Which fields are set depends on the grouping: a
/// type has its two names and sort order, a cashier a name, its counters and
/// its tickets by type, a gate the same (its name is null for tickets with no
/// gate, and its counters carry no gate), a method its key, a day a date.
class ReportRow extends Equatable {
  const ReportRow({
    required this.figures,
    this.id,
    this.nameAr,
    this.nameEn,
    this.sortOrder,
    this.name,
    this.typeTickets = const {},
    this.counters = const [],
    this.method,
    this.date,
  });

  factory ReportRow.fromJson(Map<String, dynamic> json) => ReportRow(
    figures: ReportFigures.fromJson(json),
    id: json['id'] as String?,
    nameAr: json['name_ar'] as String?,
    nameEn: json['name_en'] as String?,
    sortOrder: json['sort_order'] as int?,
    name: json['name'] as String?,
    typeTickets: {
      for (final t in json['types'] as List<dynamic>? ?? const [])
        (t as Map<String, dynamic>)['id'] as String: t['tickets'] as int,
    },
    counters: [
      for (final c in json['counters'] as List<dynamic>? ?? const [])
        ReportCounter.fromJson(c as Map<String, dynamic>),
    ],
    method: json['method'] as String?,
    date: switch (json['date']) {
      final String d => DateTime.parse(d),
      _ => null,
    },
  );

  final ReportFigures figures;
  final String? id;
  final String? nameAr;
  final String? nameEn;

  /// A type's place on the sell screen (ADR-0034), for the cashier view's columns.
  final int? sortOrder;
  final String? name;

  /// A cashier's or a gate's tickets by type id: only the types sold, gross (a refunded
  /// ticket still counts), adding up to [ReportFigures.tickets].
  final Map<String, int> typeTickets;

  /// A cashier's counters in the period, by name: only where it sold, so
  /// empty for a cashier with only a refund or a tip. A gate's: the counters
  /// that sold tickets for it.
  final List<ReportCounter> counters;

  /// `payment_method`; a value added later shows as its key.
  final String? method;

  /// The venue date (date only).
  final DateTime? date;

  @override
  List<Object?> get props => [
    figures,
    id,
    nameAr,
    nameEn,
    sortOrder,
    name,
    typeTickets,
    counters,
    method,
    date,
  ];
}

/// `sales_report`'s answer.
class SalesReport extends Equatable {
  const SalesReport({
    required this.now,
    required this.day,
    required this.period,
    required this.from,
    required this.to,
    required this.totals,
    required this.byType,
    required this.byCashier,
    required this.byGate,
    required this.byMethod,
    required this.byDay,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    List<ReportRow> rows(String key) => [
      for (final r in json[key] as List<dynamic>) ReportRow.fromJson(r as Map<String, dynamic>),
    ];
    return SalesReport(
      now: DateTime.parse(json['now'] as String),
      day: DateTime.parse(json['day'] as String),
      period: json['period'] as String,
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      totals: ReportFigures.fromJson(json['totals'] as Map<String, dynamic>),
      byType: rows('by_type'),
      byCashier: rows('by_cashier'),
      byGate: rows('by_gate'),
      byMethod: rows('by_method'),
      byDay: rows('by_day'),
    );
  }

  final DateTime now;

  /// The venue's day (date only).
  final DateTime day;
  final String period;

  /// The period's first and last venue dates, both included.
  final DateTime from;
  final DateTime to;
  final ReportFigures totals;

  /// By net, highest first.
  final List<ReportRow> byType;
  final List<ReportRow> byCashier;

  /// By the gate printed on the tickets (4.4b): refunds on their ticket's
  /// gate, tips on their order's or shift's.
  final List<ReportRow> byGate;
  final List<ReportRow> byMethod;

  /// Days with a sale or a refund, newest first.
  final List<ReportRow> byDay;

  /// The cashier and gate views' type columns: the types sold in the period, in the
  /// sell screen's order. Each one's tickets is its total.
  List<ReportRow> get typeColumns => [...byType]
    ..sort(
      (a, b) => switch ((a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0)) {
        0 => (a.nameEn ?? '').compareTo(b.nameEn ?? ''),
        final c => c,
      },
    );

  List<ReportRow> rows(ReportGroup group) => switch (group) {
    ReportGroup.type => byType,
    ReportGroup.cashier => byCashier,
    ReportGroup.gate => byGate,
    ReportGroup.method => byMethod,
    ReportGroup.day => byDay,
  };

  @override
  List<Object?> get props => [
    now,
    day,
    period,
    from,
    to,
    totals,
    byType,
    byCashier,
    byGate,
    byMethod,
    byDay,
  ];
}
