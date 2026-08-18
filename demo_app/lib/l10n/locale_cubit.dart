import 'package:hrms_demo/data/repos/storage/storage_keys.dart';
import 'package:hrms_demo/data/repos/storage/storage_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this.storage) : super(const Locale('en')) {
    _getInitialLocale();
  }

  /// Injected. This cubit used to build its own `StorageRepoImpl`, which was the
  /// third of three separate instances wrapping the same secure storage.
  final StorageRepo storage;

  void switchToArabic() => emit(const Locale('ar'));
  void switchToEnglish() => emit(const Locale('en'));
  void toggleLocale() async {
    try {
      final newLocale =
          state.languageCode == 'en' ? const Locale('ar') : const Locale('en');
      await storage.write(StorageKeys.language.key, newLocale.languageCode);
      emit(newLocale);
    } catch (e) {
      // Consider emitting an error state or logging the error more robustly
    }
  }

  Future<void> _getInitialLocale() async {
    try {
      final language = await storage.read(StorageKeys.language.key);
      // Check if the language code is valid and not empty
      if (language != null) {
        final langCode = language;
        if (langCode == 'en' || langCode == 'ar') {
          emit(Locale(langCode));
        } else {
          emit(const Locale('en'));
        }
      } else {
        // If language is null or empty, set the default 'en'
        await storage.delete(StorageKeys.language.key);

        emit(const Locale('en'));
      }
    } catch (e) {
      // If storage read fails, keep the default 'en' from super()
    }
  }

  @override
  void onChange(Change<Locale> change) {
    super.onChange(change);
  }
}
