import 'package:hrms_demo/data/models/leave_cancellation_request_model.dart';

abstract class LeaveCancellationRequestsRepo {
  Future<int> submitCancellationRequest(LeaveCancellationRequestModel request);
  Future<List<LeaveCancellationRequestModel>> getMyCancellationRequests(int userCode);
  Future<List<LeaveCancellationRequestModel>> getCancellationRequestsToApprove(int approverCode);
  Future<List<LeaveCancellationRequestModel>> getProcessedCancellationRequests(int approverCode);
  Future<void> approveCancellationRequest(int requestId, String approverTitle, int approverCode);
  Future<void> declineCancellationRequest(int requestId, String reason, String currentApprover, int approverCode);
  Future<List<LeaveCancellationRequestModel>> getCancellationRequestsByMonth(
    int userCode,
    DateTime month,
  );
  Future<bool> hasMyCancellationRequests(int userCode);
  Future<bool> hasTeamCancellationRequests(int approverCode);
  Future<void> cancelCancellationRequest(int requestId);
  Future<void> removeCancellationRequest(int requestId);
  Future<void> removeCancellationRequestForN1(int requestId);
  Future<bool> canRequestCancellation(int originalLeaveRequestId);
  Future<bool> hasPendingCancellationRequest(int originalLeaveRequestId);
}