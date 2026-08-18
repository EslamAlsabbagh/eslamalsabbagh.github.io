import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class SettlementInfo {
  final String? settlerNameArabic;
  final String? settlerNameEnglish;
  final DateTime settlementDate;

  SettlementInfo({this.settlerNameArabic, this.settlerNameEnglish, required this.settlementDate});

  factory SettlementInfo.fromJson(Map<String, dynamic> json) {
    return SettlementInfo(
      settlerNameArabic: json['settler_name_arabic'],
      settlerNameEnglish: json['settler_name_english'],
      settlementDate: DateTime.parse(json['settlement_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settler_name_arabic': settlerNameArabic,
      'settler_name_english': settlerNameEnglish,
      'settlement_date': settlementDate.toIso8601String(),
    };
  }

  SettlementInfo copyWith({String? settlerNameArabic, String? settlerNameEnglish, DateTime? settlementDate}) {
    return SettlementInfo(
      settlerNameArabic: settlerNameArabic ?? this.settlerNameArabic,
      settlerNameEnglish: settlerNameEnglish ?? this.settlerNameEnglish,
      settlementDate: settlementDate ?? this.settlementDate,
    );
  }

  String getLocalizedSettlerName(bool isArabic) {
    return isArabic ? (settlerNameArabic ?? settlerNameEnglish ?? '') : (settlerNameEnglish ?? settlerNameArabic ?? '');
  }
}

class ScheduledPayment {
  final int? id;
  final DateTime? createdAt;
  final int advanceRequestId;
  final double amount;
  final DateTime paymentDate;

  ScheduledPayment({
    this.id,
    this.createdAt,
    required this.advanceRequestId,
    required this.amount,
    required this.paymentDate,
  });

  factory ScheduledPayment.fromJson(Map<String, dynamic> json) {
    return ScheduledPayment(
      id: json['id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      advanceRequestId: json['advance_request_id'],
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'advance_request_id': advanceRequestId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
    };
  }

  ScheduledPayment copyWith({
    int? id,
    DateTime? createdAt,
    int? advanceRequestId,
    double? amount,
    DateTime? paymentDate,
  }) {
    return ScheduledPayment(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      advanceRequestId: advanceRequestId ?? this.advanceRequestId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }
}

class UnscheduledPayment {
  final int? id;
  final int advanceRequestId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;
  final int? recordedBy;
  final DateTime? createdAt;

  UnscheduledPayment({
    this.id,
    required this.advanceRequestId,
    required this.amount,
    required this.paymentDate,
    this.notes,
    this.recordedBy,
    this.createdAt,
  });

  factory UnscheduledPayment.fromJson(Map<String, dynamic> json) {
    return UnscheduledPayment(
      id: json['id'],
      advanceRequestId: json['advance_request_id'],
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date']),
      notes: json['notes'],
      recordedBy: json['recorded_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'advance_request_id': advanceRequestId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'recorded_by': recordedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  UnscheduledPayment copyWith({
    int? id,
    int? advanceRequestId,
    double? amount,
    DateTime? paymentDate,
    String? notes,
    int? recordedBy,
    DateTime? createdAt,
  }) {
    return UnscheduledPayment(
      id: id ?? this.id,
      advanceRequestId: advanceRequestId ?? this.advanceRequestId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AdvanceOnSalaryRequestModel {
  final int? id;
  final int? requestorCode;
  final int? borrowerCode;
  final int? n2Code;
  final double? amount;
  final String? status;
  final DateTime? createdAt;
  final DateTime? lastActionAt;
  final String? amountInLettersArabic;
  final String? amountInLettersEnglish;
  final double? monthlyPayment;
  final DateTime? paymentStartDate;
  final DateTime? paymentEndDate;
  final int? periodInMonths;
  final String? currentApprover;
  final String? declineReason;
  final String? requestType;
  final String? pdfUrl;
  final String? pdfFilePath;
  final DateTime? pdfGeneratedAt;
  final String? pdfDocumentId;
  final String? requestorEnglishName;
  final String? requestorArabicName;
  final String? borrowerEnglishName;
  final String? borrowerArabicName;
  final String? n1EnglishName;
  final String? n1ArabicName;
  final String? n2EnglishName;
  final String? n2ArabicName;
  final String? requestorTitle;
  final String? requestorEnglishTitle;
  final String? requestorDepartment;
  final String? requestorEnglishDepartment;
  final String? requestorHireDate;
  final String? borrowerTitle;
  final String? borrowerEnglishTitle;
  final String? borrowerDepartment;
  final String? borrowerEnglishDepartment;
  final String? borrowerHireDate;
  final int? hrApproverCode;
  final int? financeApproverCode;
  final String? hrEnglishName;
  final String? hrArabicName;
  final String? financeEnglishName;
  final String? financeArabicName;
  final DateTime? n2ApprovalDate;
  final DateTime? hrApprovalDate;
  final DateTime? financeApprovalDate;
  final bool? manuallySettled;
  final List<SettlementInfo>? settlementInfo;
  final bool? cancelled;
  // New finance edit fields
  final List<UnscheduledPayment>? unscheduledPayments;
  final List<ScheduledPayment>? scheduledPayments;
  final String? comments;
  final int? updatedPeriod;
  final double? updatedMonthlyPayment;
  final DateTime? updatedPaymentEndDate;
  // Employee confirmation workflow fields
  final bool? requiresEmployeeConfirmation;
  final String? employeeConfirmationStatus; // 'pending', 'confirmed', 'cancelled'
  final DateTime? employeeConfirmationDate;
  final DateTime? financeAcknowledgmentDate;
  // Settlement notification confirmation fields
  final bool? settlementReadyForReview;
  final DateTime? settlementReadyDate;
  final int? settlementConfirmedBy;
  final DateTime? settlementConfirmedDate;
  final bool? settlementNotificationSkipped;
  final int? settlementSkippedBy;
  final DateTime? settlementSkippedDate;
  final bool? settlementNotificationSent;

  String getLocalizedStatus(BuildContext context) {
    // Check if cancelled first, as this overrides the status field
    if (cancelled == true) {
      return AppLocalizations.of(context)!.cancelled;
    } else if (manuallySettled == true) {
      return AppLocalizations.of(context)!.settled;
    } else if (needsEmployeeConfirmation) {
      return AppLocalizations.of(context)!.pendingEmployeeConfirmation;
    }

    switch (status?.toLowerCase()) {
      case 'pending':
        return AppLocalizations.of(context)!.pending;
      case 'approved':
        return AppLocalizations.of(context)!.approved;
      case 'declined':
        return AppLocalizations.of(context)!.declined;
      case 'cancelled':
        return AppLocalizations.of(context)!.cancelled;
    }
    return status!;
  }

  /// Check if PDF has been generated for this request
  bool get hasPDF => pdfFilePath != null && pdfFilePath!.isNotEmpty;

  /// Check if request is cancelled
  bool get isCancelled => cancelled == true;

  /// Check if request is actionable (pending and not cancelled)
  bool get isActionable => status?.toLowerCase() == 'pending' && cancelled != true;

  /// Check if request has been settled
  bool get isSettled => settlementInfo != null && settlementInfo!.isNotEmpty;

  /// Get the most recent settlement info
  SettlementInfo? get latestSettlement =>
      settlementInfo?.isNotEmpty == true
          ? settlementInfo!.reduce((a, b) => a.settlementDate.isAfter(b.settlementDate) ? a : b)
          : null;

  /// Get localized settler name from latest settlement
  String getLatestSettlerName(bool isArabic) {
    final latest = latestSettlement;
    return latest?.getLocalizedSettlerName(isArabic) ?? '';
  }

  DateTime? getLatestSettlementDate() {
    final latest = latestSettlement;
    return latest?.settlementDate;
  }

  /// Check if request is processed (approved, declined, or cancelled)
  // bool get isProcessed =>
  //     status?.toLowerCase() == 'approved' ||
  //     status?.toLowerCase() == 'declined' ||
  //     cancelled == true;

  /// Check if request is fully approved and PDF should be available
  bool get shouldHavePDF => status?.toLowerCase() == 'approved';

  /// Check if request is at finance approval stage (final approval)
  bool get isAtFinanceApproval => currentApprover?.toLowerCase() == 'finance';

  /// Check if PDF generation should be triggered
  bool get shouldGeneratePDF =>
      status?.toLowerCase() == 'approved' && currentApprover?.toLowerCase() == 'finance' && !hasPDF;

  /// Get amount in letters based on locale
  String getAmountInLetters(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? (amountInLettersArabic ?? '') : (amountInLettersEnglish ?? '');
  }

  DateTime get tzCreatedAt {
    if (createdAt == null) {
      throw Exception('createdAt is null');
    }
    final location = tz.getLocation('Africa/Cairo');
    return tz.TZDateTime.from(createdAt!, location);
  }

  String getLocalizedApproverName(
    BuildContext context, {
    String? hrApproverEnglishName,
    String? hrApproverArabicName,
    String? financeApproverEnglishName,
    String? financeApproverArabicName,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String name;

    switch (currentApprover?.toLowerCase()) {
      case 'n1':
        if (isArabic && n1ArabicName != null && n1ArabicName!.isNotEmpty) {
          name = n1ArabicName!;
        } else {
          name = n1EnglishName ?? 'N+1';
        }
        break;
      case 'n2':
        if (isArabic && n2ArabicName != null && n2ArabicName!.isNotEmpty) {
          name = n2ArabicName!;
        } else {
          name = n2EnglishName ?? 'N+2';
        }
        break;
      case 'hr':
        // Use provided approver name if available, otherwise use stored name, fallback to department label
        final englishName = hrApproverEnglishName ?? hrEnglishName;
        final arabicName = hrApproverArabicName ?? hrArabicName;

        if (englishName != null || arabicName != null) {
          name = isArabic ? (arabicName ?? englishName ?? 'HR') : (englishName ?? arabicName ?? 'HR');
        } else {
          // Backward compatibility: show dept name if no approver code
          return isArabic ? 'الموارد البشرية' : 'HR';
        }
        break;
      case 'finance':
        // Use provided approver name if available, otherwise use stored name, fallback to department label
        final englishName = financeApproverEnglishName ?? financeEnglishName;
        final arabicName = financeApproverArabicName ?? financeArabicName;

        if (englishName != null || arabicName != null) {
          name = isArabic ? (arabicName ?? englishName ?? 'Finance') : (englishName ?? arabicName ?? 'Finance');
        } else {
          // Backward compatibility: show dept name if no approver code
          return isArabic ? 'المالية' : 'Finance';
        }
        break;
      default:
        name = currentApprover ?? '';
    }

    // Truncate to 20 characters if longer
    return name.length > 20 ? '${name.substring(0, 20)}...' : name;
  }

  // Business logic functions for finance editing

  /// Get total amount from unscheduled payments
  double get totalUnscheduledPayments => unscheduledPayments?.fold(0.0, (sum, payment) => sum! + payment.amount) ?? 0.0;

  /// Get total amount from scheduled payments
  double get totalScheduledPayments => scheduledPayments?.fold(0.0, (sum, payment) => sum! + payment.amount) ?? 0.0;

  /// Get remaining amount after both unscheduled and scheduled payments
  /// Returns 0 if the calculated amount is negative (overpayment scenario)
  double get remainingAmount {
    final calculated = (amount ?? 0.0) - totalUnscheduledPayments - totalScheduledPayments;
    return calculated < 0 ? 0.0 : calculated;
  }

  /// Get the current effective monthly payment based on remaining amount and months
  double? get currentMonthlyPayment {
    // If there are no unscheduled payments, use the updated or original monthly payment
    if (totalUnscheduledPayments == 0) {
      return updatedMonthlyPayment ?? monthlyPayment;
    }

    // If there are unscheduled payments, calculate dynamically
    final remaining = remainingAmount;
    if (remaining <= 0) {
      return 0.0; // Loan is fully paid
    }

    // Calculate remaining months from now until payment end date
    final monthsRemaining = remainingMonths;
    if (monthsRemaining == null) {
      return null; // No valid end date or already expired
    }

    // Return calculated monthly payment
    return remaining / monthsRemaining;
  }

  /// Get remaining months from now until payment end date
  int? get remainingMonths {
    final now = DateTime.now();
    final effictiveDate = paymentStartDate!.isBefore(now) == true ? now : paymentStartDate;
    final endDate = updatedPaymentEndDate ?? paymentEndDate;

    if (endDate == null || endDate.isBefore(now)) {
      return null; // No valid end date or already expired
    }

    // Calculate months remaining (excluding current month if start date is before now)
    return paymentStartDate!.isBefore(now) == true
        ? ((endDate.year - effictiveDate!.year) * 12 + endDate.month - effictiveDate.month)
        : ((endDate.year - effictiveDate!.year) * 12 + endDate.month - effictiveDate.month + 1);
  }

  /// Check if period has been modified by finance
  bool get hasPeriodBeenModified => periodInMonths != null && periodInMonths != updatedPeriod;

  /// Check if request requires employee confirmation
  bool get needsEmployeeConfirmation => requiresEmployeeConfirmation == true && employeeConfirmationStatus == 'pending';

  /// Check if employee has confirmed the finance edit
  bool get isEmployeeConfirmed => employeeConfirmationStatus == 'confirmed';

  /// Check if employee has cancelled the finance edit
  bool get isEmployeeCancelled => employeeConfirmationStatus == 'cancelled';

  /// Check if finance has acknowledged employee decision
  bool get isFinanceAcknowledged => financeAcknowledgmentDate != null;

  /// Check if request needs finance acknowledgment
  bool get needsFinanceAcknowledgment => (isEmployeeConfirmed || isEmployeeCancelled) && !isFinanceAcknowledged;

  /// Check if request is ready for settlement review by finance
  bool get isReadyForSettlementReview =>
      settlementReadyForReview == true && settlementNotificationSent != true && settlementNotificationSkipped != true;

  /// Check if monthly payment has been modified
  bool get hasMonthlyPaymentBeenModified => monthlyPayment != null && monthlyPayment != updatedMonthlyPayment;

  /// Get effective period (updated if available, otherwise original)
  int? get effectivePeriodInMonths => updatedPeriod ?? periodInMonths;

  /// Get effective monthly payment (updated if available, otherwise original)
  double? get effectiveMonthlyPayment => updatedMonthlyPayment ?? monthlyPayment;

  /// Get effective payment end date (updated if available, otherwise original)
  DateTime? get effectivePaymentEndDate => updatedPaymentEndDate ?? paymentEndDate;

  /// Calculate payment end date aligned to first day of the month
  static DateTime calculateEndDateFromStartAndPeriod(DateTime startDate, int periodInMonths) {
    // Add the period to start date
    final rawEndDate = DateTime(
      startDate.year,
      startDate.month + periodInMonths - 1,
      1, // Always first day of the month
    );

    // If the raw calculation goes to a month where the original start date
    // would be after the first, move to the next month
    // Example: Start on 15th, period 3 months -> ensure end is at least 3 full months
    return rawEndDate;
  }

  /// Recalculate payment schedule with new period
  AdvanceOnSalaryRequestModel recalculateWithNewPeriod(int newPeriodInMonths) {
    if (amount == null || paymentStartDate == null) return this;

    final newMonthlyPayment = amount! / newPeriodInMonths;
    final newPaymentEndDate = calculateEndDateFromStartAndPeriod(paymentStartDate!, newPeriodInMonths);

    return copyWith(
      updatedPeriod: newPeriodInMonths,
      updatedMonthlyPayment: newMonthlyPayment,
      updatedPaymentEndDate: newPaymentEndDate,
    );
  }

  /// Add a change log entry to comments
  AdvanceOnSalaryRequestModel addChangeLog(String change) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    final newChange = "[$timestamp] $change";
    final updatedComments = comments != null ? "$comments\n$newChange" : newChange;

    return copyWith(comments: updatedComments);
  }

  /// Add a bilingual change log entry to comments
  AdvanceOnSalaryRequestModel addBilingualChangeLog({required String englishChange, required String arabicChange}) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    final newChange = "[$timestamp] EN: $englishChange | AR: $arabicChange";
    final updatedComments = comments != null ? "$comments\n$newChange" : newChange;

    return copyWith(comments: updatedComments);
  }

  /// Calculate new end date based on remaining amount and monthly payment (aligned to month start)
  DateTime? calculateAdjustedEndDate() {
    if (remainingAmount <= 0) {
      // Can finish immediately - set to next month's first day
      final now = DateTime.now();
      return DateTime(now.year, now.month + 1, 1);
    }

    if (monthlyPayment == null || monthlyPayment! <= 0 || paymentStartDate == null) {
      return paymentEndDate;
    }

    final monthsRemaining = (remainingAmount / monthlyPayment!).ceil();
    return calculateEndDateFromStartAndPeriod(paymentStartDate!, monthsRemaining);
  }

  AdvanceOnSalaryRequestModel({
    this.id,
    this.requestorCode,
    this.borrowerCode,
    this.n2Code,
    this.amount,
    this.status,
    this.createdAt,
    this.lastActionAt,
    this.amountInLettersArabic,
    this.amountInLettersEnglish,
    this.monthlyPayment,
    this.paymentStartDate,
    this.paymentEndDate,
    this.periodInMonths,
    this.currentApprover,
    this.declineReason,
    this.requestType = 'advance_on_salary',
    this.pdfUrl,
    this.pdfFilePath,
    this.pdfGeneratedAt,
    this.pdfDocumentId,
    this.requestorEnglishName,
    this.requestorArabicName,
    this.borrowerEnglishName,
    this.borrowerArabicName,
    this.n1EnglishName,
    this.n1ArabicName,
    this.n2EnglishName,
    this.n2ArabicName,
    this.requestorTitle,
    this.requestorEnglishTitle,
    this.requestorDepartment,
    this.requestorEnglishDepartment,
    this.requestorHireDate,
    this.borrowerTitle,
    this.borrowerEnglishTitle,
    this.borrowerDepartment,
    this.borrowerEnglishDepartment,
    this.borrowerHireDate,
    this.hrApproverCode,
    this.financeApproverCode,
    this.hrEnglishName,
    this.hrArabicName,
    this.financeEnglishName,
    this.financeArabicName,
    this.n2ApprovalDate,
    this.hrApprovalDate,
    this.financeApprovalDate,
    this.manuallySettled,
    this.settlementInfo,
    this.cancelled,
    this.unscheduledPayments,
    this.scheduledPayments,
    this.comments,
    this.updatedPeriod,
    this.updatedMonthlyPayment,
    this.updatedPaymentEndDate,
    this.requiresEmployeeConfirmation,
    this.employeeConfirmationStatus,
    this.employeeConfirmationDate,
    this.financeAcknowledgmentDate,
    this.settlementReadyForReview,
    this.settlementReadyDate,
    this.settlementConfirmedBy,
    this.settlementConfirmedDate,
    this.settlementNotificationSkipped,
    this.settlementSkippedBy,
    this.settlementSkippedDate,
    this.settlementNotificationSent,
  });

  factory AdvanceOnSalaryRequestModel.fromJson(Map<String, dynamic> json) {
    return AdvanceOnSalaryRequestModel(
      id: json['id'],
      requestorCode: json['requestor_code'],
      borrowerCode: json['borrower_code'],
      n2Code: json['n2_code'],
      amount: json['amount'],
      status: json['status'],
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      lastActionAt: DateTime.tryParse(json['last_action_at'] ?? ''),
      amountInLettersArabic: json['amount_in_letters_arabic'],
      amountInLettersEnglish: json['amount_in_letters_english'],
      monthlyPayment: json['monthly_payment'],
      paymentStartDate: DateTime.tryParse(json['payment_start_date'] ?? ''),
      paymentEndDate: DateTime.tryParse(json['payment_end_date'] ?? ''),
      periodInMonths: json['period_in_months'],
      currentApprover: json['current_approver'],
      declineReason: json['decline_reason'],
      pdfFilePath: json['final_pdf_url'],
      requestorEnglishName: json['requestor_english_name'],
      requestorArabicName: json['requestor_arabic_name'],
      borrowerEnglishName: json['borrower_english_name'],
      borrowerArabicName: json['borrower_arabic_name'],
      n1EnglishName: json['n1']?['English Name'],
      n1ArabicName: json['n1']?['Arabic Name'],
      n2EnglishName: json['n2']?['English Name'],
      n2ArabicName: json['n2']?['Arabic Name'],
      requestorTitle: json['requestor']?['Title'],
      requestorEnglishTitle: json['requestor']?['english_title'],
      requestorDepartment: json['requestor']?['Department'],
      requestorEnglishDepartment: json['requestor']?['english_department'],
      requestorHireDate: json['requestor']?['Hire Date'],
      borrowerTitle: json['borrower']?['Title'],
      borrowerEnglishTitle: json['borrower']?['english_title'],
      borrowerDepartment: json['borrower']?['Department'],
      borrowerEnglishDepartment: json['borrower']?['english_department'],
      borrowerHireDate: json['borrower']?['Hire Date'],
      hrApproverCode: json['hr_approver_code'],
      financeApproverCode: json['finance_approver_code'],
      hrEnglishName: json['hr_english_name'],
      hrArabicName: json['hr_arabic_name'],
      financeEnglishName: json['finance_english_name'],
      financeArabicName: json['finance_arabic_name'],
      n2ApprovalDate: DateTime.tryParse(json['n2_approval_date'] ?? ''),
      hrApprovalDate: DateTime.tryParse(json['hr_approval_date'] ?? ''),
      financeApprovalDate: DateTime.tryParse(json['finance_approval_date'] ?? ''),
      manuallySettled: json['manually_settled'],
      settlementInfo:
          json['settlement_info'] != null
              ? (json['settlement_info'] as List).map((info) => SettlementInfo.fromJson(info)).toList()
              : null,
      cancelled: json['cancelled'],
      unscheduledPayments:
          json['unscheduled_payments'] != null
              ? (json['unscheduled_payments'] as List).map((payment) => UnscheduledPayment.fromJson(payment)).toList()
              : null,
      scheduledPayments:
          json['scheduled_payments'] != null
              ? (json['scheduled_payments'] as List).map((payment) => ScheduledPayment.fromJson(payment)).toList()
              : null,
      comments: json['comments'],
      updatedPeriod: json['updated_period'],
      updatedMonthlyPayment: json['updated_monthly_payment']?.toDouble(),
      updatedPaymentEndDate: DateTime.tryParse(json['updated_payment_end_date'] ?? ''),
      requiresEmployeeConfirmation: json['requires_employee_confirmation'],
      employeeConfirmationStatus: json['employee_confirmation_status'],
      employeeConfirmationDate: DateTime.tryParse(json['employee_confirmation_date'] ?? ''),
      financeAcknowledgmentDate: DateTime.tryParse(json['finance_acknowledgment_date'] ?? ''),
      settlementReadyForReview: json['settlement_ready_for_review'],
      settlementReadyDate: DateTime.tryParse(json['settlement_ready_date'] ?? ''),
      settlementConfirmedBy: json['settlement_confirmed_by'],
      settlementConfirmedDate: DateTime.tryParse(json['settlement_confirmed_date'] ?? ''),
      settlementNotificationSkipped: json['settlement_notification_skipped'],
      settlementSkippedBy: json['settlement_skipped_by'],
      settlementSkippedDate: DateTime.tryParse(json['settlement_skipped_date'] ?? ''),
      settlementNotificationSent: json['settlement_notification_sent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestor_code': requestorCode,
      'borrower_code': borrowerCode,
      'n2_code': n2Code,
      'amount': amount,
      'payment_start_date': paymentStartDate?.toIso8601String(),
      'period_in_months': periodInMonths,
      'payment_end_date': paymentEndDate?.toIso8601String(),
      'monthly_payment': monthlyPayment,
      'amount_in_letters_arabic': amountInLettersArabic,
      'amount_in_letters_english': amountInLettersEnglish,
      if (currentApprover != null) 'current_approver': currentApprover,
      if (status != null) 'status': status,
      'pdf_url': pdfUrl,
      'pdf_generated_at': pdfGeneratedAt?.toIso8601String(),
      'comments': comments,
      'updated_period': updatedPeriod,
      'updated_monthly_payment': updatedMonthlyPayment,
      'updated_payment_end_date': updatedPaymentEndDate?.toIso8601String(),
      'requires_employee_confirmation': requiresEmployeeConfirmation,
      'employee_confirmation_status': employeeConfirmationStatus,
      'employee_confirmation_date': employeeConfirmationDate?.toIso8601String(),
      'finance_acknowledgment_date': financeAcknowledgmentDate?.toIso8601String(),
      'settlement_ready_for_review': settlementReadyForReview,
      'settlement_ready_date': settlementReadyDate?.toIso8601String(),
      'settlement_confirmed_by': settlementConfirmedBy,
      'settlement_confirmed_date': settlementConfirmedDate?.toIso8601String(),
      'settlement_notification_skipped': settlementNotificationSkipped,
      'settlement_skipped_by': settlementSkippedBy,
      'settlement_skipped_date': settlementSkippedDate?.toIso8601String(),
      'settlement_notification_sent': settlementNotificationSent,
    };
  }

  AdvanceOnSalaryRequestModel copyWith({
    int? id,
    int? requestorCode,
    int? borrowerCode,
    int? n2Code,
    double? amount,
    String? status,
    DateTime? createdAt,
    DateTime? lastActionAt,
    String? amountInLettersArabic,
    String? amountInLettersEnglish,
    double? monthlyPayment,
    DateTime? paymentStartDate,
    DateTime? paymentEndDate,
    int? periodInMonths,
    String? currentApprover,
    String? declineReason,
    String? requestType,
    String? pdfUrl,
    String? pdfFilePath,
    DateTime? pdfGeneratedAt,
    String? pdfDocumentId,
    String? requestorEnglishName,
    String? requestorArabicName,
    String? borrowerEnglishName,
    String? borrowerArabicName,
    String? n1EnglishName,
    String? n1ArabicName,
    String? n2EnglishName,
    String? n2ArabicName,
    String? requestorTitle,
    String? requestorEnglishTitle,
    String? requestorDepartment,
    String? requestorEnglishDepartment,
    String? requestorHireDate,
    String? borrowerTitle,
    String? borrowerEnglishTitle,
    String? borrowerDepartment,
    String? borrowerEnglishDepartment,
    String? borrowerHireDate,
    int? hrApproverCode,
    int? financeApproverCode,
    String? hrEnglishName,
    String? hrArabicName,
    String? financeEnglishName,
    String? financeArabicName,
    DateTime? n2ApprovalDate,
    DateTime? hrApprovalDate,
    DateTime? financeApprovalDate,
    bool? manuallySettled,
    List<SettlementInfo>? settlementInfo,
    bool? cancelled,
    List<UnscheduledPayment>? unscheduledPayments,
    List<ScheduledPayment>? scheduledPayments,
    String? comments,
    int? updatedPeriod,
    double? updatedMonthlyPayment,
    DateTime? updatedPaymentEndDate,
    bool? requiresEmployeeConfirmation,
    String? employeeConfirmationStatus,
    DateTime? employeeConfirmationDate,
    DateTime? financeAcknowledgmentDate,
    bool? settlementReadyForReview,
    DateTime? settlementReadyDate,
    int? settlementConfirmedBy,
    DateTime? settlementConfirmedDate,
    bool? settlementNotificationSkipped,
    int? settlementSkippedBy,
    DateTime? settlementSkippedDate,
    bool? settlementNotificationSent,
  }) {
    return AdvanceOnSalaryRequestModel(
      id: id ?? this.id,
      requestorCode: requestorCode ?? this.requestorCode,
      borrowerCode: borrowerCode ?? this.borrowerCode,
      n2Code: n2Code ?? this.n2Code,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      amountInLettersArabic: amountInLettersArabic ?? this.amountInLettersArabic,
      amountInLettersEnglish: amountInLettersEnglish ?? this.amountInLettersEnglish,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      paymentStartDate: paymentStartDate ?? this.paymentStartDate,
      paymentEndDate: paymentEndDate ?? this.paymentEndDate,
      periodInMonths: periodInMonths ?? this.periodInMonths,
      currentApprover: currentApprover ?? this.currentApprover,
      declineReason: declineReason ?? this.declineReason,
      requestType: requestType ?? this.requestType,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfFilePath: pdfFilePath ?? this.pdfFilePath,
      pdfGeneratedAt: pdfGeneratedAt ?? this.pdfGeneratedAt,
      pdfDocumentId: pdfDocumentId ?? this.pdfDocumentId,
      requestorEnglishName: requestorEnglishName ?? this.requestorEnglishName,
      requestorArabicName: requestorArabicName ?? this.requestorArabicName,
      borrowerEnglishName: borrowerEnglishName ?? this.borrowerEnglishName,
      borrowerArabicName: borrowerArabicName ?? this.borrowerArabicName,
      n1EnglishName: n1EnglishName ?? this.n1EnglishName,
      n1ArabicName: n1ArabicName ?? this.n1ArabicName,
      n2EnglishName: n2EnglishName ?? this.n2EnglishName,
      n2ArabicName: n2ArabicName ?? this.n2ArabicName,
      requestorTitle: requestorTitle ?? this.requestorTitle,
      requestorEnglishTitle: requestorEnglishTitle ?? this.requestorEnglishTitle,
      requestorDepartment: requestorDepartment ?? this.requestorDepartment,
      requestorEnglishDepartment: requestorEnglishDepartment ?? this.requestorEnglishDepartment,
      requestorHireDate: requestorHireDate ?? this.requestorHireDate,
      borrowerTitle: borrowerTitle ?? this.borrowerTitle,
      borrowerEnglishTitle: borrowerEnglishTitle ?? this.borrowerEnglishTitle,
      borrowerDepartment: borrowerDepartment ?? this.borrowerDepartment,
      borrowerEnglishDepartment: borrowerEnglishDepartment ?? this.borrowerEnglishDepartment,
      borrowerHireDate: borrowerHireDate ?? this.borrowerHireDate,
      hrApproverCode: hrApproverCode ?? this.hrApproverCode,
      financeApproverCode: financeApproverCode ?? this.financeApproverCode,
      hrEnglishName: hrEnglishName ?? this.hrEnglishName,
      hrArabicName: hrArabicName ?? this.hrArabicName,
      financeEnglishName: financeEnglishName ?? this.financeEnglishName,
      financeArabicName: financeArabicName ?? this.financeArabicName,
      n2ApprovalDate: n2ApprovalDate ?? this.n2ApprovalDate,
      hrApprovalDate: hrApprovalDate ?? this.hrApprovalDate,
      financeApprovalDate: financeApprovalDate ?? this.financeApprovalDate,
      manuallySettled: manuallySettled ?? this.manuallySettled,
      settlementInfo: settlementInfo ?? this.settlementInfo,
      cancelled: cancelled ?? this.cancelled,
      unscheduledPayments: unscheduledPayments ?? this.unscheduledPayments,
      scheduledPayments: scheduledPayments ?? this.scheduledPayments,
      comments: comments ?? this.comments,
      updatedPeriod: updatedPeriod ?? this.updatedPeriod,
      updatedMonthlyPayment: updatedMonthlyPayment ?? this.updatedMonthlyPayment,
      updatedPaymentEndDate: updatedPaymentEndDate ?? this.updatedPaymentEndDate,
      requiresEmployeeConfirmation: requiresEmployeeConfirmation ?? this.requiresEmployeeConfirmation,
      employeeConfirmationStatus: employeeConfirmationStatus ?? this.employeeConfirmationStatus,
      employeeConfirmationDate: employeeConfirmationDate ?? this.employeeConfirmationDate,
      financeAcknowledgmentDate: financeAcknowledgmentDate ?? this.financeAcknowledgmentDate,
      settlementReadyForReview: settlementReadyForReview ?? this.settlementReadyForReview,
      settlementReadyDate: settlementReadyDate ?? this.settlementReadyDate,
      settlementConfirmedBy: settlementConfirmedBy ?? this.settlementConfirmedBy,
      settlementConfirmedDate: settlementConfirmedDate ?? this.settlementConfirmedDate,
      settlementNotificationSkipped: settlementNotificationSkipped ?? this.settlementNotificationSkipped,
      settlementSkippedBy: settlementSkippedBy ?? this.settlementSkippedBy,
      settlementSkippedDate: settlementSkippedDate ?? this.settlementSkippedDate,
      settlementNotificationSent: settlementNotificationSent ?? this.settlementNotificationSent,
    );
  }
}
