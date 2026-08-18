/// An injectable source of "now".
///
/// Repositories write approval/submission timestamps straight into Postgres via
/// `DateTime.now().toIso8601String()`. Calling the static `DateTime.now()` makes
/// those code paths untestable — you cannot assert on a timestamp you cannot
/// control, and any test that tries is inherently flaky.
///
/// Injecting a [Clock] instead turns "what time is it" into an ordinary
/// dependency: production passes [SystemClock], tests pass [FixedClock].
abstract interface class Clock {
  DateTime now();
}

/// The production clock — delegates to the real wall clock.
///
/// `const` so it can be a default parameter value, which is what lets [Clock] be
/// added to an existing constructor without touching a single call site.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A clock frozen at [_instant], for tests that assert on written timestamps.
class FixedClock implements Clock {
  const FixedClock(this._instant);

  final DateTime _instant;

  @override
  DateTime now() => _instant;
}
