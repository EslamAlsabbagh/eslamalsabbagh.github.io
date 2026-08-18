import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Spacing rhythm the whole builder follows (the app has no spacing tokens, so
/// these mirror its de-facto 4 / 8 / 12 / 16 / 24 scale in one place).
class OrgGap {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
}

/// Self-contained bilingual chrome strings for the builder. Deliberately NOT in
/// the app's generated l10n: this screen's static text is small and localized
/// off the GLOBAL locale (`ar` vs anything-else), so we avoid editing the large
/// .arb files + regenerating for a single feature. Entity NAMES use the separate
/// 3-way OrgLang toggle (see org_labels.dart); this is only the fixed chrome.
class OrgStrings {
  final bool ar;
  const OrgStrings(this.ar);
  factory OrgStrings.of(BuildContext c) => OrgStrings(Localizations.localeOf(c).languageCode == 'ar');

  String get t => ar ? 'ar' : 'en';
  String _p(String en, String arabic) => ar ? arabic : en;

  String get title => _p('Org Structure Builder', 'منشئ الهيكل التنظيمي');
  String get subtitle => _p('Locations, departments, positions', 'المواقع والإدارات والمناصب');

  String get statLocations => _p('Locations', 'المواقع');
  String get statDepartments => _p('Departments', 'الإدارات');
  String get statLinks => _p('Links', 'الروابط');
  String get statPositions => _p('Positions', 'المناصب');

  String get departments => _p('Departments', 'الإدارات');
  String get dragToReorganize => _p('drag to reorganize', 'اسحب لإعادة الترتيب');
  String get dropHereTopLevel => _p('drop here to make top-level', 'أفلت هنا لجعلها رئيسية');
  String get addTopLevel => _p('Add top-level department', 'إضافة إدارة رئيسية');
  String get addSubDepartment => _p('Add sub-department', 'إضافة إدارة فرعية');

  String get locations => _p('Locations', 'المواقع');
  String get addLocation => _p('Location', 'موقع');

  String get presentAt => _p('Present at these locations', 'موجودة في هذه المواقع');
  String get topLevelDepartment => _p('Top-level department', 'إدارة رئيسية');
  String get selectDeptPrompt =>
      _p('Select a department to manage its locations and positions', 'اختر إدارة لإدارة مواقعها ومناصبها');

  String get manager => _p('Manager', 'المدير');
  String get noManager => _p('No manager', 'لا يوجد مدير');
  String get addPosition => _p('Position', 'منصب');
  String get copyFromLocation => _p('Copy from…', 'نسخ من…');
  String get copyFromLocationTip => _p('Copy all positions from another location', 'انسخ كل المناصب من موقع آخر');
  String get dropHereRemoveManager => _p('drop here to remove manager (top-level)', 'أفلت هنا لإزالة المدير');
  String get noPositionsYet => _p('No positions yet — add one', 'لا توجد مناصب بعد — أضف واحدًا');

  String get collapseRepeats => _p('Collapse repeated positions', 'دمج المناصب المتكررة');
  String get expandRepeats => _p('Expand repeated positions', 'إظهار المناصب المتكررة');
  String get addOne => _p('Add one', 'إضافة واحد');
  String get removeOne => _p('Remove one', 'إزالة واحد');
  String deleteAll(int n) => _p('Delete all $n', 'حذف الكل ($n)');

  String get inactive => _p('Inactive', 'غير نشط');
  String get activate => _p('Activate', 'تفعيل');
  String get deactivate => _p('Deactivate', 'إلغاء التفعيل');
  String get delete => _p('Delete', 'حذف');
  String get duplicate => _p('Duplicate', 'تكرار');

  String get englishName => _p('English name', 'الاسم بالإنجليزية');
  String get arabicName => _p('Arabic name', 'الاسم بالعربية');
  String get englishTitle => _p('English title', 'المسمى بالإنجليزية');
  String get arabicTitle => _p('Arabic title', 'المسمى بالعربية');
  String get code => _p('Code', 'الرمز');
  String get grade => _p('Grade', 'الدرجة');
  String get save => _p('Save', 'حفظ');

  /// Translate a Bloc warning token to a short inline message.
  String warning(String token) {
    switch (token) {
      case OrgWarn.deptHasChildren:
        return _p('Move or delete sub-departments first', 'انقل أو احذف الإدارات الفرعية أولًا');
      case OrgWarn.deptCycle:
        return _p(
          "Can't move a department into itself or its own sub-tree",
          'لا يمكن نقل إدارة داخل نفسها أو أحد فروعها',
        );
      case OrgWarn.linkHasPositions:
        return _p('Remove its positions before disconnecting this location', 'احذف مناصب هذا الموقع قبل فصله');
      case OrgWarn.positionCycle:
        return _p("A position can't report to its own subordinate", 'لا يمكن أن يتبع المنصب أحد مرؤوسيه');
      case OrgWarn.saveFailed:
      default:
        return _p('Something went wrong — please try again', 'حدث خطأ ما — يرجى المحاولة مرة أخرى');
    }
  }
}

/// A small inline tag/pill (code, "Inactive", grade, pin-count …). No shared
/// chip existed in the app, so this is the builder's local one.
class OrgTag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final Color? background;

  const OrgTag(this.text, {super.key, this.icon, this.color, this.background});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.inkSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: OrgGap.s, vertical: 2),
      decoration: BoxDecoration(
        color: background ?? AppColors.gridline.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 3)],
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

/// An inline warning banner shown at the top of a pane when the Bloc rejects an
/// action. Tappable to dismiss.
class OrgWarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const OrgWarningBanner({super.key, required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: OrgGap.m),
      padding: const EdgeInsets.symmetric(horizontal: OrgGap.m, vertical: OrgGap.s),
      decoration: BoxDecoration(
        color: AppColors.statusOnHold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.statusOnHold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.statusOnHold),
          const SizedBox(width: OrgGap.s),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.inkPrimary))),
          InkWell(onTap: onDismiss, child: const Icon(Icons.close, size: 14, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}

/// The shared inline editor: 1–3 stacked bare inputs + a confirm ✓. Saves on
/// Enter or on the check button; cancels on Escape. Reused by department,
/// location and position edits — each supplies its own field set.
class InlineEditRow extends StatefulWidget {
  /// Ordered fields: (label, initialValue, rtl, uppercase).
  final List<OrgEditField> fields;
  final void Function(List<String> values) onSave;
  final VoidCallback onCancel;

  const InlineEditRow({super.key, required this.fields, required this.onSave, required this.onCancel});

  @override
  State<InlineEditRow> createState() => _InlineEditRowState();
}

class OrgEditField {
  final String label;
  final String initial;
  final bool rtl;
  final bool uppercase;
  const OrgEditField(this.label, this.initial, {this.rtl = false, this.uppercase = false});
}

class _InlineEditRowState extends State<InlineEditRow> {
  late final List<TextEditingController> _controllers;
  late final FocusNode _firstFocus;

  @override
  void initState() {
    super.initState();
    _controllers = widget.fields.map((f) => TextEditingController(text: f.initial)).toList();
    _firstFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstFocus.requestFocus();
      _controllers.first.selection = TextSelection(baseOffset: 0, extentOffset: _controllers.first.text.length);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _firstFocus.dispose();
    super.dispose();
  }

  void _save() => widget.onSave(_controllers.map((c) => c.text).toList());

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.fields.length; i++) ...[
                  if (i > 0) const SizedBox(height: OrgGap.xs),
                  _bareInput(i),
                ],
              ],
            ),
          ),
          const SizedBox(width: OrgGap.s),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check, size: 18, color: AppColors.deltaGood),
            tooltip: OrgStrings.of(context).save,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _bareInput(int i) {
    final f = widget.fields[i];
    return TextField(
      controller: _controllers[i],
      focusNode: i == 0 ? _firstFocus : null,
      textDirection: f.rtl ? TextDirection.rtl : null,
      inputFormatters: f.uppercase ? [UpperCaseFormatter()] : null,
      onSubmitted: (_) => _save(),
      style: const TextStyle(fontSize: 14, color: AppColors.inkPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: f.label,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        border: const UnderlineInputBorder(),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}

/// Forces a text field's content to upper-case (location CODE).
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
