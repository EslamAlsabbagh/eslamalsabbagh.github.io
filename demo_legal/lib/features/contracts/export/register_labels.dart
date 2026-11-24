import '../../../core/domain/contract_kind.dart';
import 'register_document.dart';

/// Every word the register shows, filled from `AppLocalizations` by the view
/// (`registerLabels`), so `buildRegister` stays plain Dart and testable.
///
/// Digits in the register are Western, as in the firm's workbook: its dates
/// and areas are Excel numbers, which Excel shows that way (chosen
/// 2026-11-16).
class RegisterLabels {
  const RegisterLabels({
    required this.headers,
    required this.legend,
    required this.bandTitle,
    required this.terminatedBandTitle,
    required this.terminatedSheetName,
    required this.subject,
    required this.annexSubject,
    required this.unitWithKey,
    required this.duration,
    required this.needs,
    required this.ourSide,
    required this.terminatedNote,
  }) : assert(headers.length == 15, 'a header per column');

  /// A to O.
  final List<String> headers;
  final RegisterLegend legend;

  /// «بيان بجميع العقود السارية بمشروع {file} لموسم {season}», or the
  /// undated band's title when [season] is null.
  final String Function(String file, int? season) bandTitle;

  /// The same for the terminated contracts' sheet.
  final String Function(String file, int? season) terminatedBandTitle;

  /// «{file} - الملغاة».
  final String Function(String file) terminatedSheetName;

  /// A main or storage contract's subject, or its kind's name when it has
  /// none.
  final String Function(ContractKind kind, String subject) subject;

  /// «ملحق {n}: {subject}».
  final String Function(int? annexNo, String subject) annexSubject;

  /// «{code} (مفتاح {key})».
  final String Function(String code, String key) unitWithKey;

  /// «5 سنوات», «سنتان و3 أشهر».
  final String Function(int months) duration;

  /// «توقيع وختم», «توقيع» or «ختم».
  final String Function({required bool signature, required bool stamp}) needs;

  /// «من جانبنا»: a missing item on the firm's side.
  final String ourSide;

  /// «أُلغي في {date}: {reason}», with the date already as text.
  final String Function(String? date, String reason) terminatedNote;
}

/// `dd/mm/yyyy`, the register's date format (Excel's number format too).
String registerDateText(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year.toString().padLeft(4, '0')}';
