
/// Why a sign-in attempt failed, in terms the login screen can show.
enum SignInFailure {
  invalidCredentials,

  /// The access token hook refused an inactive profile (ADR-0006).
  accountDisabled,
  rateLimited,
  network,
  unknown,
}

/// Thrown by `AuthRepository.signInWithPassword`.
class SignInException implements Exception {
  const SignInException(this.failure);

  final SignInFailure failure;

  @override
  String toString() => 'SignInException($failure)';
}
