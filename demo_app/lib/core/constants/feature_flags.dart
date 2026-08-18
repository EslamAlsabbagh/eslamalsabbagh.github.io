/// Compile-time feature switches, set with `--dart-define`.
///
/// These exist so a risky change can ship dark and be reverted with a rebuild
/// rather than a code revert. Delete a flag once its rollout is finished —
/// a flag that is permanently `true` is just dead branches.
abstract final class FeatureFlags {
  /// Server-side paging for the leave-request screens (My / Team / Processed).
  ///
  /// When `true` the screens use `list_user_leave_requests` and fetch one page
  /// at a time; when `false` they fall back to the whole-list read plus
  /// client-side filtering.
  ///
  /// The fallback exists because the paged path depends on a database
  /// migration. If the migration has not been applied, or a session's user row
  /// has no `auth_user_id`, the RPC raises 42501 and the screen fails — build
  /// with `--dart-define=SERVER_PAGED_LEAVE_REQUESTS=false` to get users
  /// working again while that is fixed.
  ///
  /// Note the fallback is still subject to PostgREST's max_rows cap, which
  /// truncates lists silently. It is an escape hatch, not a supported mode.
  static const bool serverPagedLeaveRequests = bool.fromEnvironment('SERVER_PAGED_LEAVE_REQUESTS', defaultValue: true);

  /// Server-side paging for the business-trip screens (My / Team / Processed).
  ///
  /// Same contract as [serverPagedLeaveRequests], one screen over: when `true`
  /// the screens use `list_user_businesstrip_requests` and fetch one page at a
  /// time; when `false` they fall back to the whole-list read plus client-side
  /// filtering.
  ///
  /// Depends on `20260803120000_businesstrip_requests_pagination.sql`, which in
  /// turn depends on the leave migration for `_require_user_code()` / `_is_hr()`.
  /// If either has not been applied the RPC raises 42501 and the screen fails —
  /// build with `--dart-define=SERVER_PAGED_BUSINESSTRIP_REQUESTS=false` to get
  /// users working again while that is fixed.
  static const bool serverPagedBusinesstripRequests = bool.fromEnvironment(
    'SERVER_PAGED_BUSINESSTRIP_REQUESTS',
    defaultValue: true,
  );

  /// Server-side paging for the missing-punch screens (My / Team / Processed).
  ///
  /// Same contract as [serverPagedLeaveRequests]: when `true` the screens use
  /// `list_user_missingpunch_requests` and fetch one page at a time; when
  /// `false` they fall back to the whole-list read plus client-side filtering.
  ///
  /// Depends on `20260804120000_missingpunch_requests_pagination.sql`, which in
  /// turn depends on the leave migration for `_require_user_code()` / `_is_hr()`.
  /// If either has not been applied the RPC raises 42501 and the screen fails —
  /// build with `--dart-define=SERVER_PAGED_MISSINGPUNCH_REQUESTS=false` to get
  /// users working again while that is fixed.
  ///
  /// Note the fallback also loses the per-row business-trip conflict flag and
  /// falls back to [SameDayConflictService], which can only see the rows it
  /// fetched.
  static const bool serverPagedMissingpunchRequests = bool.fromEnvironment(
    'SERVER_PAGED_MISSINGPUNCH_REQUESTS',
    defaultValue: true,
  );

  /// Server-side paging for the overtime screens (My / Team / Processed).
  ///
  /// Same contract as [serverPagedLeaveRequests], one screen over. Depends on
  /// `20260804130000_overtime_requests_pagination.sql` plus the leave migration
  /// for `_require_user_code()` / `_is_hr()`. Escape hatch:
  /// `--dart-define=SERVER_PAGED_OVERTIME_REQUESTS=false`.
  static const bool serverPagedOvertimeRequests = bool.fromEnvironment(
    'SERVER_PAGED_OVERTIME_REQUESTS',
    defaultValue: true,
  );

  /// Server-side paging for the HR-letter screens (My / Team / Processed).
  ///
  /// Unlike the four above, these screens are card lists rather than
  /// `AsyncPaginatedDataTable2` tables, so the page window lives in the bloc —
  /// see `PagedSection` in lib/core/bases/paged_section.dart. The server
  /// contract is identical.
  ///
  /// Depends on `20260804140000_hr_letter_requests_pagination.sql` plus the
  /// leave migration for `_require_user_code()`. If either has not been applied
  /// the RPC raises 42501/42883 and the screen fails — build with
  /// `--dart-define=SERVER_PAGED_HR_LETTER_REQUESTS=false` to get users working
  /// again while that is fixed.
  ///
  /// WARNING: the fallback is worse here than for the other flags. Turning this
  /// off restores `getAllHrLetterRequests()`, which reads the entire table with
  /// no predicate — so the Team/Processed tabs lose their `hr`-group gate as
  /// well as their paging. Treat "off" as a break-glass measure, and delete
  /// this flag before the others.
  static const bool serverPagedHrLetterRequests = bool.fromEnvironment(
    'SERVER_PAGED_HR_LETTER_REQUESTS',
    defaultValue: true,
  );

  /// Server-side paging for the advance-on-salary screens (all seven tabs) and
  /// the Finance-only Settlement Review screen.
  ///
  /// Card lists, so the page window lives in the bloc — same shape as
  /// [serverPagedHrLetterRequests].
  ///
  /// Depends on `20260804150000_advance_requests_pagination.sql`, which depends
  /// on `20260804140000` for `_is_in_group()` / `_managed_codes()` and on the
  /// leave migration for `_require_user_code()`. Escape hatch:
  /// `--dart-define=SERVER_PAGED_ADVANCE_REQUESTS=false`.
  ///
  /// The fallback is NOT equivalent, in both directions. Turning this off
  /// restores fuzzy (Levenshtein) search, the relevance sort and searchable
  /// amount-in-letters — but also restores the duplicate rows in the My tab,
  /// the client-supplied-code role checks, and silent max_rows truncation on
  /// every tab.
  static const bool serverPagedAdvanceRequests = bool.fromEnvironment(
    'SERVER_PAGED_ADVANCE_REQUESTS',
    defaultValue: true,
  );

  /// Server-side paging for the disciplinary screens (My / Team / Processed
  /// disciplinary / Processed investigations).
  ///
  /// The only one of the three that pages a MERGED list: disciplinary actions
  /// and investigations are two tables unioned server-side with a `row_kind`
  /// discriminator, the shape leave already uses for requests + cancellations.
  ///
  /// Depends on `20260804160000_disciplinary_requests_pagination.sql`, which
  /// depends on `20260804140000` for `_is_in_group()` / `_managed_codes()` and
  /// on the leave migration for `_require_user_code()`. Escape hatch:
  /// `--dart-define=SERVER_PAGED_DISCIPLINARY_REQUESTS=false`.
  ///
  /// The fallback also reinstates a latent crash: `EditWrittenWarningOptions`
  /// looks its row up with `state.requests.firstWhere(...)` on the legacy path
  /// and throws `StateError` when the row is not in the loaded list. The paged
  /// path fetches by id instead.
  static const bool serverPagedDisciplinaryRequests = bool.fromEnvironment(
    'SERVER_PAGED_DISCIPLINARY_REQUESTS',
    defaultValue: true,
  );
}
