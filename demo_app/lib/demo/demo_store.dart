import 'package:flutter/foundation.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';
import 'package:hrms_demo/data/models/missingpunching_request_model.dart';
import 'package:hrms_demo/data/models/overtime_request_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/demo/demo_seed.dart';

/// The demo's entire backend: a mutable in-memory store.
///
/// The production app talks to Supabase through 16 repository interfaces. In
/// the demo those interfaces are implemented against this object instead, so
/// **no network call is made from anywhere in the application**. Writes mutate
/// this store and are visible immediately; [reset] restores the seeded state.
///
/// Deliberately a singleton: several repositories and the role switcher all
/// need to see the same data, and the demo has no notion of separate sessions.
class DemoStore extends ChangeNotifier {
  DemoStore._() {
    reset();
  }

  static final DemoStore instance = DemoStore._();

  // ── State ────────────────────────────────────────────────────────────────
  late List<UserModel> _users;
  late List<LeaveRequestModel> _leave;
  late List<OvertimeRequestModel> _overtime;
  late List<MissingpunchingRequestModel> _missingPunch;

  /// Code of the employee the demo is currently "signed in" as.
  late int _currentUserCode;

  int _nextRequestId = 5000;

  // ── Accessors ────────────────────────────────────────────────────────────
  List<UserModel> get users => List.unmodifiable(_users);
  List<LeaveRequestModel> get leaveRequests => List.unmodifiable(_leave);
  List<OvertimeRequestModel> get overtimeRequests => List.unmodifiable(_overtime);
  List<MissingpunchingRequestModel> get missingPunchRequests =>
      List.unmodifiable(_missingPunch);

  int get currentUserCode => _currentUserCode;
  UserModel get currentUser => userByCode(_currentUserCode)!;

  int get nextRequestId => _nextRequestId++;

  UserModel? userByCode(int? code) {
    if (code == null) return null;
    for (final u in _users) {
      if (u.id == code) return u;
    }
    return null;
  }

  /// Direct reports of [managerCode] (N+1 == managerCode).
  List<UserModel> directReports(int managerCode) =>
      _users.where((u) => u.n1 == managerCode).toList();

  /// Second-level reports (N+2 == managerCode).
  List<UserModel> indirectReports(int managerCode) =>
      _users.where((u) => u.n2 == managerCode).toList();

  /// Everyone below [managerCode] in the tree, at any depth.
  List<UserModel> allSubordinates(int managerCode) {
    final out = <UserModel>[];
    final queue = <int>[managerCode];
    final seen = <int>{managerCode};
    while (queue.isNotEmpty) {
      final code = queue.removeAt(0);
      for (final u in _users.where((u) => u.n1 == code)) {
        if (u.id != null && seen.add(u.id!)) {
          out.add(u);
          queue.add(u.id!);
        }
      }
    }
    return out;
  }

  /// Subordinates at depth 3 or greater (excludes direct and second level).
  List<UserModel> deepSubordinates(int managerCode) {
    final direct = directReports(managerCode).map((u) => u.id).toSet();
    final indirect = indirectReports(managerCode).map((u) => u.id).toSet();
    return allSubordinates(managerCode)
        .where((u) => !direct.contains(u.id) && !indirect.contains(u.id))
        .toList();
  }

  // ── Mutations ────────────────────────────────────────────────────────────
  void switchUser(int code) {
    if (userByCode(code) == null) return;
    _currentUserCode = code;
    notifyListeners();
  }

  void upsertUser(UserModel user) {
    final i = _users.indexWhere((u) => u.id == user.id);
    if (i >= 0) {
      _users[i] = user;
    } else {
      _users.add(user);
    }
    notifyListeners();
  }

  void addLeaveRequest(LeaveRequestModel r) {
    _leave.insert(0, r);
    notifyListeners();
  }

  void replaceLeaveRequest(int id, LeaveRequestModel Function(LeaveRequestModel) f) {
    final i = _leave.indexWhere((r) => r.id == id);
    if (i >= 0) {
      _leave[i] = f(_leave[i]);
      notifyListeners();
    }
  }

  void removeLeaveRequest(int id) {
    _leave.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void addOvertimeRequest(OvertimeRequestModel r) {
    _overtime.insert(0, r);
    notifyListeners();
  }

  void addMissingPunchRequest(MissingpunchingRequestModel r) {
    _missingPunch.insert(0, r);
    notifyListeners();
  }

  // ── Seeding ──────────────────────────────────────────────────────────────
  /// Restores the store to its initial seeded state. Bound to the demo's
  /// "reset data" control.
  void reset() {
    _users = DemoSeed.employees();
    _currentUserCode = DemoSeed.defaultUserCode;
    _nextRequestId = 5000;
    _leave = _seedLeave();
    _overtime = [];
    _missingPunch = [];
    notifyListeners();
  }

  /// Leave requests seeded across every workflow state, so no screen in the
  /// product renders empty: pending at N+1, escalated to N+2, waiting on HR,
  /// approved, and declined.
  List<LeaveRequestModel> _seedLeave() {
    final now = DateTime.now();
    DateTime d(int offset) => DateTime(now.year, now.month, now.day + offset);

    LeaveRequestModel make({
      required int id,
      required int userId,
      required int from,
      required int to,
      required String type,
      required String status,
      String? approver,
      String? decline,
    }) {
      final u = userByCode(userId);
      final n1 = userByCode(u?.n1);
      final n2 = userByCode(u?.n2);
      return LeaveRequestModel(
        id: id,
        userId: userId,
        dateFrom: d(from),
        dateTo: d(to),
        leaveType: type,
        status: status,
        createdAt: d(from - 7),
        currentApprover: approver,
        n1Code: u?.n1,
        n2Code: u?.n2,
        n1EnglishName: n1?.englishName,
        n1ArabicName: n1?.arabicName,
        n2EnglishName: n2?.englishName,
        n2ArabicName: n2?.arabicName,
        lastActionAt: d(from - 5),
        userEnglishName: u?.englishName,
        userArabicName: u?.arabicName,
        userTitle: u?.title,
        userEnglishTitle: u?.englishTitle,
        userDepartment: u?.department,
        userEnglishDepartment: u?.englishDepartment,
        userHireDate: u?.hireDate,
        numberOfDays: (to - from + 1).toDouble(),
        userLeaveBalance: u?.leaveBalance,
        userOvertimeBalance: u?.overtimeBalance,
        userShiftHours: u?.shiftHours,
        declineReason: decline,
        requestType: 'leave',
        cancelled: false,
      );
    }

    return [
      // Pending on the current user's manager — the "needs your approval" case.
      make(id: 4001, userId: 10000032, from: 6, to: 8, type: 'Annual', status: 'pending', approver: 'N+1'),
      make(id: 4002, userId: 10000033, from: 10, to: 10, type: 'Emergency', status: 'pending', approver: 'N+1'),
      make(id: 4003, userId: 10000037, from: 14, to: 18, type: 'Annual', status: 'pending', approver: 'N+1'),
      // Escalated one level up.
      make(id: 4004, userId: 10000034, from: 3, to: 4, type: 'Annual', status: 'pending', approver: 'N+2'),
      make(id: 4005, userId: 10000041, from: 21, to: 25, type: 'Annual', status: 'pending', approver: 'N+2'),
      // Sitting with HR.
      make(id: 4006, userId: 10000042, from: -2, to: 1, type: 'Sick', status: 'pending', approver: 'HR'),
      make(id: 4007, userId: 10000072, from: 30, to: 34, type: 'Annual', status: 'pending', approver: 'HR'),
      // Settled.
      make(id: 4008, userId: 10000032, from: -20, to: -18, type: 'Annual', status: 'approved'),
      make(id: 4009, userId: 10000035, from: -30, to: -30, type: 'Emergency', status: 'approved'),
      make(id: 4010, userId: 10000051, from: -12, to: -9, type: 'Annual', status: 'approved'),
      make(id: 4011, userId: 10000036, from: -40, to: -36, type: 'Annual', status: 'declined',
          decline: 'Coverage unavailable for the requested week.'),
      make(id: 4012, userId: 10000073, from: -8, to: -7, type: 'Sick', status: 'approved'),
      make(id: 4013, userId: 10000061, from: 40, to: 44, type: 'Annual', status: 'pending', approver: 'N+1'),
      make(id: 4014, userId: 10000064, from: -5, to: -5, type: 'Emergency', status: 'approved'),
    ];
  }
}
