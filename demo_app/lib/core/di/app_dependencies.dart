import 'package:hrms_demo/core/services/auth_service.dart';
import 'package:hrms_demo/core/services/employee_validation_service.dart';
import 'package:hrms_demo/core/services/file_parser_service.dart';
import 'package:hrms_demo/core/time/clock.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/data/repos/auth/auth_repo_fake.dart';
import 'package:hrms_demo/data/repos/businesstrip_cancellation_request/businesstrip_cancellation_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_cancellation_request/businesstrip_cancellation_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/leave_cancellation_request/leave_cancellation_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_cancellation_request/leave_cancellation_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/org_structure/org_structure_repo.dart';
import 'package:hrms_demo/data/repos/org_structure/org_structure_repo_fake.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo_fake.dart';
import 'package:hrms_demo/data/repos/schedule/schedule_repo.dart';
import 'package:hrms_demo/data/repos/schedule/schedule_repo_fake.dart';
import 'package:hrms_demo/data/repos/statistics/statistics_repo.dart';
import 'package:hrms_demo/data/repos/statistics/statistics_repo_fake.dart';
import 'package:hrms_demo/data/repos/storage/storage_repo.dart';
import 'package:hrms_demo/data/repos/storage/storage_repo_fake.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo_fake.dart';
import 'package:hrms_demo/data/services/disabled_dates_service.dart';
import 'package:hrms_demo/data/services/same_day_conflict_service.dart';
import 'package:hrms_demo/services/advance_request/advance_request_workflow_service.dart';
import 'package:hrms_demo/services/businesstrip_request/businesstrip_approval_workflow_service.dart';
import 'package:hrms_demo/services/pdf/advance_pdf_storage_service.dart';
import 'package:hrms_demo/services/pdf/business_trip_pdf_generation_service.dart';
import 'package:hrms_demo/services/pdf/disciplinary_pdf_storage_service.dart';
import 'package:hrms_demo/services/pdf/pdf_generation_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/demo/demo_session.dart';

/// The application's single composition root.
///
/// Before this existed, every page was its own composition root: `build()`
/// methods called `SomeRepoImpl(Supabase.instance.client)` inline, which meant
/// 114 construction sites for 16 repositories (~7 duplicate instances each),
/// reallocated on every rebuild. `DashboardPage` alone built 20.
///
/// [AppDependencies] owns the object graph instead. It is constructed exactly
/// once in `main()` and handed to `MyApp`, which exposes it to the widget tree
/// through [providers]. Widgets then ask for a dependency by its *interface*
/// (`context.read<UsersRepo>()`) and never name an implementation.
///
/// Two properties make this safe to retrofit onto the existing code:
///
/// * Every `*RepoImpl` is stateless — one `final SupabaseClient` and no caches —
///   so collapsing many instances into one is observationally identical, just
///   with fewer allocations.
/// * Every field is `late final`, so nothing is built until first read, and
///   [providers] uses `RepositoryProvider(create:)` (lazy by default) rather
///   than `.value`, which would force eager construction of the whole graph.
///
/// Tests construct this directly with fakes, or subclass it and override
/// individual `late final` fields.
class AppDependencies {
  AppDependencies({
    required this.session,
    this.clock = const SystemClock(),
  });

  /// The demo graph. Every repository is an in-memory fake reading from
  /// `DemoStore`, so constructing this reaches no network and needs no
  /// initialisation step — unlike production, which had to run after
  /// `Supabase.initialize`.
  factory AppDependencies.demo() => AppDependencies(session: DemoSession());

  final DemoSession session;
  final Clock clock;

  // ---------------------------------------------------------------------------
  // Repositories — always declared as the INTERFACE type.
  //
  // This is what makes the migration free: every bloc already declares its
  // fields as interfaces (`UserBloc.repo` is `UsersRepo`, not `UsersRepoImpl`),
  // so `context.read<UsersRepo>()` type-checks against the existing constructors
  // without a single bloc change.
  // ---------------------------------------------------------------------------

  late final UsersRepo usersRepo = FakeUsersRepo();
  late final AuthRepo authRepo = FakeAuthRepo();
  late final StorageRepo storageRepo = FakeStorageRepo();

  late final LeaveRequestsRepo leaveRequestsRepo = FakeLeaveRequestsRepo();
  late final LeaveCancellationRequestsRepo leaveCancellationRequestsRepo =
      FakeLeaveCancellationRequestsRepo();
  late final OvertimeRequestRepo overtimeRequestRepo = FakeOvertimeRequestRepo();
  late final BusinesstripRequestsRepo businesstripRequestsRepo = FakeBusinesstripRequestsRepo();
  late final BusinesstripCancellationRequestsRepo businesstripCancellationRequestsRepo =
      FakeBusinesstripCancellationRequestsRepo();
  late final MissingpunchingRequestsRepo missingpunchingRequestsRepo =
      FakeMissingpunchingRequestsRepo();
  late final AdvanceOnSalaryRequestsRepo advanceOnSalaryRequestsRepo =
      FakeAdvanceOnSalaryRequestsRepo();
  late final DisciplinaryActionRequestRepo disciplinaryActionRequestRepo =
      FakeDisciplinaryActionRequestRepo();
  late final InvestigationRequestRepo investigationRequestRepo = FakeInvestigationRequestRepo();
  late final HrLetterRequestRepo hrLetterRequestRepo = FakeHrLetterRequestRepo();
  late final ScheduleRepo scheduleRepo = FakeScheduleRepo();
  late final StatisticsRepo statisticsRepo = FakeStatisticsRepo();
  late final OrgStructureRepo orgStructureRepo = FakeOrgStructureRepo();

  // ---------------------------------------------------------------------------
  // Services. These have no interfaces, so they are keyed by concrete type.
  // ---------------------------------------------------------------------------

  /// Owned here rather than as a top-level global in `main.dart`, which forced
  /// presentation files to `import 'main.dart'` just to reach it.
  late final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  late final AuthService authService = AuthService(session: session, storage: storageRepo);
  late final DisabledDatesService disabledDatesService = DisabledDatesService();
  late final SameDayConflictService sameDayConflictService = const SameDayConflictService();
  late final EmployeeValidationService employeeValidationService = EmployeeValidationService(usersRepo);
  late final FileParserService fileParserService = FileParserService();

  late final PDFGenerationService pdfGenerationService = PDFGenerationService(
    usersRepo: usersRepo,
  );
  late final BusinessTripPDFGenerationService businessTripPdfGenerationService =
      BusinessTripPDFGenerationService();
  late final AdvancePDFStorageService advancePdfStorageService = AdvancePDFStorageService(
    pdfService: pdfGenerationService,
  );
  late final DisciplinaryPDFStorageService disciplinaryPdfStorageService =
      DisciplinaryPDFStorageService();

  /// Replaces the hand-rolled `AdvanceRequestWorkflowService.create(...)` factory,
  /// which built this same graph inside a widget's `initState`.
  late final AdvanceRequestWorkflowService advanceRequestWorkflowService = AdvanceRequestWorkflowService(
    advanceRepo: advanceOnSalaryRequestsRepo,
    pdfStorageService: advancePdfStorageService,
  );

  late final BusinesstripApprovalWorkflowService businesstripApprovalWorkflowService =
      BusinesstripApprovalWorkflowService(
        repo: businesstripRequestsRepo,
        pdfService: businessTripPdfGenerationService,
      );

  // ---------------------------------------------------------------------------

  /// The graph, as widgets, for `MultiRepositoryProvider.providers`.
  ///
  /// Deliberately typed `List<RepositoryProvider>` rather than
  /// `List<SingleChildWidget>`: `SingleChildWidget` lives in `nested`, which is
  /// only a *transitive* dependency here (via `flutter_bloc` → `provider`), so
  /// naming it would mean either an undeclared-package import or a new pubspec
  /// entry. Dart's covariant generics make this list assignable to the
  /// `List<SingleChildWidget>` that `MultiRepositoryProvider` expects, so this
  /// file needs nothing beyond `flutter_bloc`.
  List<RepositoryProvider> get providers => [
    // The demo session, for the call sites that need auth (AuthGate's session
    // stream, the role switcher) rather than a repository.
    RepositoryProvider<DemoSession>(create: (_) => session),
    RepositoryProvider<Clock>(create: (_) => clock),

    RepositoryProvider<UsersRepo>(create: (_) => usersRepo),
    RepositoryProvider<AuthRepo>(create: (_) => authRepo),
    RepositoryProvider<StorageRepo>(create: (_) => storageRepo),
    RepositoryProvider<LeaveRequestsRepo>(create: (_) => leaveRequestsRepo),
    RepositoryProvider<LeaveCancellationRequestsRepo>(create: (_) => leaveCancellationRequestsRepo),
    RepositoryProvider<OvertimeRequestRepo>(create: (_) => overtimeRequestRepo),
    RepositoryProvider<BusinesstripRequestsRepo>(create: (_) => businesstripRequestsRepo),
    RepositoryProvider<BusinesstripCancellationRequestsRepo>(
      create: (_) => businesstripCancellationRequestsRepo,
    ),
    RepositoryProvider<MissingpunchingRequestsRepo>(create: (_) => missingpunchingRequestsRepo),
    RepositoryProvider<AdvanceOnSalaryRequestsRepo>(create: (_) => advanceOnSalaryRequestsRepo),
    RepositoryProvider<DisciplinaryActionRequestRepo>(create: (_) => disciplinaryActionRequestRepo),
    RepositoryProvider<InvestigationRequestRepo>(create: (_) => investigationRequestRepo),
    RepositoryProvider<HrLetterRequestRepo>(create: (_) => hrLetterRequestRepo),
    RepositoryProvider<ScheduleRepo>(create: (_) => scheduleRepo),
    RepositoryProvider<StatisticsRepo>(create: (_) => statisticsRepo),
    RepositoryProvider<OrgStructureRepo>(create: (_) => orgStructureRepo),

    RepositoryProvider<RouteObserver<PageRoute>>(create: (_) => routeObserver),
    RepositoryProvider<AuthService>(create: (_) => authService),
    RepositoryProvider<DisabledDatesService>(create: (_) => disabledDatesService),
    RepositoryProvider<SameDayConflictService>(create: (_) => sameDayConflictService),
    RepositoryProvider<EmployeeValidationService>(create: (_) => employeeValidationService),
    RepositoryProvider<FileParserService>(create: (_) => fileParserService),
    RepositoryProvider<PDFGenerationService>(create: (_) => pdfGenerationService),
    RepositoryProvider<BusinessTripPDFGenerationService>(create: (_) => businessTripPdfGenerationService),
    RepositoryProvider<AdvancePDFStorageService>(create: (_) => advancePdfStorageService),
    RepositoryProvider<DisciplinaryPDFStorageService>(create: (_) => disciplinaryPdfStorageService),
    RepositoryProvider<AdvanceRequestWorkflowService>(create: (_) => advanceRequestWorkflowService),
    RepositoryProvider<BusinesstripApprovalWorkflowService>(
      create: (_) => businesstripApprovalWorkflowService,
    ),
  ];
}
