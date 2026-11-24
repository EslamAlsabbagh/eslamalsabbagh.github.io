/// Which build the app is.
enum AppEnv { dev, prod }

/// Build settings. In production these are compiled in from a JSON file and
/// name the on-site server and this PC's counter; the demo build has no
/// server, so only the counter remains.
class AppConfig {
  const AppConfig({required this.env, required this.counterId});

  final AppEnv env;

  /// The counter this PC is (`COUNTER_ID`): the one its shifts open at.
  final String? counterId;

  bool get isDev => env == AppEnv.dev;
}
