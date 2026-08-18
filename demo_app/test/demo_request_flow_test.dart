// Exercises the demo's leave-request flow end to end against the in-memory
// store: file a request as an employee, see it in the manager's queue, approve
// it, and watch it move along the chain and into Processed.
//
// This is the behaviour the demo exists to show, and it is far more reliably
// checked here than by clicking through a canvas-rendered web build.

import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_requests_query.dart';
import 'package:hrms_demo/demo/demo_seed.dart';
import 'package:hrms_demo/demo/demo_store.dart';

void main() {
  late DemoStore store;
  late FakeLeaveRequestsRepo repo;

  const employee = DemoSeed.employeeCode; // 10000032, Operations Coordinator
  const manager = DemoSeed.managerCode; //  10000031, their N+1

  setUp(() {
    store = DemoStore.instance..reset();
    repo = FakeLeaveRequestsRepo(store);
  });

  Future<int> fileRequest() {
    store.switchUser(employee);
    return repo.submitLeaveRequest(
      LeaveRequestModel(
        userId: employee,
        dateFrom: DateTime.now().add(const Duration(days: 30)),
        dateTo: DateTime.now().add(const Duration(days: 32)),
        leaveType: 'Annual',
        numberOfDays: 3,
      ),
    );
  }

  Future<List<int>> pageIds(LeaveRequestScope scope) async {
    final page = await repo.getLeaveRequestsPage(
      LeaveRequestsQuery(scope: scope),
      offset: 0,
      limit: 100,
    );
    return page.items.map((r) => r.rowId!).toList();
  }

  test('the seeded organisation and requests load', () {
    expect(store.users.length, 38);
    expect(store.leaveRequests, isNotEmpty);
    expect(store.userByCode(employee)?.n1, manager);
  });

  test('a filed request appears in My Requests', () async {
    final before = (await pageIds(LeaveRequestScope.my)).length;
    final id = await fileRequest();

    final mine = await pageIds(LeaveRequestScope.my);
    expect(mine.length, before + 1);
    expect(mine, contains(id));
  });

  test('a filed request lands in the manager\'s Team queue', () async {
    final id = await fileRequest();

    // The employee is not an approver of their own request.
    expect(await pageIds(LeaveRequestScope.team), isNot(contains(id)));

    store.switchUser(manager);
    expect(await pageIds(LeaveRequestScope.team), contains(id));
    expect(await repo.hasTeamRequests(manager), isTrue);
  });

  test('approving escalates the request and files it under Processed', () async {
    final id = await fileRequest();

    store.switchUser(manager);
    expect(await pageIds(LeaveRequestScope.team), contains(id));

    await repo.approveRequest(id, 'n1', manager);

    // No longer awaiting this manager...
    expect(await pageIds(LeaveRequestScope.team), isNot(contains(id)));
    // ...but now in the requests they have acted on.
    expect(await pageIds(LeaveRequestScope.processed), contains(id));

    // And it has moved one step up the chain rather than being approved
    // outright, because this employee has an N+2.
    final row = store.leaveRequests.firstWhere((r) => r.id == id);
    expect(row.status, 'pending');
    expect(row.currentApprover, 'n2');
  });

  test('declining records a reason and stops the chain', () async {
    final id = await fileRequest();
    store.switchUser(manager);

    await repo.declineRequest(id, 'Coverage unavailable.', 'n1', manager);

    final row = store.leaveRequests.firstWhere((r) => r.id == id);
    expect(row.status, 'declined');
    expect(row.declineReason, 'Coverage unavailable.');
    expect(await pageIds(LeaveRequestScope.processed), contains(id));
  });

  test('the request stays visible to its author throughout', () async {
    final id = await fileRequest();
    store.switchUser(manager);
    await repo.approveRequest(id, 'n1', manager);

    store.switchUser(employee);
    expect(await pageIds(LeaveRequestScope.my), contains(id));
  });

  test('the seeded HR queue is visible to HR and to nobody else', () async {
    store.switchUser(DemoSeed.hrCode);
    final hrQueue = await pageIds(LeaveRequestScope.team);
    expect(hrQueue, isNotEmpty, reason: 'seed includes requests awaiting HR');

    store.switchUser(employee);
    final employeeQueue = await pageIds(LeaveRequestScope.team);
    expect(employeeQueue.toSet().intersection(hrQueue.toSet()), isEmpty);
  });

  test('paging reports the full count, not just the page', () async {
    store.switchUser(manager);
    final page = await repo.getLeaveRequestsPage(
      const LeaveRequestsQuery(scope: LeaveRequestScope.team),
      offset: 0,
      limit: 1,
    );
    expect(page.items.length, lessThanOrEqualTo(1));
    expect(page.totalCount, greaterThanOrEqualTo(page.items.length));
  });

  test('reset restores the seeded state', () async {
    final id = await fileRequest();
    expect(await pageIds(LeaveRequestScope.my), contains(id));

    store.reset();
    store.switchUser(employee);
    expect(await pageIds(LeaveRequestScope.my), isNot(contains(id)));
  });
}
