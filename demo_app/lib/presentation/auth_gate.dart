import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/presentation/widgets/logout_action.dart';
import 'package:hrms_demo/core/utils/user_code_utils.dart';
import 'package:hrms_demo/data/repos/storage/storage_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';
import 'package:hrms_demo/presentation/dashboard/dashboard_page.dart';
import 'package:hrms_demo/presentation/login/login_page.dart';
import 'package:hrms_demo/presentation/mandatory_password_change/mandatory_password_change_page.dart';
import 'package:hrms_demo/presentation/widgets/loading_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/demo/demo_session.dart';

/// The single source of truth for top-level routing.
///
/// Historically two widgets fought over navigation: [LoginPage] auto-pushed the
/// Dashboard whenever a Supabase session existed, while the Dashboard pushed
/// back to Login whenever [UserBloc] had no loaded user. Because a valid session
/// can coexist with an unloaded `UserBloc` (the `initial`/reset state), the two
/// would ping-pong forever — redirecting users to login recursively and
/// hammering the backend with the dashboard's ~27 queries per entry.
///
/// [AuthGate] removes that whole bug class: it *renders* the correct screen
/// declaratively from BOTH the auth session and the [UserBloc] state, instead of
/// pushing/popping routes. With one authority and no route stack to bounce
/// against, the loop is structurally impossible. The widgets it replaces no
/// longer perform any session-based navigation of their own — they simply update
/// auth/bloc state and let the gate re-render. The gate always stays at the
/// navigator root, so logout (driven by `onAuthStateChange`) can reliably swap
/// the whole app back to login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// The user code we have already dispatched a profile load for. Guards against
  /// re-dispatching `LoadUserProfile` on every rebuild; reset to `null` whenever
  /// the session disappears so the next sign-in re-loads cleanly.
  String? _requestedCode;

  /// Last known value of the weak-password flag, used to avoid a spinner flash
  /// while the (async) re-read of secure storage is in flight.
  bool _lastWeakPassword = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<DemoSession>();
    final storage = context.read<StorageRepo>();

    // The stream only triggers rebuilds; we always read the live currentUser so
    // the very first frame (before any stream event) is already correct.
    return StreamBuilder<void>(
      stream: auth.changes,
      builder: (context, _) {
        final session = auth.isSignedIn ? auth : null;

        // No session → show login. This is the ONLY thing that decides "show
        // login", and it is driven purely by session presence.
        if (session == null) {
          _requestedCode = null;
          _lastWeakPassword = false;
          return const LoginPage();
        }

        final code = extractUserCodeFromEmail(session.email);
        // Authenticated but the email is not a valid employee code — nothing we
        // can load. Fall back to login (safe: LoginPage no longer auto-navigates,
        // so this cannot loop).
        if (code == null) {
          return const LoginPage();
        }

        return BlocBuilder<UserBloc, UserState>(
          builder: (context, userState) {
            // Kick off exactly one profile load for this code. This is the state
            // that used to feed the redirect loop; now it just loads + spins.
            if (userState.status == Status.initial && _requestedCode != code) {
              _requestedCode = code;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.read<UserBloc>().add(LoadUserProfile(code));
              });
            }

            // Re-read the weak-password flag on every UserBloc transition. The
            // flag is written by LoginBloc right after the session is created, so
            // re-reading as the profile loads reliably catches it (and catches
            // it being cleared after a successful change). Cached value avoids a
            // flash while the read is pending.
            return FutureBuilder<dynamic>(
              future: storage.read('weak_password_flag'),
              builder: (context, flagSnap) {
                final isWeak =
                    flagSnap.connectionState == ConnectionState.waiting ? _lastWeakPassword : flagSnap.data == 'true';
                _lastWeakPassword = isWeak;

                if (isWeak) {
                  return MandatoryPasswordChangePage(userCode: code);
                }

                switch (userState.status) {
                  case Status.weakPassword:
                    return MandatoryPasswordChangePage(userCode: code);

                  case Status.failure:
                    return _RetryView(code: code, message: userState.error);

                  case Status.success:
                    if (userState.user != null) return const DashboardPage();
                    // Success with no user shouldn't happen, but never redirect —
                    // show a spinner rather than risk a loop.
                    return const Scaffold(body: Center(child: LoadingLogo()));

                  case Status.initial:
                  case Status.loading:
                    return const Scaffold(body: Center(child: LoadingLogo()));
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Shown when the profile load fails (e.g. a transient backend error). Offers a
/// retry instead of a dead-end error or a redirect, so the user can recover
/// without restarting the app.
class _RetryView extends StatelessWidget {
  const _RetryView({required this.code, this.message});

  final String code;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message ?? l10n.somethingWentWrong, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.read<UserBloc>().add(LoadUserProfile(code)),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => logoutAndSurfaceLogin(context),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
