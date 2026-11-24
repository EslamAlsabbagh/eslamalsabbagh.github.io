import '../core/domain/user_role.dart';
import 'gen/app_localizations.dart';

extension UserRoleL10n on UserRole {
  String label(AppLocalizations l10n) => switch (this) {
    UserRole.lawyer => l10n.roleLawyer,
    UserRole.manager => l10n.roleManager,
    UserRole.admin => l10n.roleAdmin,
  };
}
