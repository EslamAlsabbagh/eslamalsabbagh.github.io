import 'package:intl/intl.dart';

import '../l10n/gen/app_localizations.dart';

/// An amount in piastres as the screens show it: "1,250 ج.م" / "EGP 1,250",
/// with Western digits, and piastres only when there are some ("EGP 12.50").
String formatMoney(AppLocalizations l10n, int piastres) {
  final pattern = piastres % 100 == 0 ? '#,##0' : '#,##0.00';
  return l10n.moneyAmount(NumberFormat(pattern, l10n.localeName).format(piastres / 100));
}

/// A typed amount in pounds ("500", "12.5", "12.50") as piastres; null when
/// empty or not an amount. Integer arithmetic only: money is never a double.
int? parsePiastres(String text) {
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(text.trim());
  if (match == null) return null;
  final pounds = int.parse(match.group(1)!);
  final piastres = (match.group(2) ?? '').padRight(2, '0');
  return pounds * 100 + int.parse(piastres);
}

/// [piastres] as an amount field shows it: "500", or "12.50" with piastres.
String piastresText(int piastres) {
  final pounds = piastres ~/ 100;
  final rest = piastres % 100;
  return rest == 0 ? '$pounds' : '$pounds.${rest.toString().padLeft(2, '0')}';
}
