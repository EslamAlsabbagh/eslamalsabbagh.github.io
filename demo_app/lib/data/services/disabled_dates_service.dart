import 'package:hrms_demo/data/models/disabled_date_info.dart';
import 'package:hrms_demo/demo/demo_store.dart';

/// Dates a user cannot select, because they already have a request covering
/// them.
///
/// Production derives this from three tables (missing punches, leave, business
/// trips). The demo derives it from the seeded leave requests held in
/// [DemoStore], so the date picker still greys out days the signed-in employee
/// has already booked — the behaviour the screen exists to show — without any
/// network call.
class DisabledDatesService {
  DisabledDatesService([DemoStore? store]) : _store = store ?? DemoStore.instance;

  final DemoStore _store;

  Future<List<DisabledDateInfo>> getDisabledDates({
    required int userCode,
    required DateTime calendarFirstDate,
    required DateTime calendarLastDate,
  }) async {
    DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

    final first = dayOnly(calendarFirstDate);
    final last = dayOnly(calendarLastDate);
    final out = <DisabledDateInfo>[];

    for (final r in _store.leaveRequests) {
      if (r.userId != userCode) continue;
      if (r.cancelled == true) continue;
      if ((r.status ?? '').toLowerCase() == 'declined') continue;
      final from = r.dateFrom, to = r.dateTo;
      if (from == null || to == null) continue;

      for (var d = dayOnly(from);
          !d.isAfter(dayOnly(to));
          d = d.add(const Duration(days: 1))) {
        if (d.isBefore(first) || d.isAfter(last)) continue;
        out.add(DisabledDateInfo(
          date: d,
          type: 'leave',
          leaveType: r.leaveType,
        ));
      }
    }
    return out;
  }
}
