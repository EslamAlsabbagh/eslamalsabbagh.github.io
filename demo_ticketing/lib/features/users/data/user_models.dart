import 'package:equatable/equatable.dart';

import '../../auth/data/staff.dart';

DateTime? _time(Object? value) => value is String ? DateTime.parse(value) : null;

/// The usernames the server accepts (`staff.username`'s check, ADR-0021).
final staffUsernamePattern = RegExp(r'^[a-z0-9._-]{3,32}$');

/// GoTrue's and `check_staff_password`'s limits.
const staffPasswordMin = 8;
const staffPasswordMax = 72;

/// One user on the Users page (`users_overview`).
class AdminUser extends Equatable {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.active,
    this.lastSignInAt,
    this.lastCounterName,
    this.lastShiftOpenedAt,
    this.hasOpenShift = false,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'] as String,
    fullName: json['full_name'] as String,
    username: json['username'] as String,
    role: StaffRole.fromName(json['role'] as String),
    active: json['active'] as bool,
    lastSignInAt: _time(json['last_sign_in_at']),
    lastCounterName: json['last_counter_name'] as String?,
    lastShiftOpenedAt: _time(json['last_shift_opened_at']),
    hasOpenShift: json['has_open_shift'] as bool? ?? false,
  );

  final String id;
  final String fullName;
  final String username;
  final StaffRole role;
  final bool active;

  /// Their last password sign-in (a token refresh doesn't count).
  final DateTime? lastSignInAt;

  /// The counter of their latest shift, and when it opened.
  final String? lastCounterName;
  final DateTime? lastShiftOpenedAt;

  /// Where they last signed in, as far as the server knows: the counter of a
  /// shift opened since that sign-in. Null when they opened none (an admin on
  /// the office PC, or a cashier who signed in and left).
  String? get lastSignInCounter {
    final signIn = lastSignInAt;
    final opened = lastShiftOpenedAt;
    if (signIn == null || opened == null || opened.isBefore(signIn)) return null;
    return lastCounterName;
  }

  /// Deactivating is refused until it closes.
  final bool hasOpenShift;

  UserDraft get draft =>
      UserDraft(fullName: fullName, username: username, role: role, active: active);

  @override
  List<Object?> get props => [
    id,
    fullName,
    username,
    role,
    active,
    lastSignInAt,
    lastCounterName,
    lastShiftOpenedAt,
    hasOpenShift,
  ];
}

class UsersOverview extends Equatable {
  const UsersOverview({required this.now, required this.users});

  factory UsersOverview.fromJson(Map<String, dynamic> json) => UsersOverview(
    now: DateTime.parse(json['now'] as String),
    users: [
      for (final u in json['staff'] as List<dynamic>) AdminUser.fromJson(u as Map<String, dynamic>),
    ],
  );

  /// The server's clock when it answered.
  final DateTime now;

  /// Active users first, then by name.
  final List<AdminUser> users;

  AdminUser? user(String? id) {
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  @override
  List<Object?> get props => [now, users];
}

/// The edit panel's values. [password] only for a new user.
class UserDraft extends Equatable {
  const UserDraft({
    required this.fullName,
    required this.username,
    required this.role,
    required this.active,
    this.password,
  });

  final String fullName;
  final String username;
  final StaffRole role;
  final bool active;
  final String? password;

  /// The same saved values (the password isn't one).
  bool sameAs(UserDraft other) =>
      fullName == other.fullName &&
      username == other.username &&
      role == other.role &&
      active == other.active;

  @override
  List<Object?> get props => [fullName, username, role, active, password];
}
