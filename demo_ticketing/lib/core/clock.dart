/// The current time, behind a seam so tests can fix it.
class Clock {
  const Clock([this._now = DateTime.now]);

  final DateTime Function() _now;

  DateTime now() => _now();
}
