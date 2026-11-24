import 'package:flutter_test/flutter_test.dart';
import 'package:legal_tasks_demo/core/domain/contract_kind.dart';
import 'package:legal_tasks_demo/core/domain/task_status.dart';
import 'package:legal_tasks_demo/demo/demo_seed.dart';
import 'package:legal_tasks_demo/demo/demo_store.dart';
import 'package:legal_tasks_demo/features/admin/data/user_save_failure.dart';
import 'package:legal_tasks_demo/features/admin/data/users_repository.dart';
import 'package:legal_tasks_demo/features/contracts/data/contract_record.dart';
import 'package:legal_tasks_demo/features/contracts/data/contract_save_failure.dart';
import 'package:legal_tasks_demo/features/contracts/data/contracts_repository.dart';
import 'package:legal_tasks_demo/features/notifications/data/notifications_repository.dart';
import 'package:legal_tasks_demo/features/tasks/data/task_save_failure.dart';
import 'package:legal_tasks_demo/features/tasks/data/tasks_repository.dart';

/// The demo's in-memory backend keeps the production rules. These checks run
/// the flows a visitor clicks through, against the repositories the screens use.
void main() {
  final store = DemoStore.instance;
  final tasks = TasksRepository(store);
  final contracts = ContractsRepository(store);
  final notifications = NotificationsRepository(store);
  final users = UsersRepository(store);

  setUp(store.reset);

  test('a lawyer sees only their member files', () async {
    store.signInAs(DemoSeed.managerId);
    final all = await tasks.fetchTasks();
    store.signInAs(DemoSeed.lawyerId);
    final mine = await tasks.fetchTasks();
    expect(mine.length, lessThan(all.length));
    expect(mine.map((t) => t.fileId).toSet(), {'f-harbor', 'f-cedar'});
  });

  test('a task the manager assigns rings the lawyer\'s bell', () async {
    store.signInAs(DemoSeed.lawyerId);
    final before = await notifications.fetchUnreadCount();
    store.signInAs(DemoSeed.managerId);
    final id = await tasks.createTask(
      topicId: 'tp-brew',
      title: 'Check the new signage permit',
      description: '',
      assigneeId: DemoSeed.lawyerId,
      dueDate: DateTime.now(),
      isManualUrgent: false,
    );
    store.signInAs(DemoSeed.lawyerId);
    expect(await notifications.fetchUnreadCount(), before + 1);
    final details = await tasks.fetchTask(id);
    expect(details.item.isUrgentNow, isTrue);
    await tasks.updateTask(id, status: TaskStatus.done);
    expect((await tasks.fetchActivity(id)).length, 2);
  });

  test('a lawyer cannot edit someone else\'s task or assign to others', () async {
    store.signInAs(DemoSeed.lawyerId);
    final others = (await tasks.fetchTasks()).firstWhere((t) => t.assigneeId != DemoSeed.lawyerId);
    await expectLater(
      () => tasks.updateTask(others.id, status: TaskStatus.done),
      throwsA(isA<TaskSaveException>().having((e) => e.failure, 'failure', TaskSaveFailure.notAllowed)),
    );
    await expectLater(
      () => tasks.createTask(
          topicId: 'tp-brew', title: 'x', description: '', assigneeId: 'p-yara', dueDate: DateTime.now(), isManualUrgent: false),
      throwsA(isA<TaskSaveException>()),
    );
  });

  test('search matches every word, Arabic normalized', () async {
    store.signInAs(DemoSeed.managerId);
    expect(await tasks.searchTaskIds('renewal cafe'), isEmpty); // é is not e
    expect(await tasks.searchTaskIds('renewal café'), isNotEmpty);
    expect(await tasks.searchTaskIds('عقد التخزين'), isNotEmpty);
    expect(await tasks.searchTaskIds('عقد التخزين'.replaceAll('ي', 'ى')), isNotEmpty);
  });

  test('contracts: list, details after annexes, register', () async {
    store.signInAs(DemoSeed.managerId);
    final list = await contracts.fetchContracts();
    expect(list.length, 11);
    expect(list.map((c) => c.listStatus.name).toSet(), containsAll(['active', 'ending', 'expired', 'terminated']));
    final brew = await contracts.fetchDetails('c-brew');
    expect(brew.unitCodes, ['HP-GF-U01', 'HP-GF-U02']);
    expect(brew.unitsAnnexNo, 2);
    expect(brew.areaOuterAnnexNo, 1);
    final aqua = await contracts.fetchDetails('c-aqua');
    expect(aqua.partyName, 'Aqua Wellness Holding');
    for (final c in list) {
      await contracts.fetchDetails(c.id);
      await contracts.fetchRecord(c.id);
      await contracts.fetchChildren(c.id);
      await contracts.fetchActivity(c.id);
    }
    final register = await contracts.fetchRegister([for (final c in list) c.id]);
    expect(register.mains.length, 11);
    expect(register.contracts.length, greaterThan(11));
    expect(register.items, isNotEmpty);
    expect(register.followUps, isNotEmpty);
    expect((await contracts.searchContractIds('HP-GF-U02')), {'c-brew'});
  });

  test('contracts: annex numbers are unique, deletes are guarded', () async {
    store.signInAs(DemoSeed.managerId);
    await expectLater(
      () => contracts.saveAnnex(const AnnexInput(
          id: null, parentId: 'c-brew', annexNo: 2, subject: 'dup', signedOn: null, notes: '', endsOn: null,
          areaInner: null, areaOuter: null, partyId: null, unitIds: [])),
      throwsA(isA<ContractSaveException>()
          .having((e) => e.failure, 'failure', ContractSaveFailure.duplicateAnnexNo)),
    );
    await expectLater(() => contracts.delete('c-brew'), throwsA(isA<ContractSaveException>()));
    final id = await contracts.saveContract(const ContractInput(
        id: null, fileId: 'f-cedar', kind: ContractKind.service, parentId: null, topicId: null, partyId: 'pa-spark',
        subject: 'Security services', activity: 'Security', signedOn: null, startsOn: null, endsOn: null,
        dateNote: '', areaInner: null, areaOuter: null, areaNote: '', notes: '', unitIds: []));
    await contracts.terminate(id, on: DateTime.now(), reason: 'Test');
    await contracts.reopen(id);
    await contracts.delete(id);
    expect((await contracts.fetchContracts()).length, 11);
  });

  test('admins only: users and their guards', () async {
    store.signInAs(DemoSeed.lawyerId);
    await expectLater(() => users.fetchUsers(), throwsA(isA<UserSaveException>()));
    store.signInAs(DemoSeed.adminId);
    expect((await users.fetchUsers()).length, 6);
    await expectLater(
      () => users.setActive('p-karim', active: false),
      throwsA(isA<UserSaveException>().having((e) => e.failure, 'failure', UserSaveFailure.openTasks)),
    );
    await users.setActive('p-hany', active: true);
  });
}
