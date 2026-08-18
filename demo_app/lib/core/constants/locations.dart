/// The employee site list — single source of truth for every Location dropdown
/// (the add/edit employee forms and the Statistics filter bar).
///
/// These are the values written to `users."Location / Site"`, so the Statistics
/// Location filter compares against exactly what the forms store.
const List<String> kEmployeeLocations = ['RIVERSIDE', 'HARBOUR', 'HQ'];
