import 'package:flutter_test/flutter_test.dart';
import 'package:ticketing_demo/demo/backend.dart';
import 'package:ticketing_demo/features/actions_log/data/action_log_models.dart';
import 'package:ticketing_demo/features/actions_log/data/actions_log_repository.dart';
import 'package:ticketing_demo/features/auth/data/auth_repository.dart';
import 'package:ticketing_demo/features/dashboard/data/dashboard_repository.dart';
import 'package:ticketing_demo/features/gates/data/gates_repository.dart';
import 'package:ticketing_demo/features/offline/data/offline_repository.dart';
import 'package:ticketing_demo/features/reports/data/reports_repository.dart';
import 'package:ticketing_demo/features/reports/data/sales_report_models.dart';
import 'package:ticketing_demo/features/sell/data/sell_draft.dart';
import 'package:ticketing_demo/features/sell/data/sell_repository.dart';
import 'package:ticketing_demo/features/settings/data/settings_repository.dart';
import 'package:ticketing_demo/features/shift/data/shift_repository.dart';
import 'package:ticketing_demo/features/shifts/data/shift_models.dart';
import 'package:ticketing_demo/features/shifts/data/shifts_repository.dart';
import 'package:ticketing_demo/features/ticket_types/data/ticket_types_repository.dart';
import 'package:ticketing_demo/features/tickets/data/ticket_failure.dart';
import 'package:ticketing_demo/features/tickets/data/ticket_lookup.dart';
import 'package:ticketing_demo/features/tickets/data/ticket_repository.dart';
import 'package:ticketing_demo/features/users/data/users_repository.dart';

/// The in-memory backend answers the app's repositories with the JSON the
/// production database functions return. These run a visitor's flows through
/// the repositories, so every answer is also parsed by the app's own models.
void main() {
  final b = DemoBackend.instance;
  final auth = AuthRepository(b);
  final shift = ShiftRepository(b);
  final sell = SellRepository(b);
  final tickets = TicketRepository(b);

  setUp(() async {
    b.reset();
    await auth.signOut();
  });

  test('cashier: open shift, sell, pay, scan, reactivate, close', () async {
    await auth.signIn('mona', DemoBackend.password);
    expect((await auth.loadMe())!.fullName, 'Mona Adel');
    expect(await shift.myOpenShift(), isNull);
    final opened = await shift.openShift(demoCounterId, 100000);
    expect(opened.counterName, 'Counter 1');

    final types = await sell.ticketTypes();
    final adult = types.firstWhere((t) => t.nameEn == 'Adult');
    final order = await sell.sellTickets(SellDraft(lines: [OrderLine(adult, 2)], method: PaymentMethod.cash));
    expect(order.tickets, hasLength(2));
    expect(order.totalPiastres, 20000);

    // Unpaid tickets never open a gate.
    expect(b.scan(order.tickets.first.gateCode, 'gate-1').accepted, isFalse);
    final paid =
        await sell.confirmPayment(order.id, PaymentMethod.cash, amountReceivedPiastres: 50000, tipPiastres: 1000);
    expect(paid.changePiastres, 50000 - 20000 - 1000);

    final code = order.tickets.first.gateCode;
    expect(b.scan(code, 'gate-1').accepted, isTrue);
    expect(b.scan(code, 'gate-1').accepted, isFalse);

    var lookup = await tickets.lookup(code);
    expect(lookup.status, TicketStatus.used);
    expect(lookup.can(TicketAction.reactivate), isTrue);
    expect(lookup.can(TicketAction.voidRefund), isFalse);
    await tickets.reactivate(lookup.ticketId, ActionReason.gateDidNotOpen);
    lookup = await tickets.lookup(code);
    expect(lookup.status, TicketStatus.active);
    expect(lookup.can(TicketAction.reactivate), isFalse);

    final reprint = await tickets.reprint(lookup.ticketId, ActionReason.ticketLost);
    expect(reprint.printCount, 2);
    await expectLater(
      tickets.reprint(lookup.ticketId, ActionReason.other),
      throwsA(isA<TicketFailure>().having((f) => f.kind, 'kind', TicketFailureKind.reasonTextRequired)),
    );

    final refund = await tickets.voidRefund(order.tickets.last.id, ActionReason.customerChangedMind);
    expect(refund.amountPiastres, 10000);

    expect((await sell.myShiftCounts()).ticketsCount, 2);
    expect(await shift.myShiftTips(), hasLength(1));
    final receipt = await shift.closeShift({20000: 5}, venueName: 'Riverside Gardens');
    expect(receipt.countedCashPiastres, 100000);
    expect(receipt.reprints, 1);
  });

  test('supervisor: dashboard, shifts, actions log, report', () async {
    await auth.signIn('rania', DemoBackend.password);
    final dashboard = await DashboardRepository(b).load();
    expect(dashboard.gates, hasLength(4));
    expect(dashboard.gates.last.status.name, 'offline');

    final shifts = ShiftsRepository(b);
    final pending = await shifts.overview(ShiftsPeriod.pending);
    expect(pending.shifts, hasLength(1));
    final row = pending.shifts.single;
    expect(row.differencePiastres, -5000);
    await expectLater(shifts.approve(row.id, ''), throwsA(isA<ShiftsFailure>()));
    await shifts.approve(row.id, 'Counted again: one 50 EGP note missing.');
    expect(await shifts.pendingCount(), 0);

    final log = await ActionsLogRepository(b).load(period: ActionsPeriod.review);
    expect(log.rows.where((r) => r.flagged), isNotEmpty);

    final reports = ReportsRepository(b);
    for (final period in ReportPeriod.values.where((p) => p != ReportPeriod.range)) {
      final report = await reports.load(period: period);
      expect(report.totals.tickets, greaterThanOrEqualTo(0));
    }
    expect((await reports.load(period: ReportPeriod.week)).byCashier, isNotEmpty);
  });

  test('admin pages load and save', () async {
    await auth.signIn('tarek', DemoBackend.password);
    final types = TicketTypesRepository(b);
    expect(await types.list(), hasLength(7));
    await types.peakState();
    final gates = await GatesRepository(b).overview();
    expect(gates.gates, hasLength(5));
    final users = await UsersRepository(b).overview();
    expect(users.users, hasLength(6));
    final settings = SettingsRepository(b);
    final overview = await settings.overview();
    expect(overview.counters, hasLength(4));
    await settings.saveSettings({'flag_prints_per_ticket': 3});
  });

  test('offline: pool, outage, upload', () async {
    await auth.signIn('mona', DemoBackend.password);
    final opened = await shift.openShift(demoCounterId, 0);
    final offline = OfflineRepository(b);
    final pool = await offline.reserveOfflineCodes();
    expect(pool.codes, hasLength(40));
    b.outage.value = true;
    expect(await offline.ping(timeout: const Duration(seconds: 1)), isFalse);
    // An unsold pool code opens its home gate once during the outage, no other.
    final code = '${pool.codes.first.gateCode}';
    expect(b.scan(code, 'gate-2').accepted, isFalse);
    expect(b.scan(code, 'gate-1').accepted, isTrue);
    expect(b.scan(code, 'gate-1').accepted, isFalse);
    b.outage.value = false;
    final results = await offline.syncOfflineOrders(opened.id, [
      {
        'client_id': 'c-1',
        'sold_at': DateTime.now().toUtc().toIso8601String(),
        'payment_method': 'cash',
        'amount_received_piastres': 10000,
        'tip_piastres': 0,
        'tickets': [
          {'ticket_type_id': 'tt-adult', 'gate_code': pool.codes.first.gateCode},
        ],
      },
    ]);
    expect(results.single.outcome.name, 'synced');
    // Its one entry was already used at the gate before the upload.
    expect((await tickets.lookup(code)).status, TicketStatus.used);
  });
}
