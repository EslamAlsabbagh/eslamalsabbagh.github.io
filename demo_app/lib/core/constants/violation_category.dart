import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Violation categories for disciplinary actions
enum ViolationCategory {
  attendance('attendance'),
  conduct('conduct'),
  performance('performance'),
  safety('safety'),
  policy('policy'),
  other('other');

  const ViolationCategory(this.value);
  final String value;

  static ViolationCategory fromString(String value) {
    return ViolationCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ViolationCategory.other,
    );
  }

  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case ViolationCategory.attendance:
        return l10n.categoryAttendance;
      case ViolationCategory.conduct:
        return l10n.categoryConduct;
      case ViolationCategory.performance:
        return l10n.categoryPerformance;
      case ViolationCategory.safety:
        return l10n.categorySafety;
      case ViolationCategory.policy:
        return l10n.categoryPolicy;
      case ViolationCategory.other:
        return l10n.categoryOther;
    }
  }

  bool get isOther => this == ViolationCategory.other;
}

/// Represents a violation with bilingual support
class Violation {
  final String key;
  final String englishName;
  final String arabicName;

  const Violation({required this.key, required this.englishName, required this.arabicName});

  String getLocalizedName(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? arabicName : englishName;
  }
}

/// Static violations data organized by category
class ViolationData {
  static const Map<ViolationCategory, List<Violation>> violationsByCategory = {
    ViolationCategory.attendance: [
      Violation(key: 'late_arrival', englishName: 'Late Arrival', arabicName: 'التأخر في الحضور'),
      Violation(key: 'early_departure', englishName: 'Early Departure', arabicName: 'المغادرة المبكرة'),
      Violation(key: 'unauthorized_absence', englishName: 'Unauthorized Absence', arabicName: 'الغياب غير المصرح به'),
      Violation(key: 'excessive_breaks', englishName: 'Excessive Breaks', arabicName: 'الاستراحات المفرطة'),
      Violation(
        key: 'failure_to_clock',
        englishName: 'Failure to Clock In/Out',
        arabicName: 'عدم تسجيل الحضور/الانصراف',
      ),
    ],
    ViolationCategory.conduct: [
      Violation(key: 'insubordination', englishName: 'Insubordination', arabicName: 'عدم الامتثال للأوامر'),
      Violation(key: 'harassment', englishName: 'Harassment', arabicName: 'التحرش'),
      Violation(
        key: 'unprofessional_behavior',
        englishName: 'Unprofessional Behavior',
        arabicName: 'السلوك غير المهني',
      ),
      Violation(
        key: 'conflict_with_colleagues',
        englishName: 'Conflict with Colleagues',
        arabicName: 'الخلاف مع الزملاء',
      ),
      Violation(
        key: 'inappropriate_language',
        englishName: 'Inappropriate Language',
        arabicName: 'استخدام لغة غير لائقة',
      ),
    ],
    ViolationCategory.performance: [
      Violation(
        key: 'failure_to_meet_targets',
        englishName: 'Failure to Meet Targets',
        arabicName: 'عدم تحقيق الأهداف',
      ),
      Violation(key: 'poor_quality_work', englishName: 'Poor Quality Work', arabicName: 'جودة عمل ضعيفة'),
      Violation(
        key: 'missed_deadlines',
        englishName: 'Missed Deadlines',
        arabicName: 'عدم الالتزام بالمواعيد النهائية',
      ),
      Violation(key: 'lack_of_productivity', englishName: 'Lack of Productivity', arabicName: 'نقص الإنتاجية'),
      Violation(key: 'negligence', englishName: 'Negligence', arabicName: 'الإهمال'),
    ],
    ViolationCategory.safety: [
      Violation(
        key: 'safety_protocol_violation',
        englishName: 'Safety Protocol Violation',
        arabicName: 'مخالفة بروتوكولات السلامة',
      ),
      Violation(key: 'unsafe_behavior', englishName: 'Unsafe Behavior', arabicName: 'السلوك غير الآمن'),
      Violation(
        key: 'failure_to_report_hazard',
        englishName: 'Failure to Report Hazard',
        arabicName: 'عدم الإبلاغ عن المخاطر',
      ),
      Violation(
        key: 'improper_equipment_use',
        englishName: 'Improper Equipment Use',
        arabicName: 'الاستخدام غير السليم للمعدات',
      ),
    ],
    ViolationCategory.policy: [
      Violation(key: 'dress_code_violation', englishName: 'Dress Code Violation', arabicName: 'مخالفة قواعد الزي'),
      Violation(
        key: 'misuse_of_equipment',
        englishName: 'Misuse of Company Equipment',
        arabicName: 'إساءة استخدام معدات الشركة',
      ),
      Violation(key: 'confidentiality_breach', englishName: 'Confidentiality Breach', arabicName: 'انتهاك السرية'),
      Violation(
        key: 'social_media_policy_violation',
        englishName: 'Social Media Policy Violation',
        arabicName: 'مخالفة سياسة وسائل التواصل الاجتماعي',
      ),
      Violation(key: 'unauthorized_access', englishName: 'Unauthorized Access', arabicName: 'الوصول غير المصرح به'),
    ],
  };

  /// Get violations for a specific category
  static List<Violation> getViolationsForCategory(ViolationCategory category) {
    return violationsByCategory[category] ?? [];
  }

  /// Find a violation by its key across all categories
  static Violation? findViolationByKey(String key) {
    for (final violations in violationsByCategory.values) {
      for (final violation in violations) {
        if (violation.key == key) {
          return violation;
        }
      }
    }
    return null;
  }
}
