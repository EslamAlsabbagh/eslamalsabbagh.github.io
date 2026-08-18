import 'package:hrms_demo/data/models/user_model.dart';

/// Fictional organisation used by the demo build.
///
/// Every person, code, balance and reporting line in here is invented. Nothing
/// corresponds to a real employee of any organisation, and the demo makes no
/// network calls of any kind — this file *is* the entire dataset.
///
/// The hierarchy is deliberately shaped so that every approval path in the
/// product has something to show:
///
/// ```
/// 10000001  Managing Director            (top management)
///   ├── 10000010  HR Director            (hr)
///   │     └── 10000011  HR Manager       (hr)
///   │           └── 10000012  HR Specialist (hr)
///   ├── 10000020  Finance Director       (finance)
///   │     └── 10000021  Finance Manager  (finance)
///   │           └── 10000022..24  Finance staff
///   ├── 10000030  Operations Director
///   │     ├── 10000031  Operations Manager
///   │     │     └── 10000032..37  Operations staff
///   │     └── 10000040  Maintenance Manager
///   │           └── 10000041..44  Maintenance staff
///   ├── 10000050  IT Manager
///   │     └── 10000051..53  IT staff
///   ├── 10000060  Leasing Manager
///   │     └── 10000061..64  Leasing staff
///   └── 10000070  Security Manager
///         └── 10000071..76  Security staff
/// ```
class DemoSeed {
  DemoSeed._();

  /// The employee the demo signs in as by default.
  static const int defaultUserCode = 10000032;

  /// Codes offered by the demo role switcher.
  static const int employeeCode = 10000032; // Operations Coordinator
  static const int managerCode = 10000031; // Operations Manager
  static const int hrCode = 10000011; // HR Manager
  static const int financeCode = 10000021; // Finance Manager
  static const int topManagementCode = 10000001; // Managing Director

  static const String companyName = 'Northwind Group';

  /// Every seeded employee, in hierarchy order.
  static List<UserModel> employees() => _rows.map(_toUser).toList();

  static UserModel _toUser(_Row r) {
    return UserModel(
      id: r.code,
      loginCode: r.code,
      englishName: r.en,
      arabicName: r.ar,
      englishNickname: r.en.split(' ').first,
      arabicNickname: r.ar.split(' ').first,
      englishTitle: r.title,
      title: r.titleAr,
      englishDepartment: r.dept,
      department: r.deptAr,
      location: r.location,
      costCenter: r.costCenter,
      hireDate: r.hireDate,
      n1: r.n1,
      n2: r.n2,
      email: '${r.code}@demo.local',
      authEmail: '${r.code}@demo.local',
      nationalId: '2${r.code}00${r.code % 97}',
      phoneNumber: '+20 10 ${1000 + (r.code % 9000)} ${1000 + (r.code % 8999)}',
      address: '${r.location} District, Cairo',
      userState: 'active',
      groups: r.groups,
      leavesEligibility: r.eligibility,
      workingDays: 5,
      shiftHours: 8,
      leaveBalance: r.leaveBalance,
      annualRemainingBalance: r.leaveBalance,
      carryForwardBalance: r.carryForward,
      overtimeBalance: r.overtime,
      overtimeCarryForwardBalance: 0,
      emergencyBalance: r.emergency,
      missingPunchBalance: r.missingPunch,
      daysTakenThisYear: (r.eligibility - r.leaveBalance).clamp(0, 60).toDouble(),
      monthlyLeaveRate: r.eligibility / 12,
      advanceOnSalaryEligibilityDate: DateTime(2026, 1, 1),
    );
  }

  // ── The organisation ──────────────────────────────────────────────────────
  static const List<_Row> _rows = [
    // Top management
    _Row(10000001, 'Adam Kirkland', 'آدم كيركلاند', 'Managing Director',
        'العضو المنتدب', 'Top Management', 'الإدارة العليا', 'HQ', 'Company',
        '2018-03-01', null, null, ['top management'], 30, 21.5, 5, 12, 3, 2),

    // Human Resources
    _Row(10000010, 'Hana Whitfield', 'هنا ويتفيلد', 'HR Director',
        'مدير الموارد البشرية', 'Human Resources Department', 'إدارة الموارد البشرية',
        'HQ', 'Company', '2019-05-12', 10000001, null, ['hr'], 27, 18.0, 4, 8, 2, 2),
    _Row(10000011, 'Karim Fouad', 'كريم فؤاد', 'HR Manager',
        'مدير إدارة الموارد البشرية', 'Human Resources Department', 'إدارة الموارد البشرية',
        'HQ', 'Company', '2020-02-03', 10000010, 10000001, ['hr'], 24, 15.5, 3, 6, 1, 2),
    _Row(10000012, 'Salma Nabil', 'سلمى نبيل', 'HR Specialist',
        'أخصائي موارد بشرية', 'Human Resources Department', 'إدارة الموارد البشرية',
        'HQ', 'Company', '2022-09-18', 10000011, 10000010, ['hr'], 21, 12.0, 2, 4, 1, 2),

    // Finance
    _Row(10000020, 'Yousef Darwish', 'يوسف درويش', 'Finance Director',
        'المدير المالي', 'Financial Department', 'الإدارة المالية', 'HQ', 'Company',
        '2019-01-20', 10000001, null, ['finance'], 27, 19.0, 4, 9, 2, 2),
    _Row(10000021, 'Nour El Sayed', 'نور السيد', 'Finance Manager',
        'مدير مالي', 'Financial Department', 'الإدارة المالية', 'HQ', 'Company',
        '2021-04-11', 10000020, 10000001, ['finance'], 24, 16.5, 3, 7, 2, 2),
    _Row(10000022, 'Mostafa Adel', 'مصطفى عادل', 'Senior Accountant',
        'محاسب أول', 'Financial Department', 'الإدارة المالية', 'HQ', 'Company',
        '2022-06-05', 10000021, 10000020, [], 21, 13.5, 2, 5, 1, 2),
    _Row(10000023, 'Dina Roshdy', 'دينا رشدي', 'Accountant',
        'محاسب', 'Financial Department', 'الإدارة المالية', 'HQ', 'Company',
        '2023-08-14', 10000021, 10000020, [], 21, 9.0, 1, 3, 2, 2),
    _Row(10000024, 'Peter Wassef', 'بيتر واصف', 'Collections Officer',
        'مسؤول تحصيل', 'Collection Department', 'إدارة التحصيل', 'RIVERSIDE', 'RIVERSIDE',
        '2024-01-08', 10000021, 10000020, [], 21, 11.0, 0, 2, 1, 2),

    // Operations
    _Row(10000030, 'Sherif Mansour', 'شريف منصور', 'Operations Director',
        'مدير العمليات', 'Operations Department', 'إدارة العمليات', 'RIVERSIDE', 'RIVERSIDE',
        '2019-09-02', 10000001, null, [], 27, 17.5, 4, 10, 2, 2),
    _Row(10000031, 'Laila Hassan', 'ليلى حسن', 'Operations Manager',
        'مدير تشغيل', 'Operations Department', 'إدارة العمليات', 'RIVERSIDE', 'RIVERSIDE',
        '2021-07-19', 10000030, 10000001, [], 24, 14.0, 3, 8, 1, 2),
    _Row(10000032, 'Omar Tarek', 'عمر طارق', 'Operations Coordinator',
        'منسق عمليات', 'Operations Department', 'إدارة العمليات', 'RIVERSIDE', 'RIVERSIDE',
        '2023-03-06', 10000031, 10000030, [], 21, 12.5, 2, 6, 3, 2),
    _Row(10000033, 'Mariam Sobhy', 'مريم صبحي', 'Operations Coordinator',
        'منسق عمليات', 'Operations Department', 'إدارة العمليات', 'RIVERSIDE', 'RIVERSIDE',
        '2023-05-22', 10000031, 10000030, [], 21, 10.0, 1, 4, 2, 2),
    _Row(10000034, 'Ziad Amin', 'زياد أمين', 'Shift Supervisor',
        'مشرف وردية', 'Operations Department', 'إدارة العمليات', 'HARBOUR', 'HARBOUR',
        '2022-11-30', 10000031, 10000030, [], 21, 8.5, 2, 5, 1, 2),
    _Row(10000035, 'Rana Ibrahim', 'رنا إبراهيم', 'Guest Services Agent',
        'موظف خدمة عملاء', 'Reception Department', 'إدارة الاستقبال', 'RIVERSIDE', 'RIVERSIDE',
        '2024-02-12', 10000031, 10000030, [], 21, 14.5, 0, 3, 2, 2),
    _Row(10000036, 'Hossam Gamal', 'حسام جمال', 'Guest Services Agent',
        'موظف خدمة عملاء', 'Reception Department', 'إدارة الاستقبال', 'HARBOUR', 'HARBOUR',
        '2024-06-01', 10000031, 10000030, [], 21, 16.0, 0, 2, 1, 2),
    _Row(10000037, 'Aya Mahmoud', 'آية محمود', 'Cashier',
        'أمين صندوق', 'Cashier Department', 'إدارة الخزينة', 'RIVERSIDE', 'RIVERSIDE',
        '2023-10-15', 10000031, 10000030, [], 21, 11.5, 1, 4, 2, 2),

    // Maintenance
    _Row(10000040, 'Tamer Kamal', 'تامر كمال', 'Maintenance Manager',
        'مدير الصيانة', 'Maintenance Department', 'إدارة الصيانة', 'RIVERSIDE', 'RIVERSIDE',
        '2020-08-24', 10000030, 10000001, [], 24, 13.0, 3, 11, 1, 2),
    _Row(10000041, 'Ahmed Sabry', 'أحمد صبري', 'HVAC Technician',
        'فني تكييف', 'Maintenance Department', 'إدارة الصيانة', 'RIVERSIDE', 'RIVERSIDE',
        '2022-04-18', 10000040, 10000030, [], 21, 9.5, 2, 9, 3, 2),
    _Row(10000042, 'Mahmoud Refaat', 'محمود رفعت', 'Electrician',
        'كهربائي', 'Maintenance Department', 'إدارة الصيانة', 'HARBOUR', 'HARBOUR',
        '2021-12-09', 10000040, 10000030, [], 21, 7.0, 2, 13, 2, 2),
    _Row(10000043, 'Sara Lotfy', 'سارة لطفي', 'Facilities Coordinator',
        'منسق مرافق', 'Maintenance Department', 'إدارة الصيانة', 'RIVERSIDE', 'RIVERSIDE',
        '2023-07-03', 10000040, 10000030, [], 21, 15.0, 1, 5, 1, 2),
    _Row(10000044, 'Khaled Nasser', 'خالد ناصر', 'Plumber',
        'سباك', 'Maintenance Department', 'إدارة الصيانة', 'RIVERSIDE', 'RIVERSIDE',
        '2024-03-27', 10000040, 10000030, [], 21, 17.0, 0, 6, 2, 2),

    // IT
    _Row(10000050, 'Nadia Farouk', 'نادية فاروق', 'IT Manager',
        'مدير تكنولوجيا المعلومات', 'IT Department', 'إدارة تكنولوجيا المعلومات',
        'HQ', 'Company', '2020-10-05', 10000001, null, [], 24, 16.0, 3, 7, 1, 2),
    _Row(10000051, 'Bassem Nagy', 'باسم ناجي', 'Systems Engineer',
        'مهندس نظم', 'IT Department', 'إدارة تكنولوجيا المعلومات', 'HQ', 'Company',
        '2022-01-17', 10000050, 10000001, [], 21, 13.0, 2, 8, 2, 2),
    _Row(10000052, 'Menna Ashraf', 'منة أشرف', 'Software Engineer',
        'مهندس برمجيات', 'IT Department', 'إدارة تكنولوجيا المعلومات', 'HQ', 'Company',
        '2023-09-11', 10000050, 10000001, [], 21, 10.5, 1, 4, 1, 2),
    _Row(10000053, 'Fady Samir', 'فادي سمير', 'IT Support Specialist',
        'أخصائي دعم فني', 'IT Department', 'إدارة تكنولوجيا المعلومات', 'RIVERSIDE',
        'RIVERSIDE', '2024-05-20', 10000050, 10000001, [], 21, 18.0, 0, 3, 3, 2),

    // Leasing
    _Row(10000060, 'Injy Halim', 'إنجي حليم', 'Leasing Manager',
        'مدير التأجير', 'Leasing Department', 'إدارة التأجير', 'RIVERSIDE', 'RIVERSIDE',
        '2020-06-15', 10000001, null, [], 24, 15.0, 3, 6, 1, 2),
    _Row(10000061, 'Amr Wagdy', 'عمرو وجدي', 'Leasing Executive',
        'تنفيذي تأجير', 'Leasing Department', 'إدارة التأجير', 'RIVERSIDE', 'RIVERSIDE',
        '2022-08-08', 10000060, 10000001, [], 21, 12.0, 2, 5, 2, 2),
    _Row(10000062, 'Yara Sameh', 'يارا سامح', 'Leasing Executive',
        'تنفيذي تأجير', 'Leasing Department', 'إدارة التأجير', 'HARBOUR', 'HARBOUR',
        '2023-02-13', 10000060, 10000001, [], 21, 9.0, 1, 4, 1, 2),
    _Row(10000063, 'Hazem Selim', 'حازم سليم', 'Marketing Executive',
        'تنفيذي تسويق', 'Marketing Department', 'إدارة التسويق', 'RIVERSIDE', 'RIVERSIDE',
        '2023-11-27', 10000060, 10000001, [], 21, 13.5, 1, 3, 2, 2),
    _Row(10000064, 'Farida Zaki', 'فريدة زكي', 'Events Coordinator',
        'منسق فعاليات', 'Events Department', 'إدارة الفعاليات', 'RIVERSIDE', 'RIVERSIDE',
        '2024-04-02', 10000060, 10000001, [], 21, 16.5, 0, 7, 1, 2),

    // Security
    _Row(10000070, 'Wael Abdelrahman', 'وائل عبدالرحمن', 'Security Manager',
        'مدير الأمن', 'internal security', 'الأمن الداخلي', 'RIVERSIDE', 'RIVERSIDE',
        '2019-11-11', 10000001, null, [], 24, 14.5, 3, 14, 1, 2),
    _Row(10000071, 'Sameh Roushdy', 'سامح رشدي', 'Security Supervisor',
        'مشرف أمن', 'internal security', 'الأمن الداخلي', 'RIVERSIDE', 'RIVERSIDE',
        '2021-03-22', 10000070, 10000001, [], 21, 8.0, 2, 16, 3, 2),
    _Row(10000072, 'Gamal Sedky', 'جمال صدقي', 'Security Officer',
        'ضابط أمن', 'internal security', 'الأمن الداخلي', 'RIVERSIDE', 'RIVERSIDE',
        '2022-05-30', 10000071, 10000070, [], 21, 6.5, 2, 18, 2, 2),
    _Row(10000073, 'Ibrahim Fathy', 'إبراهيم فتحي', 'Security Officer',
        'ضابط أمن', 'internal security', 'الأمن الداخلي', 'HARBOUR', 'HARBOUR',
        '2022-07-25', 10000071, 10000070, [], 21, 10.0, 1, 15, 2, 2),
    _Row(10000074, 'Mostafa Helmy', 'مصطفى حلمي', 'Security Officer',
        'ضابط أمن', 'internal security', 'الأمن الداخلي', 'RIVERSIDE', 'RIVERSIDE',
        '2023-01-16', 10000071, 10000070, [], 21, 12.5, 1, 12, 1, 2),
    _Row(10000075, 'Amir Zaher', 'أمير زاهر', 'Safety Officer',
        'ضابط سلامة', 'Safety Department', 'إدارة السلامة', 'RIVERSIDE', 'RIVERSIDE',
        '2023-06-19', 10000070, 10000001, [], 21, 11.0, 1, 9, 2, 2),
    _Row(10000076, 'Reem Adly', 'ريم عدلي', 'Warehouse Keeper',
        'أمين مخزن', 'Warehouses Department', 'إدارة المخازن', 'HARBOUR', 'HARBOUR',
        '2024-07-08', 10000070, 10000001, [], 21, 19.0, 0, 4, 1, 2),
  ];
}

/// A single seeded employee. Kept as a positional record so the table above
/// stays compact and scannable.
class _Row {
  const _Row(
    this.code,
    this.en,
    this.ar,
    this.title,
    this.titleAr,
    this.dept,
    this.deptAr,
    this.location,
    this.costCenter,
    this.hireDate,
    this.n1,
    this.n2,
    this.groups,
    this.eligibility,
    this.leaveBalance,
    this.carryForward,
    this.overtime,
    this.missingPunch,
    this.emergency,
  );

  final int code;
  final String en;
  final String ar;
  final String title;
  final String titleAr;
  final String dept;
  final String deptAr;
  final String location;
  final String costCenter;
  final String hireDate;
  final int? n1;
  final int? n2;
  final List<String> groups;
  final int eligibility;
  final double leaveBalance;
  final double carryForward;
  final double overtime;
  final int missingPunch;
  final double emergency;
}
