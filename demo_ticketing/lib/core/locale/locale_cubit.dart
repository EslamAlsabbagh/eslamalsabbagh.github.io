import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'locale_store.dart';

/// The UI language. Text direction follows it (Arabic RTL, English LTR).
///
/// Arabic-first (ADR-0010). With a [LocaleStore] it starts in the language
/// last used on this PC and saves every change there. After login the app
/// sets the staff member's language (`staff.language`, or the default-language
/// setting).
///
/// `ar`, not `ar_EG`: the plain Arabic locale keeps Western digits.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({Locale initial = arabic, LocaleStore? store})
      : _store = store,
        super(fromCode(store?.read()) ?? initial);

  final LocaleStore? _store;

  static const arabic = Locale('ar');
  static const english = Locale('en');

  /// The locale for an `app_language` value (`ar` / `en`); null for anything else.
  static Locale? fromCode(String? code) => switch (code) {
        'ar' => arabic,
        'en' => english,
        _ => null,
      };

  void setLocale(Locale locale) {
    emit(locale);
    // Best effort: a failed write only means the login screen opens in the
    // previous language next time.
    if (_store case final store?) unawaited(store.write(locale.languageCode));
  }

  void toggle() => setLocale(state.languageCode == arabic.languageCode ? english : arabic);
}
