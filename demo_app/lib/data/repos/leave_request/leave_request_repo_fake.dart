// In-memory stand-in for LeaveRequestsRepo, backed by DemoStore.
//
// This is the repository the demo leans on hardest: leave is the request type
// the case study describes, and the approval chain is the thing worth showing.
// So unlike the generated scaffolds, every read and every mutation here is real
// — a request you file appears in My Requests, shows up in your manager's Team
// queue, and moves to Processed once they act on it.
//
// Production resolves the caller server-side from the auth session (which is
// why `getLeaveRequestsPage` takes no user code). The demo resolves it from
// `DemoStore.currentUserCode`, which the role switcher drives.

import 'dart:typed_data';

import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/core/constants/approver_codes.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/models/user_request_row.dart';
import 'package:hrms_demo/data/repos/leave_request/bulk_leave_result.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_requests_query.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeLeaveRequestsRepo implements LeaveRequestsRepo {
  FakeLeaveRequestsRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  // ── Helpers ──────────────────────────────────────────────────────────────

  int get _me => store.currentUserCode;

  bool _isHr(int code) => ApproverCodes.hrCodes.contains(code.toString());

  String _approver(LeaveRequestModel r) => (r.currentApprover ?? '').toLowerCase();
  String _status(LeaveRequestModel r) => (r.status ?? '').toLowerCase();

  bool _isPending(LeaveRequestModel r) => _status(r) == 'pending' && r.cancelled != true;

  /// Whether [code] is the approver this request is currently waiting on.
  ///
  /// Mirrors the server's routing: `n1`/`n2` match the request's own chain,
  /// and `hr` matches anyone in the HR group rather than a specific person.
  bool _awaitingActionBy(LeaveRequestModel r, int code) {
    if (!_isPending(r)) return false;
    switch (_approver(r)) {
      case 'n1':
        return r.n1Code == code;
      case 'n2':
        return r.n2Code == code;
      case 'hr':
        return _isHr(code);
      default:
        return false;
    }
  }

  /// Rows for a scope, newest first.
  List<LeaveRequestModel> _scopeRows(LeaveRequestScope scope) {
    final me = _me;
    final all = store.leaveRequests;
    final rows = switch (scope) {
      LeaveRequestScope.my => all.where((r) => r.userId == me),
      LeaveRequestScope.team => all.where((r) => _awaitingActionBy(r, me)),
      LeaveRequestScope.processed =>
        all.where((r) => r.id != null && store.hasActedOn(r.id!, me)),
    }.toList();

    rows.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return rows;
  }

  bool _matchesQuery(LeaveRequestModel r, LeaveRequestsQuery q) {
    if (q.status != 'all' && _status(r) != q.status.toLowerCase()) return false;

    if (q.month != null) {
      final m = q.month!;
      final d = r.dateFrom;
      if (d == null || d.year != m.year || d.month != m.month) return false;
    }

    final term = q.search.trim().toLowerCase();
    if (term.isEmpty) return true;
    final name = q.locale == 'ar' ? (r.userArabicName ?? '') : (r.userEnglishName ?? '');
    return name.toLowerCase().contains(term) ||
        (r.userId.toString()).contains(term) ||
        r.leaveType.toLowerCase().contains(term);
  }

  int _compare(LeaveRequestModel a, LeaveRequestModel b, LeaveRequestsQuery q) {
    int c;
    switch (q.sortKey) {
      case LeaveRequestSortKey.createdAt:
        c = (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0));
      case LeaveRequestSortKey.dateFrom:
        c = (a.dateFrom ?? DateTime(0)).compareTo(b.dateFrom ?? DateTime(0));
      case LeaveRequestSortKey.dateTo:
        c = (a.dateTo ?? DateTime(0)).compareTo(b.dateTo ?? DateTime(0));
      case LeaveRequestSortKey.leaveType:
        c = a.leaveType.compareTo(b.leaveType);
      case LeaveRequestSortKey.numOfDays:
        c = (a.numberOfDays ?? 0).compareTo(b.numberOfDays ?? 0);
      case LeaveRequestSortKey.status:
        c = _status(a).compareTo(_status(b));
      case LeaveRequestSortKey.currentApprover:
        c = _approver(a).compareTo(_approver(b));
      case LeaveRequestSortKey.userId:
        c = a.userId.compareTo(b.userId);
      case LeaveRequestSortKey.employeeName:
        final an = q.locale == 'ar' ? (a.userArabicName ?? '') : (a.userEnglishName ?? '');
        final bn = q.locale == 'ar' ? (b.userArabicName ?? '') : (b.userEnglishName ?? '');
        c = an.compareTo(bn);
    }
    return q.sortAscending ? c : -c;
  }

  // ── Reads ────────────────────────────────────────────────────────────────

  @override
  Future<PagedResult<UserRequestRow>> getLeaveRequestsPage(
    LeaveRequestsQuery query, {
    required int offset,
    required int limit,
  }) async {
    final filtered = _scopeRows(query.scope).where((r) => _matchesQuery(r, query)).toList()
      ..sort((a, b) => _compare(a, b, query));

    final me = _me;
    final hasActionable = filtered.any((r) => _awaitingActionBy(r, me));

    final page = offset >= filtered.length
        ? const <LeaveRequestModel>[]
        : filtered.skip(offset).take(limit).toList();

    return PagedResult<UserRequestRow>(
      items: page.map<UserRequestRow>(LeaveRequestRow.new).toList(),
      totalCount: filtered.length,
      hasActionable: hasActionable,
    );
  }

  @override
  Future<List<DateTime>> getLeaveRequestMonths(LeaveRequestScope scope) async {
    final months = <DateTime>{};
    for (final r in _scopeRows(scope)) {
      final d = r.dateFrom;
      if (d != null) months.add(DateTime(d.year, d.month));
    }
    final list = months.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  @override
  Future<bool> hasAnyRequests(LeaveRequestScope scope, int userCode) async =>
      _scopeRows(scope).isNotEmpty;

  @override
  Future<List<LeaveRequestModel>> getMyLeaveRequests(int userCode) async =>
      store.leaveRequests.where((r) => r.userId == userCode).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

  @override
  Future<List<LeaveRequestModel>> getRequestsToApprove(int approverCode) async =>
      store.leaveRequests.where((r) => _awaitingActionBy(r, approverCode)).toList()
        ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));

  @override
  Future<List<LeaveRequestModel>> getProcessedRequests(int approverCode) async =>
      store.leaveRequests
          .where((r) => r.id != null && store.hasActedOn(r.id!, approverCode))
          .toList()
        ..sort((a, b) => (b.lastActionAt ?? DateTime(0)).compareTo(b.lastActionAt ?? DateTime(0)));

  @override
  Future<List<LeaveRequestModel>> getRequestsByMonth(int userCode, DateTime month) async =>
      store.leaveRequests
          .where((r) =>
              r.userId == userCode &&
              r.dateFrom != null &&
              r.dateFrom!.year == month.year &&
              r.dateFrom!.month == month.month)
          .toList();

  @override
  Future<bool> hasMyRequests(int userCode) async =>
      store.leaveRequests.any((r) => r.userId == userCode);

  @override
  Future<bool> hasTeamRequests(int approverCode) async =>
      store.leaveRequests.any((r) => _awaitingActionBy(r, approverCode));

  @override
  Future<bool> hasProcessedRequests(int approverCode) async =>
      store.leaveRequests.any((r) => r.id != null && store.hasActedOn(r.id!, approverCode));

  // ── Mutations ────────────────────────────────────────────────────────────

  @override
  Future<int> submitLeaveRequest(LeaveRequestModel request) async {
    final id = store.nextRequestId;
    final author = store.userByCode(request.userId) ?? store.currentUser;
    final n1 = store.userByCode(author.n1);
    final n2 = store.userByCode(author.n2);

    // Hydrate the columns the list screens read. Production fills these from a
    // join plus the submit RPC's defaults; the request the UI hands us carries
    // only what the form collected.
    final hydrated = request.copyWith(
      id: id,
      status: 'pending',
      currentApprover: 'n1',
      createdAt: DateTime.now(),
      lastActionAt: DateTime.now(),
      n1Code: author.n1,
      n2Code: author.n2,
      n1EnglishName: n1?.englishName,
      n1ArabicName: n1?.arabicName,
      n2EnglishName: n2?.englishName,
      n2ArabicName: n2?.arabicName,
      userEnglishName: author.englishName,
      userArabicName: author.arabicName,
      userTitle: author.title,
      userEnglishTitle: author.englishTitle,
      userDepartment: author.department,
      userEnglishDepartment: author.englishDepartment,
      userHireDate: author.hireDate,
      userLeaveBalance: author.leaveBalance,
      userOvertimeBalance: author.overtimeBalance,
      userShiftHours: author.shiftHours,
      requestType: request.requestType ?? 'leave',
      cancelled: false,
    );

    store.addLeaveRequest(hydrated);
    return id;
  }

  @override
  Future<void> approveRequest(int requestId, String approverTitle, int approverCode) async {
    store.replaceLeaveRequest(requestId, (r) {
      // Walk the chain the way the server does: n1 -> n2 -> hr -> approved.
      // Escalating to n2 only makes sense when the employee actually has one.
      final next = switch (_approver(r)) {
        'n1' => r.n2Code != null ? 'n2' : 'hr',
        'n2' => 'hr',
        _ => null,
      };
      return r.copyWith(
        status: next == null ? 'approved' : 'pending',
        currentApprover: next ?? r.currentApprover,
        lastActionAt: DateTime.now(),
      );
    });
    store.recordAction(requestId, approverCode);
  }

  @override
  Future<void> declineRequest(
    int requestId,
    String reason,
    String currentApprover,
    int approverCode,
  ) async {
    store.replaceLeaveRequest(
      requestId,
      (r) => r.copyWith(
        status: 'declined',
        declineReason: reason,
        lastActionAt: DateTime.now(),
      ),
    );
    store.recordAction(requestId, approverCode);
  }

  @override
  Future<void> cancelRequest(int requestId) async {
    store.replaceLeaveRequest(
      requestId,
      (r) => r.copyWith(status: 'cancelled', cancelled: true, lastActionAt: DateTime.now()),
    );
  }

  @override
  Future<void> removeRequest(int requestId) async => store.removeLeaveRequest(requestId);

  @override
  Future<void> removeRequestForN1(int requestId) async => store.removeLeaveRequest(requestId);

  @override
  Future<void> uploadSickNote(
    List<Uint8List> sickNotes,
    List<String>? sickNoteFileNames,
    int requestId,
  ) async {
    // No object store in the demo; the attachment is accepted and discarded.
  }

  @override
  Future<List<int>> submitBulkLeaveRequests({
    required List<UserModel> employees,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String leaveType,
    required double numberOfDays,
    required int hrApproverCode,
  }) async {
    final ids = <int>[];
    for (final e in employees) {
      final id = await submitLeaveRequest(
        LeaveRequestModel(
          userId: e.id ?? 0,
          dateFrom: dateFrom,
          dateTo: dateTo,
          leaveType: leaveType,
          numberOfDays: numberOfDays,
        ),
      );
      // This variant auto-approves, skipping the chain entirely.
      store.replaceLeaveRequest(
        id,
        (r) => r.copyWith(status: 'approved', currentApprover: 'hr'),
      );
      store.recordAction(id, hrApproverCode);
      ids.add(id);
    }
    return ids;
  }

  @override
  Future<BulkLeaveSubmissionResult> submitBulkLeaveRequestsForApproval({
    required List<UserModel> employees,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String leaveType,
    required double numberOfDays,
  }) async {
    final ids = <int>[];
    for (final e in employees) {
      ids.add(await submitLeaveRequest(
        LeaveRequestModel(
          userId: e.id ?? 0,
          dateFrom: dateFrom,
          dateTo: dateTo,
          leaveType: leaveType,
          numberOfDays: numberOfDays,
        ),
      ));
    }
    return BulkLeaveSubmissionResult(createdIds: ids, failures: const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
