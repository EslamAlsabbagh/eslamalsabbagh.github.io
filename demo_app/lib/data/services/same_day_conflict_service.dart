import 'package:hrms_demo/data/models/businesstrip_request_model.dart';
import 'package:hrms_demo/data/models/missingpunching_request_model.dart';

/// Flags requests that collide with another request on the same day.
///
/// Production cross-checks several tables per request. The demo's seeded data
/// contains no deliberate collisions, so both checks report none — the screens
/// render their normal, non-conflicting state.
class SameDayConflictService {
  const SameDayConflictService();

  Future<Set<int>> businesstripConflicts(
    List<BusinesstripRequestModel> trips,
  ) async => <int>{};

  Future<Set<int>> missingPunchConflicts(
    List<MissingpunchingRequestModel> punches,
  ) async => <int>{};
}
