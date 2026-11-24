import 'package:equatable/equatable.dart';

/// The Shifts page's periods (`shifts_overview`'s `p_period`). The server
/// works out the venue-day bounds; the app can't convert a zone name.
enum ShiftsPeriod {
  today('today'),
  yesterday('yesterday'),
  week('week'),

  /// Every closed shift not approved yet, whatever its date.
  pending('pending');

  const ShiftsPeriod(this.key);

  final String key;
}

enum ShiftStatus {
  open,
  closed,
  approved;

  static ShiftStatus fromKey(String key) => switch (key) {
    'open' => open,
    'closed' => closed,
    'approved' => approved,
    _ => throw FormatException('unknown shift status: $key'),
  };
}

/// One `shift_reconciliation` row: expected cash and its inputs, counted cash
/// and the difference (ADR-0008). Supervisors and admins only.
class ShiftRow extends Equatable {
  const ShiftRow({
    required this.id,
    required this.number,
    required this.status,
    required this.cashierId,
    required this.cashierName,
    required this.counterName,
    required this.openedAt,
    required this.closedAt,
    required this.openingCashPiastres,
    required this.cashSalesPiastres,
    required this.cardSalesPiastres,
    required this.walletSalesPiastres,
    required this.paidOrders,
    required this.offlineOrders,
    required this.unsyncedEntries,
    required this.refusedOfflineOrders,
    required this.tipsPiastres,
    required this.tipCount,
    required this.cashRefundsPiastres,
    required this.expectedCashPiastres,
    required this.countedCashPiastres,
    required this.differencePiastres,
    required this.actionCount,
    required this.flaggedActionCount,
    required this.approvedByName,
    required this.approvedAt,
    required this.approvalComment,
  });

  factory ShiftRow.fromJson(Map<String, dynamic> json) => ShiftRow(
    id: json['shift_id'] as String,
    number: json['shift_number'] as int,
    status: ShiftStatus.fromKey(json['status'] as String),
    cashierId: json['cashier_id'] as String,
    cashierName: json['cashier_name'] as String,
    counterName: json['counter_name'] as String,
    openedAt: DateTime.parse(json['opened_at'] as String),
    closedAt: _time(json['closed_at']),
    openingCashPiastres: json['opening_cash_piastres'] as int,
    cashSalesPiastres: json['cash_sales_piastres'] as int,
    cardSalesPiastres: json['card_sales_piastres'] as int,
    walletSalesPiastres: json['wallet_sales_piastres'] as int,
    paidOrders: json['paid_orders'] as int,
    offlineOrders: json['offline_orders'] as int,
    unsyncedEntries: json['unsynced_entries'] as int,
    refusedOfflineOrders: json['refused_offline_orders'] as int,
    tipsPiastres: json['tips_piastres'] as int,
    tipCount: json['tip_count'] as int,
    cashRefundsPiastres: json['cash_refunds_piastres'] as int,
    expectedCashPiastres: json['expected_cash_piastres'] as int,
    countedCashPiastres: json['counted_cash_piastres'] as int?,
    differencePiastres: json['difference_piastres'] as int?,
    actionCount: json['action_count'] as int,
    flaggedActionCount: json['flagged_action_count'] as int,
    approvedByName: json['approved_by_name'] as String?,
    approvedAt: _time(json['approved_at']),
    approvalComment: json['approval_comment'] as String?,
  );

  final String id;
  final int number;
  final ShiftStatus status;
  final String cashierId;
  final String cashierName;
  final String counterName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int openingCashPiastres;
  final int cashSalesPiastres;
  final int cardSalesPiastres;
  final int walletSalesPiastres;

  /// Paid orders of every method.
  final int paidOrders;
  final int offlineOrders;

  /// Pool codes of this counter that entered during the shift with no sale
  /// uploaded yet (ADR-0015).
  final int unsyncedEntries;

  /// Offline orders that never reached the server: their cash is in the
  /// drawer but not in the figures (ADR-0026).
  final int refusedOfflineOrders;
  final int tipsPiastres;
  final int tipCount;
  final int cashRefundsPiastres;
  final int expectedCashPiastres;

  /// Null while the shift is open.
  final int? countedCashPiastres;

  /// Counted − expected; null while the shift is open.
  final int? differencePiastres;
  final int actionCount;
  final int flaggedActionCount;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? approvalComment;

  bool get isOpen => status == ShiftStatus.open;
  bool get needsApproval => status == ShiftStatus.closed;

  @override
  List<Object?> get props => [
    id, number, status, cashierId, cashierName, counterName, openedAt, closedAt,
    openingCashPiastres, cashSalesPiastres, cardSalesPiastres, walletSalesPiastres, paidOrders,
    offlineOrders, unsyncedEntries, refusedOfflineOrders, tipsPiastres, tipCount,
    cashRefundsPiastres, expectedCashPiastres, countedCashPiastres, differencePiastres,
    actionCount, flaggedActionCount, approvedByName, approvedAt, approvalComment,
  ];
}

/// A pool code that entered while its counter had no open shift, so no shift
/// row counts it. No gate code is sent.
class OrphanEntry extends Equatable {
  const OrphanEntry({
    required this.poolCodeId,
    required this.counterName,
    required this.gateName,
    required this.scannedAt,
  });

  factory OrphanEntry.fromJson(Map<String, dynamic> json) => OrphanEntry(
    poolCodeId: json['pool_code_id'] as String,
    counterName: json['counter_name'] as String,
    gateName: json['gate_name'] as String,
    scannedAt: DateTime.parse(json['scanned_at'] as String),
  );

  final String poolCodeId;
  final String counterName;
  final String gateName;
  final DateTime scannedAt;

  @override
  List<Object?> get props => [poolCodeId, counterName, gateName, scannedAt];
}

/// `shifts_overview`'s answer.
class ShiftsOverview extends Equatable {
  const ShiftsOverview({
    required this.now,
    required this.day,
    required this.period,
    required this.pendingCount,
    required this.shifts,
    required this.orphanEntries,
  });

  factory ShiftsOverview.fromJson(Map<String, dynamic> json) => ShiftsOverview(
    now: DateTime.parse(json['now'] as String),
    day: DateTime.parse(json['day'] as String),
    period: ShiftsPeriod.values.firstWhere(
      (p) => p.key == json['period'],
      orElse: () => throw FormatException('unknown period: ${json['period']}'),
    ),
    pendingCount: json['pending_count'] as int,
    shifts: [
      for (final row in json['shifts'] as List) ShiftRow.fromJson(row as Map<String, dynamic>),
    ],
    orphanEntries: [
      for (final row in json['orphan_entries'] as List)
        OrphanEntry.fromJson(row as Map<String, dynamic>),
    ],
  );

  final DateTime now;

  /// The venue's day today (date only).
  final DateTime day;
  final ShiftsPeriod period;

  /// Closed shifts not approved yet, in any period.
  final int pendingCount;
  final List<ShiftRow> shifts;
  final List<OrphanEntry> orphanEntries;

  @override
  List<Object?> get props => [now, day, period, pendingCount, shifts, orphanEntries];
}

enum RefusalKind { order, action }

/// A ticket type in a refused order, with its names when the server knows it.
class RefusedTypeCount extends Equatable {
  const RefusedTypeCount({required this.nameAr, required this.nameEn, required this.count});

  factory RefusedTypeCount.fromJson(Map<String, dynamic> json) => RefusedTypeCount(
    nameAr: json['name_ar'] as String?,
    nameEn: json['name_en'] as String?,
    count: json['count'] as int,
  );

  final String? nameAr;
  final String? nameEn;
  final int count;

  @override
  List<Object?> get props => [nameAr, nameEn, count];
}

/// What the counter sent, as `shift_offline_refusals` rebuilds it from known
/// keys only. Any field can be missing or of another type: a refused upload
/// may be malformed, so nothing here throws.
class RefusalSent extends Equatable {
  const RefusalSent({
    this.soldAt,
    this.paymentMethod,
    this.amountReceivedPiastres,
    this.tipPiastres,
    this.ticketCount,
    this.ticketsByType = const [],
    this.action,
    this.at,
    this.reason,
    this.reasonText,
  });

  factory RefusalSent.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RefusalSent();
    T? as<T>(Object? v) => v is T ? v : null;
    DateTime? time(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return RefusalSent(
      soldAt: time(json['sold_at']),
      paymentMethod: as<String>(json['payment_method']),
      amountReceivedPiastres: as<int>(json['amount_received_piastres']),
      tipPiastres: as<int>(json['tip_piastres']),
      ticketCount: as<int>(json['ticket_count']),
      ticketsByType: [
        for (final t in as<List>(json['tickets_by_type']) ?? const [])
          if (t is Map<String, dynamic>) RefusedTypeCount.fromJson(t),
      ],
      action: as<String>(json['action']),
      at: time(json['at']),
      reason: as<String>(json['reason']),
      reasonText: as<String>(json['reason_text']),
    );
  }

  // An order.
  final DateTime? soldAt;
  final String? paymentMethod;
  final int? amountReceivedPiastres;
  final int? tipPiastres;
  final int? ticketCount;
  final List<RefusedTypeCount> ticketsByType;

  // An action.
  final String? action;
  final DateTime? at;
  final String? reason;
  final String? reasonText;

  @override
  List<Object?> get props => [
    soldAt, paymentMethod, amountReceivedPiastres, tipPiastres, ticketCount, ticketsByType,
    action, at, reason, reasonText,
  ];
}

/// An offline order or action the server refused at upload (ADR-0026).
class OfflineRefusal extends Equatable {
  const OfflineRefusal({
    required this.id,
    required this.kind,
    required this.error,
    required this.reportedAt,
    required this.acceptedAt,
    required this.resolvedAt,
    required this.resolvedByName,
    required this.resolutionComment,
    required this.sent,
  });

  factory OfflineRefusal.fromJson(Map<String, dynamic> json) => OfflineRefusal(
    id: json['id'] as String,
    kind: json['kind'] == 'order' ? RefusalKind.order : RefusalKind.action,
    error: json['error'] as String,
    reportedAt: DateTime.parse(json['reported_at'] as String),
    acceptedAt: _time(json['accepted_at']),
    resolvedAt: _time(json['resolved_at']),
    resolvedByName: json['resolved_by_name'] as String?,
    resolutionComment: json['resolution_comment'] as String?,
    sent: RefusalSent.fromJson(json['sent'] as Map<String, dynamic>?),
  );

  final String id;
  final RefusalKind kind;

  /// The server's error key (`code_not_in_pool`, …).
  final String error;
  final DateTime reportedAt;

  /// A later upload passed.
  final DateTime? acceptedAt;

  /// A supervisor cleared it.
  final DateTime? resolvedAt;
  final String? resolvedByName;
  final String? resolutionComment;
  final RefusalSent sent;

  /// Still blocks the shift's close.
  bool get isOpen => acceptedAt == null && resolvedAt == null;

  @override
  List<Object?> get props => [
    id, kind, error, reportedAt, acceptedAt, resolvedAt, resolvedByName, resolutionComment, sent,
  ];
}

DateTime? _time(Object? value) => value == null ? null : DateTime.parse(value as String);
