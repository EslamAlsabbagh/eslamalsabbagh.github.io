import 'package:hrms_demo/data/models/businesstrip_cancellation_request_model.dart';

abstract class BusinesstripCancellationRequestsRepo {
  Future<int> submitCancellationRequest(BusinesstripCancellationRequestModel request);
  Future<List<BusinesstripCancellationRequestModel>> getMyCancellationRequests(int userCode);
  Future<List<BusinesstripCancellationRequestModel>> getCancellationRequestsToApprove(int approverCode);
  Future<List<BusinesstripCancellationRequestModel>> getProcessedCancellationRequests(int approverCode);
  Future<void> approveCancellationRequest(int requestId, String approverTitle, int approverCode);
  Future<void> declineCancellationRequest(int requestId, String reason, String currentApprover, int approverCode);
  Future<List<BusinesstripCancellationRequestModel>> getCancellationRequestsByMonth(
    int userCode,
    DateTime month,
  );
  Future<bool> hasMyCancellationRequests(int userCode);
  Future<bool> hasTeamCancellationRequests(int approverCode);
  Future<void> cancelCancellationRequest(int requestId);
  Future<void> removeCancellationRequest(int requestId);
  Future<void> removeCancellationRequestForN1(int requestId);
  Future<bool> canRequestCancellation(int originalBusinesstripRequestId);
  Future<bool> hasPendingCancellationRequest(int originalBusinesstripRequestId);
}
