import '../../data/models/advance_on_salary_request_model.dart';
import '../../data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import '../pdf/advance_pdf_storage_service.dart';

/// Complete workflow service for advance requests including PDF generation
class AdvanceRequestWorkflowService {
  final AdvanceOnSalaryRequestsRepo _advanceRepo;
  final AdvancePDFStorageService _pdfStorageService;

  AdvanceRequestWorkflowService({
    required AdvanceOnSalaryRequestsRepo advanceRepo,
    required AdvancePDFStorageService pdfStorageService,
  }) : _advanceRepo = advanceRepo,
       _pdfStorageService = pdfStorageService;

  /// Complete workflow when finance approves the request
  /// This is the main method to call when finance clicks "Approve"
  Future<void> financeApproveWithPDFWorkflow(int requestId, int approverCode, String locale) async {
    try {
      // 2. Approve the request in database
      await _advanceRepo.approveRequest(requestId, 'finance', approverCode);

      // 3. Re-fetch request data to get updated finance approval info
      final updatedRequest = await _getRequestById(requestId);

      // 4. Populate user names from users table
      final requestWithNames = await _populateUserNames(updatedRequest, approverCode);

      // 5. Generate both current and final PDFs
      final pdfUrls = await _pdfStorageService.generateBothPDFs(requestWithNames, locale);

      // 6. Add PDF URLs to the request object for email notifications
      final requestWithPDF = requestWithNames.copyWith(pdfUrl: pdfUrls['currentPdfUrl']);

      // 7. Send email notifications with current PDF attachment
      await _sendApprovalNotificationsWithPDF(requestWithPDF);
    } catch (e) {
      rethrow;
    }
  }

  /// Generate PDF for an existing approved request (manual/on-demand)
  /// Regenerates both current and final PDFs
  ///
  /// DEPRECATED: Use regenerateFinalPDFOnly() after unscheduled payments/settlements
  /// This method should only be used when BOTH PDFs need regeneration (rare cases)
  Future<String> generatePDFForApprovedRequest(int requestId, String locale) async {
    // Get the request data by ID
    final request = await _getRequestById(requestId);

    // Fetch unscheduled payments separately (no join issues)
    final unscheduledPayments = await _advanceRepo.getUnscheduledPayments(requestId);

    // Fetch scheduled payments separately (no join issues)
    // No scheduled_payments table in the demo; the schedule is derived on the
    // request itself, so an empty result keeps the mapping below intact.
    final scheduledPaymentsResponse = <Map<String, dynamic>>[];
    final scheduledPayments = scheduledPaymentsResponse.map((json) => ScheduledPayment.fromJson(json)).toList();

    // Populate borrower and requestor names from users table
    // Use existing finance approver code from the request
    final requestWithNames = await _populateUserNames(request, request.financeApproverCode ?? 0);

    // Add BOTH unscheduled AND scheduled payments to the request
    final completeRequest = requestWithNames.copyWith(
      unscheduledPayments: unscheduledPayments,
      scheduledPayments: scheduledPayments,
    );

    // Regenerate both PDFs with complete data (current + final state)
    await _pdfStorageService.generateBothPDFs(completeRequest, locale);

    // Return current PDF URL for backward compatibility
    return await _pdfStorageService.getPDFUrl(requestId) ?? '';
  }

  /// Regenerate only final PDF after unscheduled payments or settlements
  /// Optimized version that skips current state PDF to improve performance
  Future<String> regenerateFinalPDFOnly(int requestId, String locale) async {
    // Get the request data by ID
    final request = await _getRequestById(requestId);

    // Fetch unscheduled payments separately (no join issues)
    final unscheduledPayments = await _advanceRepo.getUnscheduledPayments(requestId);

    // Fetch scheduled payments separately (no join issues)
    // No scheduled_payments table in the demo; the schedule is derived on the
    // request itself, so an empty result keeps the mapping below intact.
    final scheduledPaymentsResponse = <Map<String, dynamic>>[];
    final scheduledPayments = scheduledPaymentsResponse.map((json) => ScheduledPayment.fromJson(json)).toList();

    // Populate borrower and requestor names from users table
    final requestWithNames = await _populateUserNames(request, request.financeApproverCode ?? 0);

    // Add BOTH unscheduled AND scheduled payments to the request
    final completeRequest = requestWithNames.copyWith(
      unscheduledPayments: unscheduledPayments,
      scheduledPayments: scheduledPayments,
    );

    // Regenerate ONLY final PDF (optimized - skips current state PDF)
    final finalPdfUrl = await _pdfStorageService.generateAndStoreFinalPDF(completeRequest, locale);

    return finalPdfUrl;
  }

  /// Get PDF URL for display in app
  Future<String?> getPDFUrlForDisplay(int requestId) async {
    return await _advanceRepo.getPDFUrl(requestId);
  }

  /// Check if PDF exists for a request
  Future<bool> hasPDF(int requestId) async {
    final url = await getPDFUrlForDisplay(requestId);
    return url != null && url.isNotEmpty;
  }

  /// Get a specific request by ID from the database
  /// Note: Unscheduled payments are fetched separately to avoid join issues
  /// Resolves a request by id from the repository.
  ///
  /// Production issued a direct `select().eq('id', ...).single()` here; the
  /// demo has no table to query, so it scans what the repository already
  /// exposes. Same result, no network call.
  Future<AdvanceOnSalaryRequestModel> _getRequestById(int requestId) async {
    for (final r in await _advanceRepo.getApprovedUnsettledRequests()) {
      if (r.id == requestId) return r;
    }
    throw StateError('Advance request $requestId is not in the demo dataset.');
  }

  /// Populate user names and finance approval data
  Future<AdvanceOnSalaryRequestModel> _populateUserNames(
    AdvanceOnSalaryRequestModel request,
    int financeApproverCode,
  ) async {
    try {
      // Get all relevant user codes
      final userCodes = <int>{};
      if (request.requestorCode != null) userCodes.add(request.requestorCode!);
      if (request.borrowerCode != null) userCodes.add(request.borrowerCode!);
      if (request.n2Code != null) userCodes.add(request.n2Code!);
      if (request.hrApproverCode != null) userCodes.add(request.hrApproverCode!);
      userCodes.add(financeApproverCode); // Add current finance approver

      // Fetch user data
      final usersResponse = <Map<String, dynamic>>[];

      // Create a map for quick lookup
      final usersMap = <int, Map<String, dynamic>>{};
      for (final user in usersResponse) {
        usersMap[user['Code'] as int] = user;
      }

      // Get user names
      String? requestorEnglishName;
      String? requestorArabicName;
      String? borrowerEnglishName;
      String? borrowerArabicName;

      if (request.requestorCode != null && usersMap.containsKey(request.requestorCode)) {
        final user = usersMap[request.requestorCode!]!;
        requestorEnglishName = user['English Name'];
        requestorArabicName = user['Arabic Name'];
      }

      if (request.borrowerCode != null && usersMap.containsKey(request.borrowerCode)) {
        final user = usersMap[request.borrowerCode!]!;
        borrowerEnglishName = user['English Name'];
        borrowerArabicName = user['Arabic Name'];
      }

      return request.copyWith(
        requestorEnglishName: requestorEnglishName,
        requestorArabicName: requestorArabicName,
        borrowerEnglishName: borrowerEnglishName,
        borrowerArabicName: borrowerArabicName,
        financeApproverCode: financeApproverCode,
      );
    } catch (e) {
      return request; // Return original request if population fails
    }
  }

  /// Send email notifications with PDF attachment
  /// Approval e-mail is sent by a Supabase Edge Function in production. The
  /// demo sends nothing — it makes no network calls — so this is a no-op kept
  /// in place so the workflow reads the same.
  Future<void> _sendApprovalNotificationsWithPDF(AdvanceOnSalaryRequestModel request) async {}

}
