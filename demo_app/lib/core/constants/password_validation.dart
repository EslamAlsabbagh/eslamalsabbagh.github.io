import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PasswordValidation {
  static const int minLength = 8;
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]');

  /// Validates password against all complexity requirements
  /// Returns null if valid, otherwise returns the first validation error
  static String? validatePassword(BuildContext context, String password) {
    if (password.isEmpty) {
      return AppLocalizations.of(context)!.plsNewPassword;
    }

    if (password.length < minLength) {
      return AppLocalizations.of(context)!.passwordTooShortNew;
    }

    if (!_uppercaseRegex.hasMatch(password)) {
      return AppLocalizations.of(context)!.passwordMissingUppercase;
    }

    if (!_lowercaseRegex.hasMatch(password)) {
      return AppLocalizations.of(context)!.passwordMissingLowercase;
    }

    if (!_digitRegex.hasMatch(password)) {
      return AppLocalizations.of(context)!.passwordMissingDigit;
    }

    if (!_specialCharRegex.hasMatch(password)) {
      return AppLocalizations.of(context)!.passwordMissingSpecialChar;
    }

    if (password == "123456") {
      return AppLocalizations.of(context)!.weakPasswordError;
    }

    return null; // Password is valid
  }

  /// Returns true if password meets all complexity requirements
  static bool isPasswordValid(String password) {
    return password.isNotEmpty &&
           password.length >= minLength &&
           _uppercaseRegex.hasMatch(password) &&
           _lowercaseRegex.hasMatch(password) &&
           _digitRegex.hasMatch(password) &&
           _specialCharRegex.hasMatch(password) &&
           password != "123456";
  }

  /// Returns a list of all password requirement violations
  static List<String> getPasswordViolations(BuildContext context, String password) {
    List<String> violations = [];

    if (password.isEmpty) {
      violations.add(AppLocalizations.of(context)!.plsNewPassword);
      return violations;
    }

    if (password.length < minLength) {
      violations.add(AppLocalizations.of(context)!.passwordTooShortNew);
    }

    if (!_uppercaseRegex.hasMatch(password)) {
      violations.add(AppLocalizations.of(context)!.passwordMissingUppercase);
    }

    if (!_lowercaseRegex.hasMatch(password)) {
      violations.add(AppLocalizations.of(context)!.passwordMissingLowercase);
    }

    if (!_digitRegex.hasMatch(password)) {
      violations.add(AppLocalizations.of(context)!.passwordMissingDigit);
    }

    if (!_specialCharRegex.hasMatch(password)) {
      violations.add(AppLocalizations.of(context)!.passwordMissingSpecialChar);
    }

    if (password == "123456") {
      violations.add(AppLocalizations.of(context)!.weakPasswordError);
    }

    return violations;
  }
}