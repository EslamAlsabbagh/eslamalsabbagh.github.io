import '../core/domain/contract_item_kind.dart';
import '../core/domain/contract_kind.dart';
import '../core/domain/contract_status.dart';
import '../core/domain/task_status.dart';
import '../core/domain/unit_kind.dart';
import '../core/domain/user_role.dart';
import 'demo_store.dart';

/// The demo's fictional data. Every person, mall, brand and company here is
/// invented. Dates are relative to today, so "overdue", "due today" and
/// "ending soon" always mean something when the demo is opened.
abstract final class DemoSeed {
  static const adminId = 'p-admin';
  static const managerId = 'p-manager';
  static const lawyerId = 'p-laila';

  /// The accounts the demo bar's role buttons sign in as.
  static const roleAccounts = <(String label, String id)>[
    ('Manager', managerId),
    ('Lawyer', lawyerId),
    ('Admin', adminId),
  ];

  static void populate(DemoStore s) {
    final now = s.now;
    final today = s.today;
    DateTime day(int offset) => today.add(Duration(days: offset));
    DateTime ago(int days, [int hours = 0]) => now.subtract(Duration(days: days, hours: hours));

    // ── People ────────────────────────────────────────────────────────────────
    final created = ago(400);
    s.profiles.addAll([
      DemoProfile(id: adminId, displayName: 'Nadia Fawzy', email: 'nadia@example.com', role: UserRole.admin, createdAt: created),
      DemoProfile(id: managerId, displayName: 'Omar Haddad', email: 'omar@example.com', role: UserRole.manager, createdAt: created.add(const Duration(minutes: 1))),
      DemoProfile(id: lawyerId, displayName: 'Laila Mansour', email: 'laila@example.com', role: UserRole.lawyer, createdAt: created.add(const Duration(minutes: 2)), fileIds: {'f-harbor', 'f-cedar'}),
      DemoProfile(id: 'p-karim', displayName: 'Karim Saleh', email: 'karim@example.com', role: UserRole.lawyer, createdAt: created.add(const Duration(minutes: 3)), fileIds: {'f-cedar', 'f-sunline'}),
      DemoProfile(id: 'p-yara', displayName: 'Yara Nabil', email: 'yara@example.com', role: UserRole.lawyer, createdAt: created.add(const Duration(minutes: 4)), fileIds: {'f-harbor', 'f-sunline'}),
      DemoProfile(id: 'p-hany', displayName: 'Hany Samir', email: 'hany@example.com', role: UserRole.lawyer, createdAt: created.add(const Duration(minutes: 5)), fileIds: {'f-cedar'}, isActive: false),
    ]);

    // ── Files (malls) and topics (tenant brands) ────────────────────────────────
    s.files.addAll([
      DemoFile(id: 'f-harbor', name: 'Harbor Point Mall', createdAt: ago(380)),
      DemoFile(id: 'f-cedar', name: 'Cedar Grove Plaza', createdAt: ago(379)),
      DemoFile(id: 'f-sunline', name: 'Sunline Walk', createdAt: ago(378)),
    ]);
    const brands = {
      'brew': ('f-harbor', 'Brew & Company'),
      'nimbus': ('f-harbor', 'Nimbus Sports'),
      'lumen': ('f-harbor', 'Lumen Optics'),
      'kiddo': ('f-harbor', 'Kiddo Land'),
      'saffron': ('f-cedar', 'Saffron Kitchen'),
      'urban': ('f-cedar', 'Urban Thread'),
      'pixel': ('f-cedar', 'PixelHub'),
      'bloom': ('f-sunline', 'Bloom Florist'),
      'aqua': ('f-sunline', 'Aqua Fitness'),
      'pages': ('f-sunline', 'Pages Bookstore'),
    };
    var minute = 0;
    brands.forEach((key, value) {
      s.topics.add(DemoTopic(id: 'tp-$key', fileId: value.$1, name: value.$2, createdAt: ago(370).add(Duration(minutes: minute++))));
    });

    // ── Parties and units ─────────────────────────────────────────────────────
    const partyNames = {
      'brew': 'Brew & Co. Trading LLC',
      'nimbus': 'Nimbus Retail Group',
      'lumen': 'Lumen Vision Co.',
      'kiddo': 'Kiddo Entertainment',
      'saffron': 'Saffron Restaurants',
      'urban': 'Urban Thread Apparel',
      'pixel': 'PixelHub Electronics',
      'bloom': 'Bloom & Petal',
      'aqua': 'Aqua Fitness Clubs',
      'aquaH': 'Aqua Wellness Holding',
      'pages': 'Pages Books',
      'spark': 'SparkPro Facility Services',
    };
    partyNames.forEach((key, name) => s.parties.add(DemoParty(id: 'pa-$key', name: name)));

    void unitRow(String id, String file, String code, UnitKind kind, [String? keyNumber]) =>
        s.units.add(DemoUnit(id: id, fileId: file, code: code, kind: kind, keyNumber: keyNumber));
    unitRow('un-h1', 'f-harbor', 'HP-GF-U01', UnitKind.shop);
    unitRow('un-h2', 'f-harbor', 'HP-GF-U02', UnitKind.shop);
    unitRow('un-h3', 'f-harbor', 'HP-GF-U03', UnitKind.shop);
    unitRow('un-h5', 'f-harbor', 'HP-GF-U05', UnitKind.shop);
    unitRow('un-h10', 'f-harbor', 'HP-FF-U10', UnitKind.shop);
    unitRow('un-hs1', 'f-harbor', 'HP-FF-S01', UnitKind.space);
    unitRow('un-hst', 'f-harbor', 'HP-ST-04', UnitKind.storage, '112');
    unitRow('un-c1', 'f-cedar', 'CG-GF-U01', UnitKind.shop);
    unitRow('un-c2', 'f-cedar', 'CG-GF-U02', UnitKind.shop);
    unitRow('un-c7', 'f-cedar', 'CG-FF-U07', UnitKind.shop);
    unitRow('un-c8', 'f-cedar', 'CG-FF-U08', UnitKind.shop);
    unitRow('un-cst', 'f-cedar', 'CG-ST-02', UnitKind.storage, '208');
    unitRow('un-sk1', 'f-sunline', 'SW-K-01', UnitKind.kiosk);
    unitRow('un-s3', 'f-sunline', 'SW-GF-U03', UnitKind.shop);
    unitRow('un-s4', 'f-sunline', 'SW-GF-U04', UnitKind.shop);
    unitRow('un-s11', 'f-sunline', 'SW-FF-U11', UnitKind.shop);
    unitRow('un-ssite', 'f-sunline', 'SW-SITE-01', UnitKind.site);

    // ── Contracts ───────────────────────────────────────────────────────────────
    DemoContract lease(
      String id,
      String brand, {
      required String party,
      required List<String> units,
      required int signedDaysAgo,
      int? endsIn,
      String activity = '',
      String subject = 'Lease of a retail unit',
      double? inner,
      double? outer,
      String dateNote = '',
      ContractKind kind = ContractKind.lease,
      String? file,
    }) {
      final c = DemoContract(
        id: id,
        fileId: file ?? brands[brand]!.$1,
        kind: kind,
        createdAt: ago(signedDaysAgo - 2),
        topicId: kind == ContractKind.service ? null : 'tp-$brand',
        subject: subject,
        activity: activity,
        signedOn: day(-signedDaysAgo),
        endsOn: endsIn == null ? null : day(endsIn),
        dateNote: dateNote,
        areaInner: inner,
        areaOuter: outer,
        partyId: 'pa-$party',
        unitIds: units,
      );
      s.contracts.add(c);
      s.logContract(c, 'created',
          actorId: managerId, at: c.createdAt, newValue: {'kind': c.kind.name, 'annex_no': null, 'subject': c.subject});
      return c;
    }

    DemoContract child(
      DemoContract parent,
      String id, {
      required ContractKind kind,
      required int signedDaysAgo,
      int? annexNo,
      String subject = '',
      int? endsIn,
      double? outer,
      String? party,
      List<String> units = const [],
    }) {
      final c = DemoContract(
        id: id,
        fileId: parent.fileId,
        kind: kind,
        createdAt: ago(signedDaysAgo - 1),
        topicId: parent.topicId,
        parentId: parent.id,
        annexNo: annexNo,
        subject: subject,
        signedOn: day(-signedDaysAgo),
        endsOn: endsIn == null ? null : day(endsIn),
        areaOuter: outer,
        partyId: party == null ? null : 'pa-$party',
        unitIds: [...units],
      );
      s.contracts.add(c);
      s.logContract(c, 'created',
          actorId: managerId, at: c.createdAt, newValue: {'kind': c.kind.name, 'annex_no': annexNo, 'subject': subject});
      return c;
    }

    final brewLease = lease('c-brew', 'brew',
        party: 'brew', units: ['un-h1'], signedDaysAgo: 610, endsIn: 480, activity: 'Café', inner: 85, outer: 20);
    child(brewLease, 'c-brew-a1',
        kind: ContractKind.annex, annexNo: 1, signedDaysAgo: 300, subject: 'Larger outdoor seating area', outer: 32);
    final brewA2 = child(brewLease, 'c-brew-a2',
        kind: ContractKind.annex,
        annexNo: 2,
        signedDaysAgo: 18,
        subject: 'Adds the neighbouring unit',
        units: ['un-h1', 'un-h2']);
    lease('c-nimbus', 'nimbus',
        party: 'nimbus', units: ['un-h10'], signedDaysAgo: 1040, endsIn: 58, activity: 'Sportswear', inner: 140);
    lease('c-lumen', 'lumen',
        party: 'lumen', units: ['un-h3'], signedDaysAgo: 700, endsIn: 24, activity: 'Optics', inner: 62);
    final kiddoLease = lease('c-kiddo', 'kiddo',
        party: 'kiddo', units: ['un-hs1'], signedDaysAgo: 250, endsIn: 845, activity: 'Indoor play area', inner: 310);
    final kiddoStorage = child(kiddoLease, 'c-kiddo-st',
        kind: ContractKind.storage, signedDaysAgo: 30, subject: 'Storage room', endsIn: 845, party: 'kiddo', units: ['un-hst']);
    final saffron = lease('c-saffron', 'saffron',
        party: 'saffron', units: ['un-c1', 'un-c2'], signedDaysAgo: 120, endsIn: 1700, activity: 'Restaurant', inner: 210, outer: 45);
    final urban = lease('c-urban', 'urban',
        party: 'urban', units: ['un-c7'], signedDaysAgo: 820, endsIn: 300, activity: 'Fashion', inner: 120);
    final pixel = lease('c-pixel', 'pixel',
        party: 'pixel', units: ['un-c8'], signedDaysAgo: 400, endsIn: 330, activity: 'Electronics', inner: 95);
    child(pixel, 'c-pixel-st',
        kind: ContractKind.storage, signedDaysAgo: 380, subject: 'Storage room', endsIn: 330, party: 'pixel', units: ['un-cst']);
    final bloom = lease('c-bloom', 'bloom',
        party: 'bloom',
        units: ['un-sk1'],
        signedDaysAgo: 75,
        activity: 'Flowers',
        subject: 'Kiosk licence',
        dateNote: 'Until the end of the summer season');
    final aqua = lease('c-aqua', 'aqua',
        party: 'aqua', units: ['un-s3', 'un-s4'], signedDaysAgo: 520, endsIn: 1300, activity: 'Gym and pool', inner: 640);
    child(aqua, 'c-aqua-a1',
        kind: ContractKind.annex, annexNo: 1, signedDaysAgo: 90, subject: 'Transfer to the holding company', party: 'aquaH');
    lease('c-pages', 'pages',
        party: 'pages', units: ['un-s11'], signedDaysAgo: 1100, endsIn: -6, activity: 'Books and stationery', inner: 150);
    lease('c-spark', 'brew',
        file: 'f-sunline',
        kind: ContractKind.service,
        party: 'spark',
        units: [],
        signedDaysAgo: 210,
        endsIn: 155,
        subject: 'Cleaning and facility services',
        activity: 'Cleaning');

    // Urban Thread left by mutual agreement.
    urban
      ..status = ContractStatus.terminated
      ..terminatedOn = day(-10)
      ..terminationReason = 'Tenant exit by mutual agreement';
    s.logContract(urban, 'status_changed',
        actorId: managerId,
        at: ago(10),
        oldValue: {'status': 'active'},
        newValue: {'status': 'terminated', 'termination_reason': urban.terminationReason});

    // ── Checklist items ───────────────────────────────────────────────────────
    void missing(DemoContract c, String label, {bool signature = false, bool stamp = false, int daysAgo = 5}) {
      final item = DemoItem(
        id: s.id('i'),
        kind: ContractItemKind.missing,
        contractId: c.id,
        label: label,
        needsSignature: signature,
        needsStamp: stamp,
        createdAt: ago(daysAgo),
      );
      s.items.add(item);
      s.logContract(c, 'item_added', actorId: lawyerId, at: item.createdAt, newValue: {'label': label, 'contract_id': c.id});
    }

    void document(String party, DemoContract on, String label, {bool resolved = false, int daysAgo = 20}) {
      final item = DemoItem(
        id: s.id('i'),
        kind: ContractItemKind.document,
        partyId: 'pa-$party',
        label: label,
        isResolved: resolved,
        createdAt: ago(daysAgo),
      );
      s.items.add(item);
      s.logContract(on, 'item_added', actorId: managerId, at: item.createdAt, newValue: {'label': label, 'contract_id': null});
    }

    missing(brewA2, 'Stamped copy of annex 2', stamp: true, daysAgo: 16);
    missing(kiddoStorage, 'Tenant signature on the storage contract', signature: true, daysAgo: 25);
    missing(saffron, 'Landlord signature on page 7', signature: true, daysAgo: 110);
    document('saffron', saffron, 'Tax card copy', daysAgo: 100);
    document('saffron', saffron, 'Commercial register extract', resolved: true, daysAgo: 115);
    document('bloom', bloom, 'Commercial register copy', daysAgo: 60);
    document('aquaH', aqua, 'Board resolution approving the transfer', daysAgo: 80);

    // ── Tasks ───────────────────────────────────────────────────────────────────
    final rows = <_T>[
      _T('brew', 'Send the renewal offer for the café unit', 'p-yara', -3, TaskStatus.doing, updates: [
        ('p-yara', 'Called the tenant\'s office. They asked for the draft by email.', 4),
        ('p-manager', 'Use the standard 5% escalation, not the old 7%.', 3),
      ]),
      _T('brew', 'Collect the stamped copy of annex 2', lawyerId, 0, TaskStatus.todo, contract: 'c-brew-a2'),
      _T('brew', 'مراجعة بند الغرامات في عقد الإيجار', lawyerId, 5, TaskStatus.todo),
      _T('brew', 'Quarterly review of all expiring leases', managerId, 10, TaskStatus.todo),
      _T('nimbus', 'Reply to the tenant\'s objection on service charges', 'p-yara', -1, TaskStatus.waiting, updates: [
        ('p-yara', 'Sent our reply. Waiting for their finance team.', 2),
      ]),
      _T('nimbus', 'Prepare the late-payment notice for Q3', lawyerId, 2, TaskStatus.todo, urgent: true),
      _T('nimbus', 'Archive the signed fit-out permit', 'p-yara', -10, TaskStatus.done, closedDaysAgo: 8),
      _T('lumen', 'Draft a 12-month extension annex', lawyerId, 9, TaskStatus.doing, contract: 'c-lumen', updates: [
        ('p-laila', 'First draft is in the shared folder for review.', 1),
      ]),
      _T('lumen', 'Confirm the insurance certificate is current', 'p-yara', 14, TaskStatus.todo),
      _T('lumen', 'Update the tenant contact list', 'p-yara', 30, TaskStatus.todo),
      _T('kiddo', 'Review the play-area safety undertaking', lawyerId, 1, TaskStatus.todo),
      _T('kiddo', 'متابعة توقيع عقد التخزين', 'p-yara', -4, TaskStatus.doing, contract: 'c-kiddo-st', updates: [
        ('p-yara', 'تم التواصل مع المستأجر وسيرسل النسخة الموقعة هذا الأسبوع.', 2),
      ]),
      _T('kiddo', 'Close out the old signage dispute', lawyerId, -20, TaskStatus.cancelled, closedDaysAgo: 15),
      _T('saffron', 'Renew the kitchen exhaust maintenance clause', 'p-karim', 0, TaskStatus.doing, updates: [
        ('p-karim', 'Facilities confirmed the new contractor\'s details.', 3),
        ('p-manager', 'Please copy finance on the final version.', 1),
      ]),
      _T('saffron', 'Obtain the tax card copy from the tenant', lawyerId, 3, TaskStatus.todo, contract: 'c-saffron'),
      _T('saffron', 'Register the lease at the notary office', 'p-karim', 18, TaskStatus.todo),
      _T('saffron', 'Brief the new lawyer on the Cedar Grove portfolio', managerId, 1, TaskStatus.doing),
      _T('urban', 'Termination letter: confirm the handover date', 'p-karim', -2, TaskStatus.waiting),
      _T('urban', 'Calculate the early-exit settlement', managerId, 4, TaskStatus.todo),
      _T('urban', 'Settle the deposit refund', lawyerId, -12, TaskStatus.done, closedDaysAgo: 9),
      _T('pixel', 'إعداد مذكرة الرد على الإنذار', 'p-karim', -5, TaskStatus.doing, updates: [
        ('p-karim', 'المسودة الأولى جاهزة وتنتظر مراجعة المدير.', 2),
      ]),
      _T('pixel', 'Check the subletting request against clause 14', lawyerId, 7, TaskStatus.todo),
      _T('pixel', 'Confirm the storage key handover', lawyerId, -2, TaskStatus.todo),
      _T('pixel', 'Send the signed annex to finance', 'p-karim', -15, TaskStatus.done, closedDaysAgo: 14),
      _T('bloom', 'Agree the seasonal kiosk extension', 'p-yara', 6, TaskStatus.todo),
      _T('bloom', 'Chase the missing commercial register copy', 'p-karim', -1, TaskStatus.todo, contract: 'c-bloom'),
      _T('aqua', 'Review the pool equipment liability clause', 'p-yara', 0, TaskStatus.waiting, urgent: true),
      _T('aqua', 'تجديد عقد الصيانة السنوي', 'p-karim', 21, TaskStatus.todo),
      _T('aqua', 'Respond to the noise complaint from the next unit', 'p-yara', -3, TaskStatus.doing),
      _T('aqua', 'مراجعة شهادة الدفاع المدني', 'p-karim', 8, TaskStatus.todo),
      _T('aqua', 'Collect the signed house rules acknowledgement', 'p-karim', -25, TaskStatus.done, closedDaysAgo: 22),
      _T('pages', 'Prepare the renewal pack for signature', 'p-yara', 11, TaskStatus.todo, contract: 'c-pages'),
      _T('pages', 'Verify the bank guarantee amount', 'p-karim', 2, TaskStatus.doing),
      _T('pages', 'File the reading-corner permit', managerId, -7, TaskStatus.done, closedDaysAgo: 6),
    ];

    for (final (index, row) in rows.indexed) {
      final createdAt = ago(14 + (index % 9), index % 7);
      final t = DemoTask(
        id: 't-${index + 1}',
        topicId: 'tp-${row.brand}',
        title: row.title,
        description: row.description,
        assigneeId: row.assignee,
        createdBy: managerId,
        status: TaskStatus.todo,
        isUrgent: row.urgent,
        dueDate: day(row.due),
        createdAt: createdAt,
        contractId: row.contract,
      );
      s.tasks.add(t);
      s.logTask(t, 'created', actorId: managerId, at: createdAt, newValue: {
        'title': t.title,
        'status': 'todo',
        'assignee_id': t.assigneeId,
        'due_date': DemoStore.ymd(t.dueDate),
        'is_urgent': t.isUrgent,
        'topic_id': t.topicId,
      });
      if (row.status != TaskStatus.todo) {
        final at = row.closedDaysAgo != null ? ago(row.closedDaysAgo!) : ago(5 + index % 4);
        t.status = row.status;
        if (row.status.isClosed) t.completedAt = at;
        s.logTask(t, 'status_changed', actorId: row.assignee, at: at, oldValue: 'todo', newValue: row.status.name);
      }
      for (final (author, body, daysAgo) in row.updates) {
        s.updates.add(DemoUpdate(id: s.id('u'), taskId: t.id, authorId: author, body: body, createdAt: ago(daysAgo, 2)));
        s.notify(t, type: 'update_posted', actorId: author, recipients: [t.assigneeId, t.createdBy], at: ago(daysAgo, 2));
      }
    }

    // Anything older than two days has been seen; the rest rings the bell.
    for (final n in s.notifications) {
      if (n.createdAt.isBefore(ago(2))) n.readAt = n.createdAt.add(const Duration(hours: 3));
    }
  }
}

class _T {
  const _T(
    this.brand,
    this.title,
    this.assignee,
    this.due,
    this.status, {
    this.urgent = false,
    this.contract,
    this.closedDaysAgo,
    this.updates = const [],
  });

  final String brand;
  final String title;
  final String assignee;
  final int due;
  final TaskStatus status;
  final bool urgent;
  final String? contract;
  final int? closedDaysAgo;

  /// (author, body, days ago)
  final List<(String, String, int)> updates;

  String get description => '';
}
