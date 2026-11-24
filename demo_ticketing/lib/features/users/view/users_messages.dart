import '../../../l10n/gen/app_localizations.dart';
import '../../actions_log/data/action_log_models.dart' show SettingsChange;
import '../../auth/data/staff.dart';
import '../../home/view/app_header.dart' show roleName;
import '../data/user_models.dart';
import '../data/users_repository.dart';

/// The Users page's texts, shared with the actions log's change lines.

String usersFailureMessage(AppLocalizations l10n, UsersFailureKind kind) => switch (kind) {
  UsersFailureKind.notAllowed => l10n.usersNotAllowed,
  UsersFailureKind.nameRequired => l10n.usersNameRequired,
  UsersFailureKind.invalidUsername => l10n.usersInvalidUsername,
  UsersFailureKind.usernameTaken => l10n.usersUsernameTaken,
  UsersFailureKind.passwordTooShort => l10n.usersPasswordTooShort(staffPasswordMin),
  UsersFailureKind.passwordTooLong => l10n.usersPasswordTooLong,
  UsersFailureKind.cannotChangeOwnAccount => l10n.usersCannotChangeOwn,
  UsersFailureKind.staffHasOpenShift => l10n.usersHasOpenShift,
  UsersFailureKind.notFound => l10n.usersNotFound,
  UsersFailureKind.serverUnreachable => l10n.errorServerUnreachable,
  UsersFailureKind.unexpected => l10n.usersUnexpected,
};

/// What each role can do, as the design's summary lists it: the line and the
/// lowest role that has it.
List<(String, StaffRole)> permissionLines(AppLocalizations l10n) => [
  (l10n.usersPermSell, StaffRole.cashier),
  (l10n.usersPermActions, StaffRole.cashier),
  (l10n.usersPermShifts, StaffRole.supervisor),
  (l10n.usersPermLog, StaffRole.supervisor),
  (l10n.usersPermCatalog, StaffRole.admin),
  (l10n.usersPermUsers, StaffRole.admin),
];

/// [role] has what [needs] has: the roles are ordered cashier < supervisor < admin.
bool roleCovers(StaffRole role, StaffRole needs) => role.index >= needs.index;

/// A staff settings_change for the actions log (4.7), as `gateChangeText`
/// gives a gate's. Null for another subject. Never a password: a reset is
/// only its marker.
({String title, List<String> lines})? userChangeText(AppLocalizations l10n, SettingsChange change) {
  if (change.subject != 'staff') return null;
  final name = change.name ?? '—';
  final c = change.changes;

  String text(Object? value) => value is String && value.isNotEmpty ? value : '—';
  String role(Object? value) => switch (value) {
    final String key when StaffRole.values.any((r) => r.name == key) => roleName(
      l10n,
      StaffRole.fromName(key),
    ),
    _ => '—',
  };
  String active(Object? value) => switch (value) {
    true => l10n.usersStatusActive,
    false => l10n.usersStatusInactive,
    _ => '—',
  };
  // A username reads left to right in both languages.
  String username(Object? value) =>
      value is String && value.isNotEmpty ? '\u2066$value\u2069' : '—';

  if (change.created) {
    return (
      title: l10n.changeNewUser(name),
      lines: [
        [
          if (c['username']?.to case final String u when u.isNotEmpty) username(u),
          role(c['role']?.to),
          if (c['active']?.to == false) l10n.usersStatusInactive,
        ].join(' · '),
      ],
    );
  }
  return (
    title: l10n.changeUserName(name),
    lines: [
      if (c['full_name'] case final v?) l10n.changeField(l10n.usersName, text(v.from), text(v.to)),
      if (c['username'] case final v?)
        l10n.changeField(l10n.usersUsername, username(v.from), username(v.to)),
      if (c['role'] case final v?) l10n.changeField(l10n.usersRole, role(v.from), role(v.to)),
      if (c['active'] case final v?)
        l10n.changeField(l10n.usersColStatus, active(v.from), active(v.to)),
      if (c.containsKey('password')) l10n.changePasswordReset,
    ],
  );
}
