/// Screen-local display language for the Org Structure Builder. This is
/// DELIBERATELY separate from the app's global LocaleCubit (which only has
/// en/ar): the builder offers a third "bilingual" mode that has no global
/// equivalent, and it only affects how ENTITY names/titles render — static
/// chrome still follows the global locale via AppLocalizations.
enum OrgLang { en, ar, bilingual }

extension OrgLangX on OrgLang {
  /// Resolve an entity's display string from its English + optional Arabic value.
  ///   en        -> English
  ///   ar        -> Arabic, falling back to English when Arabic is absent
  ///   bilingual -> "English — Arabic" (English alone when Arabic is absent)
  String label(String en, String? ar) {
    final arabic = (ar == null || ar.trim().isEmpty) ? null : ar.trim();
    switch (this) {
      case OrgLang.en:
        return en;
      case OrgLang.ar:
        return arabic ?? en;
      case OrgLang.bilingual:
        return arabic == null ? en : '$en — $arabic';
    }
  }
}
