import 'package:hrms_demo/core/constants/department.dart';
import 'package:hrms_demo/core/constants/violation_category.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stat_widgets.dart';
import 'package:flutter/material.dart';

/// Localizes the raw values the `stats_*` RPCs return (`'missing_punching'`,
/// `'on_hold'`, `'n1'`, …) for display inside charts.
///
/// The RPCs deliberately return raw keys rather than display text — aggregation
/// is locale-agnostic — so translation happens here, at the edge. Wherever the
/// app already knows how to localize a domain value (violation categories,
/// disciplinary action types, departments) this delegates to that existing
/// helper instead of duplicating the mapping.
///
/// Every mapper falls back to [humanize] for an unrecognized value, so a new
/// status or request type added server-side degrades to a readable label rather
/// than crashing or rendering blank.
class StatsLabels {
  StatsLabels._();

  /// Normalized status: approved | pending | on_hold | declined | cancelled.
  static String status(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;
    switch (raw.toLowerCase().trim()) {
      case 'approved':
        return l10n.approved;
      case 'pending':
        return l10n.pending;
      case 'on_hold':
        return l10n.onHold;
      case 'declined':
        return l10n.declined;
      case 'cancelled':
        return l10n.cancelled;
      case 'unknown':
        return l10n.statsUnknown;
      default:
        return humanize(raw);
    }
  }

  /// Approver role (the desk a request sits at) — not a person's name.
  static String approver(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;
    switch (raw.toLowerCase().trim()) {
      case 'n1':
        return l10n.statsApproverN1;
      case 'n2':
        return l10n.statsApproverN2;
      case 'hr':
        return l10n.statsApproverHr;
      case 'finance':
        return l10n.statsApproverFinance;
      case 'legal':
        return l10n.statsApproverLegal;
      case 'top_management':
        return l10n.topManagement;
      case 'employee':
        return l10n.statsApproverEmployee;
      case 'none':
        return l10n.statsApproverNone;
      default:
        return humanize(raw);
    }
  }

  /// `requestType` as stored on the request models.
  static String requestType(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;
    switch (raw.toLowerCase().trim()) {
      case 'leave':
        return l10n.leave;
      case 'business_trip':
        return l10n.businessTrip;
      case 'overtime':
        return l10n.overtime;
      case 'missing_punching':
        return l10n.missingPunching;
      case 'advance_on_salary':
        return l10n.advanceOnSalary;
      case 'disciplinary_action':
        return l10n.disciplinaryAction;
      case 'investigation':
        return l10n.investigation;
      case 'hr_letter':
        return l10n.hrLetter;
      case 'leave_cancellation':
        return l10n.statsLeaveCancellation;
      case 'businesstrip_cancellation':
        return l10n.statsBusinesstripCancellation;
      default:
        return humanize(raw);
    }
  }

  /// `leave_requests.leave_type` (stored capitalized: 'Annual', 'Sick', …).
  static String leaveType(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;
    switch (raw.toLowerCase().trim()) {
      case 'annual':
        return l10n.annual;
      case 'emergency':
        return l10n.emergency;
      case 'compensation':
        return l10n.compensation;
      case 'sick':
        return l10n.sick;
      case 'unpaid':
        return l10n.unpaid;
      default:
        return humanize(raw);
    }
  }

  /// Delegates to the app's existing [ViolationCategory] localization.
  static String violationCategory(BuildContext context, String raw) =>
      ViolationCategory.fromString(raw.toLowerCase().trim()).getLocalizedName(context);

  /// Delegates to [DisciplinaryActionType], guarding its `fromString` — that
  /// helper uses `firstWhere` with no `orElse` and throws on anything it doesn't
  /// know, and the RPC emits 'unknown' for a null action_type.
  static String actionType(BuildContext context, String raw) {
    final key = raw.toLowerCase().trim();
    final match = DisciplinaryActionType.values.where((t) => t.value == key);
    if (match.isEmpty) {
      return key == 'unknown' ? AppLocalizations.of(context)!.statsUnknown : humanize(raw);
    }
    return match.first.getLocalizedName(context);
  }

  /// Department name, preferring [arabicName] — the value stored alongside
  /// english_department on `users` and returned by the RPCs.
  ///
  /// Do NOT rely on the [Department] enum to translate these: the stored English
  /// names don't all match it ("Project Department" vs the enum's "Projects
  /// Department"), and its Arabic spellings differ too ("إدارة" vs the stored
  /// "ادارة"), so enum lookups silently fall through to English. The DB is the
  /// source of truth; the enum is only a last-ditch fallback for rows with no
  /// Arabic name recorded.
  static String department(BuildContext context, String englishName, [String? arabicName]) {
    if (Localizations.localeOf(context).languageCode != 'ar') return englishName;
    if (arabicName != null && arabicName.trim().isNotEmpty) return arabicName;
    return Department.getArabicFromEnglish(englishName) ?? englishName;
  }

  /// Funnel stage: submitted | n1 | n2 | hr | finalized. The middle stages are
  /// approver desks, so they reuse [approver].
  static String funnelStage(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;
    switch (raw.toLowerCase().trim()) {
      case 'submitted':
        return l10n.statsStageSubmitted;
      case 'finalized':
        return l10n.statsStageFinalized;
      default:
        return approver(context, raw);
    }
  }

  /// Tenure bands as emitted by `stats_tenure_buckets`.
  static String tenureBucket(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;
    switch (raw.trim()) {
      case '< 1 yr':
        return l10n.statsTenureUnder1;
      case '1-2 yr':
        return l10n.statsTenure1to2;
      case '2-4 yr':
        return l10n.statsTenure2to4;
      case '4+ yr':
        return l10n.statsTenure4plus;
      case 'Unknown':
        return l10n.statsUnknown;
      default:
        return raw;
    }
  }
}
