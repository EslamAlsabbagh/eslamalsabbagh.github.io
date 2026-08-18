import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/services/pdf/business_trip_pdf_generation_service.dart';

/// Orchestrates HR final approval of a business-trip request.
///
/// In production this performs the approval, re-reads the row, renders a PDF
/// for fee-eligible trips and hands it to a Supabase Edge Function that mails
/// the employee plus the HR and Finance groups.
///
/// The demo performs the approval — the part the user sees — and stops there.
/// It sends no mail and re-reads nothing, because it makes no network calls of
/// any kind.
class BusinesstripApprovalWorkflowService {
  /// [pdfService] is accepted so the demo graph matches production's shape,
  /// but the demo never renders the attachment because it sends no mail.
  BusinesstripApprovalWorkflowService({
    required BusinesstripRequestsRepo repo,
    BusinessTripPDFGenerationService? pdfService,
  }) : _repo = repo;

  final BusinesstripRequestsRepo _repo;

  /// Performs HR final approval. The notification and PDF attachment steps are
  /// server-side in production and intentionally absent here.
  Future<void> hrApproveWithNotification(
    int requestId,
    int approverCode,
    String locale, {
    double? transportationFeeAmount,
  }) async {
    await _repo.approveRequest(
      requestId,
      'hr',
      approverCode,
      transportationFeeAmount: transportationFeeAmount,
    );
  }
}
