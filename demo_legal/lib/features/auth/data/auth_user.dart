import 'package:equatable/equatable.dart';

/// The signed-in user, as the app sees it. Keeps Supabase's `User` type out of
/// blocs and widgets. Role and display name are in [UserProfile].
class AuthUser extends Equatable {
  const AuthUser({required this.id, this.email});

  /// `auth.users.id`; the same id the database uses for RLS.
  final String id;
  final String? email;

  @override
  List<Object?> get props => [id, email];
}
