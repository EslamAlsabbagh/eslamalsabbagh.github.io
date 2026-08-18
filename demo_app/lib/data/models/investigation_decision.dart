import 'package:equatable/equatable.dart';

/// Represents a decision made for an employee in an investigation.
///
/// This model stores the outcome of an investigation for a specific employee,
/// including the decision type and an optional reference to a created disciplinary action.
class InvestigationDecision extends Equatable {
  /// The employee code for whom this decision was made
  final int employeeCode;

  /// The decision type for this employee
  /// Possible values: 'cleared', 'verbal_warning', 'written_warning',
  /// 'suspension', 'termination', 'take_action'
  final String decision;

  /// Reference to the created disciplinary action ID if applicable
  /// This is populated when a disciplinary action is created from this decision
  final int? disciplinaryId;

  /// Optional comment/justification for this decision
  final String? comment;

  /// The DA action type when decision is 'take_action'
  /// e.g. 'verbal_warning', 'written_warning', 'verbal_remark', 'written_remark'
  final String? daType;

  /// Deduction days for written_warning DA type (if applicable)
  final double? deductDays;

  const InvestigationDecision({
    required this.employeeCode,
    required this.decision,
    this.disciplinaryId,
    this.comment,
    this.daType,
    this.deductDays,
  });

  @override
  List<Object?> get props => [employeeCode, decision, disciplinaryId, comment, daType, deductDays];

  /// Converts this decision to a JSON map for database storage
  Map<String, dynamic> toJson() => {
        'employee_code': employeeCode,
        'decision': decision,
        if (disciplinaryId != null) 'disciplinary_id': disciplinaryId,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
        if (daType != null) 'da_type': daType,
        if (deductDays != null) 'deduct_days': deductDays,
      };

  /// Creates an InvestigationDecision from a JSON map
  factory InvestigationDecision.fromJson(Map<String, dynamic> json) {
    return InvestigationDecision(
      employeeCode: json['employee_code'] as int,
      decision: json['decision'] as String,
      disciplinaryId: json['disciplinary_id'] as int?,
      comment: json['comment'] as String?,
      daType: json['da_type'] as String?,
      deductDays: (json['deduct_days'] as num?)?.toDouble(),
    );
  }

  /// Creates a copy of this decision with the given fields replaced
  InvestigationDecision copyWith({
    int? employeeCode,
    String? decision,
    int? disciplinaryId,
    String? comment,
    String? daType,
    double? deductDays,
  }) {
    return InvestigationDecision(
      employeeCode: employeeCode ?? this.employeeCode,
      decision: decision ?? this.decision,
      disciplinaryId: disciplinaryId ?? this.disciplinaryId,
      comment: comment ?? this.comment,
      daType: daType ?? this.daType,
      deductDays: deductDays ?? this.deductDays,
    );
  }

  @override
  String toString() =>
      'InvestigationDecision(employeeCode: $employeeCode, decision: $decision, disciplinaryId: $disciplinaryId, comment: $comment)';
}
