/// The demo's whole backend, in memory.
///
/// In production the cashier app talks to a self-hosted Postgres where every
/// rule lives in SQL functions (`sell_tickets`, `confirm_payment`,
/// `validate_ticket`, `close_shift`, …). The demo keeps the app's repositories
/// unchanged and hands them this object instead of the database client: it
/// answers the same function names with the same JSON, and raises the same
/// error codes, so the app's own parsers and error messages run as they do in
/// production. **Nothing here makes a network call.**
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/venue_day.dart';
import '../features/sell/data/peak_schedule.dart';

part 'backend_rpc.dart';
part 'backend_seed.dart';

// ── Errors with the shapes the repositories match on ─────────────────────────

/// A refused call: what Postgres raises with `raise exception '<key>'`.
class PostgrestException implements Exception {
  const PostgrestException({required this.message, this.code = 'P0001', this.details});

  final String message;
  final String? code;
  final Object? details;

  @override
  String toString() => 'PostgrestException($code, $message)';
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class AuthRetryableFetchException extends AuthException {
  const AuthRetryableFetchException() : super('unreachable');
}

/// No answer: the demo bar's "server outage" switch is on.
class ServerUnreachable implements Exception {
  const ServerUnreachable();

  @override
  String toString() => 'ServerUnreachable';
}

enum CountOption { exact }

class CountResponse {
  const CountResponse(this.count);

  final int count;
}

// ── The client surface the repositories use ──────────────────────────────────

class DemoBackend {
  DemoBackend._() {
    reset();
    // The unpaid-order job (pg_cron every minute in production).
    Timer.periodic(const Duration(seconds: 20), (_) => _cancelUnpaid());
  }

  static final DemoBackend instance = DemoBackend._();

  /// The default password of every seeded account.
  static const password = 'demo1234';

  final _random = Random();

  // Session ------------------------------------------------------------------
  String? _userId;
  final _signedOut = StreamController<void>.broadcast();

  String? get currentUserId => _userId;
  Stream<void> get signedOutEvents => _signedOut.stream;

  // Demo switches ------------------------------------------------------------

  /// The server can't be reached: every call fails as a dead server would.
  final ValueNotifier<bool> outage = ValueNotifier(false);

  /// The counter's printer is jammed: printing fails and the retry path shows.
  final ValueNotifier<bool> printerJammed = ValueNotifier(false);

  /// Bumped whenever a scan is recorded, for the live dashboard.
  final _scanEvents = StreamController<void>.broadcast();
  Stream<void> get scanEvents => _scanEvents.stream;

  /// Bumped on any write, so the demo bar's lists refresh.
  final ValueNotifier<int> revision = ValueNotifier(0);

  // Tables -------------------------------------------------------------------
  late Map<String, Object?> settings;
  final staff = <DemoStaff>[];
  final controllers = <_Controller>[];
  final gates = <_Gate>[];
  final counters = <_Counter>[];
  final types = <_Type>[];
  final shifts = <_Shift>[];
  final orders = <_Order>[];
  final tickets = <_Ticket>[];
  final tips = <_Tip>[];
  final scans = <_Scan>[];
  final actions = <_Action>[];
  final pool = <_PoolCode>[];
  final commands = <_Command>[];
  int _seq = 1;
  int _orderNumber = 1000;
  int _shiftNumber = 200;

  String _id(String prefix) => '$prefix-${_seq++}';

  void reset() {
    for (final t in <List<Object>>[
      staff, controllers, gates, counters, types, shifts, orders, tickets, tips, scans, actions, pool, commands,
    ]) {
      t.clear();
    }
    _seq = 1;
    _orderNumber = 1000;
    _shiftNumber = 200;
    outage.value = false;
    printerJammed.value = false;
    _seed(this);
    _changed();
  }

  void _changed() => revision.value++;

  Future<void> _call() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (outage.value) throw const ServerUnreachable();
  }

  // Auth -----------------------------------------------------------------------

  Future<void> signIn(String email, String password) async {
    await _call();
    final username = email.split('@').first;
    final s = staff.where((x) => x.username == username).firstOrNull;
    if (s == null || s.password != password) throw const AuthException('invalid_credentials');
    _userId = s.id;
    s.lastSignInAt = _now;
  }

  Future<void> signOut() async {
    _userId = null;
    _signedOut.add(null);
  }

  // PostgREST-shaped reads -------------------------------------------------------

  DemoQuery from(String table) => DemoQuery._(this, table);

  List<Map<String, dynamic>> _table(String table) => switch (table) {
        'settings' => [Map<String, dynamic>.of(settings)],
        'staff' => [
            for (final s in staff)
              if (s.active)
                {'id': s.id, 'full_name': s.fullName, 'username': s.username, 'role': s.role, 'language': s.language},
          ],
        'shifts' => [
            for (final s in shifts)
              {
                'id': s.id,
                'number': s.number,
                'cashier_id': s.cashierId,
                'counter_id': s.counterId,
                'status': s.status,
                'opened_at': _iso(s.openedAt),
                'counter': {'name': _counter(s.counterId)!.name},
              },
          ],
        'counters' => [
            for (final c in counters)
              {
                'id': c.id,
                'name': c.name,
                'active': c.active,
                'printer_ip': c.printerIp,
                'printer_port': c.printerPort,
                'paper_width_mm': c.paperWidthMm,
                'entry_gate_id': c.entryGateId,
                'entry_gate': c.entryGateId == null ? null : {'name': _gate(c.entryGateId)!.name},
              },
          ],
        'ticket_types' => [for (final t in types) t.row()],
        'ticket_actions' => [
            for (final a in actions) {'id': a.id, 'flags': a.flags, 'reviewed_at': a.reviewedAt == null ? null : _iso(a.reviewedAt!)},
          ],
        _ => throw PostgrestException(message: 'unknown table $table', code: '42P01'),
      };

  // RPC ------------------------------------------------------------------------

  Future<T> rpc<T>(String fn, {Map<String, dynamic>? params}) async {
    await _call();
    final result = _dispatch(fn, params ?? const {});
    _changed();
    return result as T;
  }

  // Clock & venue day ----------------------------------------------------------

  DateTime get _now => DateTime.now();

  VenueDay get venueDay => VenueDay(
        start: VenueTime.parse(settings['venue_day_starts_at']! as String),
        closing: VenueTime.parse(settings['closing_time']! as String),
      );

  PeakSchedule get peak => PeakSchedule.fromRow(Map<String, dynamic>.of(settings));

  DateTime get today => venueDay.dayOf(_now);

  int _num(String key) => settings[key]! as int;
  bool _flag(String key) => settings[key]! as bool;

  // Lookups --------------------------------------------------------------------
  DemoStaff? _staff(String? id) => id == null ? null : staff.where((s) => s.id == id).firstOrNull;
  _Counter? _counter(String? id) => id == null ? null : counters.where((c) => c.id == id).firstOrNull;
  _Gate? _gate(String? id) => id == null ? null : gates.where((g) => g.id == id).firstOrNull;
  _Type? _type(String? id) => id == null ? null : types.where((t) => t.id == id).firstOrNull;
  _Shift? _shift(String? id) => id == null ? null : shifts.where((s) => s.id == id).firstOrNull;
  _Order? _order(String? id) => id == null ? null : orders.where((o) => o.id == id).firstOrNull;
  _Ticket? _ticket(String? id) => id == null ? null : tickets.where((t) => t.id == id).firstOrNull;

  DemoStaff _me() {
    final me = _staff(_userId);
    if (me == null || !me.active) throw const PostgrestException(message: 'not_staff');
    return me;
  }

  _Shift? _myOpenShift() =>
      shifts.where((s) => s.cashierId == _userId && s.status == 'open').firstOrNull;

  _Shift _requireMyShift() =>
      _myOpenShift() ?? (throw const PostgrestException(message: 'no_open_shift'));

  void _requireRole(Set<String> roles) {
    if (!roles.contains(_me().role)) throw const PostgrestException(message: 'not_allowed');
  }

  /// A random gate code no live ticket or pool code holds.
  int _newGateCode() {
    final length = _num('gate_code_length');
    final min = pow(10, length - 1).toInt();
    final max = pow(10, length).toInt();
    final taken = {
      for (final t in tickets)
        if (t.status == 'pending' || t.status == 'active') t.gateCode,
      for (final p in pool) p.gateCode,
    };
    while (true) {
      final code = min + _random.nextInt(max - min);
      if (!taken.contains(code)) return code;
    }
  }

  // The unpaid-order job ----------------------------------------------------------

  void _cancelUnpaid() {
    final limit = Duration(minutes: _num('unpaid_order_timeout_min'));
    var any = false;
    for (final o in orders) {
      if (o.status == 'awaiting_payment' && _now.difference(o.createdAt) >= limit) {
        o
          ..status = 'cancelled'
          ..cancelledAt = _now;
        for (final t in tickets.where((t) => t.orderId == o.id)) {
          t.status = 'voided';
        }
        any = true;
      }
    }
    if (any) _changed();
  }

  static String _iso(DateTime d) => d.toUtc().toIso8601String();
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Just enough of the PostgREST query builder for the app's direct table
/// reads: filters, order, limit, single rows and counts.
class DemoQuery implements Future<List<Map<String, dynamic>>> {
  DemoQuery._(this._backend, this._table);

  final DemoBackend _backend;
  final String _table;
  final _filters = <bool Function(Map<String, dynamic>)>[];
  final _orders = <(String, bool)>[];
  int? _limit;

  DemoQuery select([String columns = '*']) => this;

  DemoQuery eq(String column, Object? value) => this.._filters.add((r) => r[column] == value);

  DemoQuery neq(String column, Object? value) => this
    .._filters.add((r) {
      final v = r[column];
      if (value == '{}' && v is List) return v.isNotEmpty;
      return v != value;
    });

  DemoQuery isFilter(String column, Object? value) => this.._filters.add((r) => r[column] == value);

  DemoQuery order(String column, {bool ascending = true}) => this.._orders.add((column, ascending));

  DemoQuery limit(int count) => this.._limit = count;

  Future<List<Map<String, dynamic>>> _run() async {
    await _backend._call();
    var rows = _backend._table(_table).where((r) => _filters.every((f) => f(r))).toList();
    for (final (column, ascending) in _orders.reversed) {
      rows.sort((a, b) {
        final x = a[column], y = b[column];
        final c = x is Comparable && y is Comparable ? x.compareTo(y) : 0;
        return ascending ? c : -c;
      });
    }
    if (_limit != null) rows = rows.take(_limit!).toList();
    return rows;
  }

  Future<Map<String, dynamic>> single() async {
    final rows = await _run();
    if (rows.length != 1) throw const PostgrestException(message: 'not one row', code: 'PGRST116');
    return rows.single;
  }

  Future<Map<String, dynamic>?> maybeSingle() async {
    final rows = await _run();
    return rows.isEmpty ? null : rows.first;
  }

  Future<CountResponse> count([CountOption option = CountOption.exact]) async =>
      CountResponse((await _run()).length);

  @override
  Stream<List<Map<String, dynamic>>> asStream() => _run().asStream();

  @override
  Future<List<Map<String, dynamic>>> catchError(Function onError, {bool Function(Object error)? test}) =>
      _run().catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {Function? onError}) =>
      _run().then(onValue, onError: onError);

  @override
  Future<List<Map<String, dynamic>>> timeout(Duration timeLimit,
          {FutureOr<List<Map<String, dynamic>>> Function()? onTimeout}) =>
      _run().timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<Map<String, dynamic>>> whenComplete(FutureOr<void> Function() action) =>
      _run().whenComplete(action);
}

// ── Rows ─────────────────────────────────────────────────────────────────────

/// A staff row; public so the demo's entry point can set a language.
class DemoStaff {
  DemoStaff(this.id, this.fullName, this.username, this.role, {this.active = true});

  final String id;
  String fullName;
  String username;
  String role;
  String language = 'en';
  bool active;
  String password = DemoBackend.password;
  DateTime? lastSignInAt;
}

class _Controller {
  _Controller(this.id, this.name, this.model, this.ip);

  final String id;
  String name;
  String? model;
  String? ip;
  int port = 4370;
  int doorCount = 4;
}

class _Gate {
  _Gate(this.id, this.name, {this.direction = 'entry', this.controllerId, this.doorNumber});

  final String id;
  String name;
  String direction;
  String? controllerId;
  int? doorNumber;
  int openSeconds = 3;
  String? reader = 'QR';
  bool enabled = true;
  DateTime? lastSeenAt;
}

class _Counter {
  _Counter(this.id, this.name, this.printerIp, this.entryGateId);

  final String id;
  String name;
  String? printerIp;
  int printerPort = 9100;
  int paperWidthMm = 80;
  String? entryGateId;
  bool active = true;
}

class _Type {
  _Type(this.id, this.nameAr, this.nameEn, this.price, this.sortOrder,
      {this.entries = 1, this.validityKind = 'same_day', this.validityHours, this.salePeriod = 'always'});

  final String id;
  String nameAr;
  String nameEn;
  int price;
  int entries;
  String validityKind;
  int? validityHours;
  bool active = true;
  int sortOrder;
  String salePeriod;

  Map<String, dynamic> row() => {
        'id': id,
        'name_ar': nameAr,
        'name_en': nameEn,
        'price_piastres': price,
        'entries_allowed': entries,
        'validity_kind': validityKind,
        'validity_hours': validityHours,
        'active': active,
        'sort_order': sortOrder,
        'sale_period': salePeriod,
      };
}

class _Shift {
  _Shift(this.id, this.number, this.cashierId, this.counterId, this.openedAt, this.openingCash);

  final String id;
  final int number;
  final String cashierId;
  final String counterId;
  final DateTime openedAt;
  final int openingCash;
  String status = 'open';
  DateTime? closedAt;
  int? countedCash;
  String? approvedBy;
  DateTime? approvedAt;
  String? approvalComment;
}

class _Order {
  _Order(this.id, this.number, this.shiftId, this.total, this.createdAt);

  final String id;
  final int number;
  final String shiftId;
  final int total;
  final DateTime createdAt;
  String status = 'awaiting_payment';
  String? method;
  int? amountReceived;
  DateTime? paidAt;
  DateTime? cancelledAt;
  String? clientId;
}

class _Ticket {
  _Ticket(this.id, this.orderId, this.typeId, this.price, this.homeGateId, this.gateCode, this.validFrom,
      this.validUntil, this.entriesLeft);

  final String id;
  final String orderId;
  final String typeId;
  final int price;
  final String? homeGateId;
  final int gateCode;
  final DateTime validFrom;
  final DateTime validUntil;
  int entriesLeft;
  String status = 'pending';
  int printCount = 1;
  int reactivationCount = 0;
}

class _Tip {
  _Tip(this.id, this.shiftId, this.orderId, this.amount, this.source, this.createdAt);

  final String id;
  final String shiftId;
  final String? orderId;
  final int amount;
  final String source;
  final DateTime createdAt;
}

class _Scan {
  _Scan(this.id, this.ticketId, this.gateId, this.result, this.reason, this.scannedAt,
      {this.poolCode = false, this.poolGateCode});

  final String id;
  final String? ticketId;
  final String gateId;
  final String result;
  final String? reason;
  final DateTime scannedAt;
  final bool poolCode;

  /// The pool code a scan let in before its sale reached the server.
  final int? poolGateCode;
}

class _Action {
  _Action(this.id, this.actorId, this.shiftId, this.action, this.createdAt,
      {this.ticketId, this.orderId, this.gateId, this.reasonCode, this.reasonText, this.amount, this.details});

  final String id;
  final String? actorId;
  final String? shiftId;
  final String action;
  final DateTime createdAt;
  final String? ticketId;
  final String? orderId;
  final String? gateId;
  final String? reasonCode;
  final String? reasonText;
  final int? amount;
  final Map<String, dynamic>? details;
  List<String> flags = [];
  String? reviewedBy;
  DateTime? reviewedAt;
}

class _PoolCode {
  _PoolCode(this.gateCode, this.counterId, this.homeGateId, this.expiresAt);

  final int gateCode;
  final String counterId;
  final String homeGateId;
  final DateTime expiresAt;
  String status = 'reserved';
}

class _Command {
  _Command(this.id, this.gateId, this.createdAt);

  final String id;
  final String gateId;
  final DateTime createdAt;
}
