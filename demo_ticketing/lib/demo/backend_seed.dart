part of 'backend.dart';

/// The counter this demo "PC" is: what `COUNTER_ID` is in production.
const demoCounterId = 'counter-1';

/// The role buttons in the demo bar: label, username.
const demoAccounts = <(String, String)>[
  ('Cashier', 'mona'),
  ('Supervisor', 'rania'),
  ('Admin', 'tarek'),
];

/// Fictional venue, people and history. Times are relative to now, so the
/// live dashboard always has a morning of traffic to show.
void _seed(DemoBackend b) {
  final random = Random(7);
  final now = DateTime.now();
  b.settings = <String, Object?>{
    'venue_name': 'Riverside Gardens',
    // A venue day of 24 hours from midnight, so the demo sells at any hour
    // wherever it is opened. Production runs e.g. 08:00 to 02:00 (ADR-0038).
    'venue_day_starts_at': '00:00:00',
    'closing_time': '00:00:00',
    'default_language': 'en',
    'gate_code_length': 6,
    'unpaid_order_timeout_min': 10,
    'reactivation_window_min': 10,
    'reactivation_max': 1,
    'flag_actions_per_shift': 3,
    'flag_prints_per_ticket': 2,
    'offline_pool_size': 40,
    // Short in the demo, so the outage switch shows within seconds.
    'offline_health_check_seconds': 4,
    'gate_offline_after_seconds': 120,
    'test_open_timeout_seconds': 10,
    'refund_before_scan_only': true,
    'refund_same_shift_only': true,
    'flag_other_reason': true,
    'tips_enabled': true,
    'tip_quick_amounts_piastres': [500, 1000, 2000, 5000, 10000, 20000],
    'opening_float_quick_amounts_piastres': [50000, 100000, 200000],
    'received_quick_amounts_piastres': [5000, 10000, 20000, 50000, 100000, 200000],
    'cash_denominations_piastres': [20000, 10000, 5000, 2000, 1000, 500, 100, 50, 25],
    // Fridays and Saturdays all day, and 17:00 to 22:00 on other days.
    'peak_weekdays': [5, 6],
    'peak_from': '17:00:00',
    'peak_to': '22:00:00',
    'peak_override': null,
    'peak_override_day': null,
  };

  // ── People ──────────────────────────────────────────────────────────────────
  b.staff.addAll([
    DemoStaff('st-mona', 'Mona Adel', 'mona', 'cashier'),
    DemoStaff('st-sherif', 'Sherif Kamal', 'sherif', 'cashier'),
    DemoStaff('st-dina', 'Dina Samy', 'dina', 'cashier'),
    DemoStaff('st-hossam', 'Hossam Ali', 'hossam', 'cashier', active: false),
    DemoStaff('st-rania', 'Rania Fathy', 'rania', 'supervisor'),
    DemoStaff('st-tarek', 'Tarek Hosny', 'tarek', 'admin'),
  ]);

  // ── Hardware ──────────────────────────────────────────────────────────────────
  b.controllers.addAll([
    _Controller('ctl-a', 'Controller A', 'C3-400', '10.20.0.51'),
    _Controller('ctl-b', 'Controller B', 'C3-400', '10.20.0.52'),
  ]);
  final seen = now.subtract(const Duration(seconds: 5));
  b.gates.addAll([
    _Gate('gate-1', 'Gate 1', controllerId: 'ctl-a', doorNumber: 1)..lastSeenAt = seen,
    _Gate('gate-2', 'Gate 2', controllerId: 'ctl-a', doorNumber: 2)..lastSeenAt = seen,
    _Gate('gate-3', 'Gate 3', controllerId: 'ctl-b', doorNumber: 1)..lastSeenAt = seen,
    // Its gate service stopped answering twenty minutes ago.
    _Gate('gate-4', 'Gate 4', controllerId: 'ctl-b', doorNumber: 2)
      ..lastSeenAt = now.subtract(const Duration(minutes: 20)),
    _Gate('gate-x', 'Exit North', direction: 'exit', controllerId: 'ctl-b', doorNumber: 3),
  ]);
  b.counters.addAll([
    _Counter(demoCounterId, 'Counter 1', '10.20.0.21', 'gate-1'),
    _Counter('counter-2', 'Counter 2', '10.20.0.22', 'gate-2'),
    _Counter('counter-3', 'Counter 3', '10.20.0.23', 'gate-3'),
    _Counter('counter-4', 'Counter 4', '10.20.0.24', 'gate-4'),
  ]);

  // ── Ticket types ──────────────────────────────────────────────────────────────
  b.types.addAll([
    _Type('tt-adult', 'بالغ', 'Adult', 10000, 1),
    _Type('tt-child', 'طفل', 'Child', 6000, 2),
    _Type('tt-vip', 'كبار الزوار', 'VIP', 25000, 3),
    _Type('tt-day', 'تذكرة اليوم الكامل', 'Day pass (3 entries)', 15000, 4, entries: 3),
    _Type('tt-evening', 'تذكرة المساء', 'Evening pass (4 hours)', 8000, 5,
        validityKind: 'hours_from_sale', validityHours: 4),
    _Type('tt-garden-off', 'الحديقة – خارج الذروة', 'Garden pass (off-peak)', 2000, 6, salePeriod: 'off_peak'),
    _Type('tt-garden-peak', 'الحديقة – الذروة', 'Garden pass (peak)', 3000, 7, salePeriod: 'peak'),
  ]);

  // ── History ───────────────────────────────────────────────────────────────────
  final dayStart = b.venueDay.startOf(b.today);
  final weights = ['tt-adult', 'tt-adult', 'tt-adult', 'tt-child', 'tt-child', 'tt-vip', 'tt-day'];
  final methods = ['cash', 'cash', 'cash', 'card', 'wallet'];

  _Order sale(_Shift shift, DateTime at, {bool scan = true}) {
    final counter = b._counter(shift.counterId)!;
    final lines = [for (var i = 0; i < 1 + random.nextInt(3); i++) b._type(weights[random.nextInt(weights.length)])!];
    final total = lines.fold(0, (s, t) => s + t.price);
    final order = _Order(b._id('o'), ++b._orderNumber, shift.id, total, at)
      ..status = 'paid'
      ..method = methods[random.nextInt(methods.length)]
      ..paidAt = at.add(const Duration(seconds: 40));
    order.amountReceived = order.method == 'cash' ? ((total ~/ 5000) + 1) * 5000 : total;
    b.orders.add(order);
    for (final type in lines) {
      final t = _Ticket(b._id('t'), order.id, type.id, type.price, counter.entryGateId, b._newGateCode(), at,
          b._validUntil(type, at), type.entries)
        ..status = 'active';
      b.tickets.add(t);
      if (scan && random.nextDouble() < .85) {
        final scannedAt = at.add(Duration(minutes: 2 + random.nextInt(9)));
        if (scannedAt.isBefore(now)) {
          // Most visitors use the gate by their counter; some walk further.
          final gate = random.nextDouble() < .8 ? counter.entryGateId! : 'gate-${1 + random.nextInt(3)}';
          b.scans.add(_Scan(b._id('scan'), t.id, gate, 'accepted', null, scannedAt));
          t.entriesLeft--;
          if (t.entriesLeft == 0) t.status = 'used';
        }
      }
    }
    if (order.method == 'cash' && random.nextDouble() < .25) {
      b.tips.add(_Tip(b._id('tip'), shift.id, order.id, 1000, 'with_order', order.paidAt!));
    }
    return order;
  }

  // Yesterday: an approved shift, and an evening shift still waiting for a
  // supervisor, 50 EGP short in its blind count.
  final yesterday = dayStart.subtract(const Duration(days: 1));
  final approved = _Shift(b._id('s'), ++b._shiftNumber, 'st-dina', 'counter-3',
      yesterday.add(const Duration(hours: 9)), 100000)
    ..status = 'approved'
    ..closedAt = yesterday.add(const Duration(hours: 16))
    ..approvedBy = 'st-rania'
    ..approvedAt = yesterday.add(const Duration(hours: 16, minutes: 20))
    ..approvalComment = null;
  b.shifts.add(approved);
  for (var t = approved.openedAt.add(const Duration(minutes: 10));
      t.isBefore(approved.closedAt!);
      t = t.add(Duration(minutes: 9 + random.nextInt(8)))) {
    sale(approved, t, scan: false);
  }
  approved.countedCash = b._shiftRow(approved)['expected_cash_piastres'] as int;

  final pending = _Shift(b._id('s'), ++b._shiftNumber, 'st-sherif', 'counter-2',
      yesterday.add(const Duration(hours: 15)), 100000);
  b.shifts.add(pending);
  for (var t = pending.openedAt.add(const Duration(minutes: 5));
      t.isBefore(yesterday.add(const Duration(hours: 22, minutes: 50)));
      t = t.add(Duration(minutes: 8 + random.nextInt(8)))) {
    sale(pending, t, scan: false);
  }
  b._userId = 'st-sherif';
  final reprinted = b.tickets.lastWhere((t) => b._order(t.orderId)!.shiftId == pending.id);
  reprinted.printCount = 3;
  b._log('reprint',
      ticketId: reprinted.id,
      reason: 'other',
      reasonText: 'Customer spilled water on it',
      details: {'copy_number': 3},
      at: yesterday.add(const Duration(hours: 21, minutes: 12)),
      shiftId: pending.id);
  pending
    ..status = 'closed'
    ..closedAt = yesterday.add(const Duration(hours: 23));
  pending.countedCash = (b._shiftRow(pending)['expected_cash_piastres'] as int) - 5000;

  // Today: Dina has been selling at Counter 3 for a few hours.
  final windowStart = now.subtract(const Duration(hours: 5)).isAfter(dayStart)
      ? now.subtract(const Duration(hours: 5))
      : dayStart.add(const Duration(minutes: 1));
  final open = _Shift(b._id('s'), ++b._shiftNumber, 'st-dina', 'counter-3', windowStart, 100000);
  b.shifts.add(open);
  for (var t = windowStart.add(const Duration(minutes: 3));
      t.isBefore(now.subtract(const Duration(minutes: 2)));
      t = t.add(Duration(minutes: 4 + random.nextInt(6)))) {
    sale(open, t);
  }
  // A few refusals at the gates, as a real morning has.
  final someTicket = b.tickets.where((t) => t.status == 'used').lastOrNull;
  if (someTicket != null) {
    b.scans.add(_Scan(b._id('scan'), someTicket.id, 'gate-3', 'rejected', 'used_up',
        now.subtract(const Duration(minutes: 7))));
  }
  b.scans.add(_Scan(b._id('scan'), null, 'gate-2', 'rejected', 'not_found', now.subtract(const Duration(minutes: 31))));

  // Dina voided a ticket bought by mistake and reprinted one twice.
  b._userId = 'st-dina';
  final mine = b.tickets.where((t) => b._order(t.orderId)!.shiftId == open.id && t.status == 'active').toList();
  if (mine.length > 3) {
    mine[0].status = 'voided';
    b._log('void_refund',
        ticketId: mine[0].id,
        reason: 'wrong_ticket_type',
        amount: mine[0].price,
        at: now.subtract(const Duration(minutes: 50)),
        shiftId: open.id);
    for (var i = 0; i < 2; i++) {
      mine[1].printCount++;
      b._log('reprint',
          ticketId: mine[1].id,
          reason: 'print_failed',
          details: {'copy_number': mine[1].printCount},
          at: now.subtract(Duration(minutes: 40 - i * 10)),
          shiftId: open.id);
    }
  }
  b._userId = null;
}
