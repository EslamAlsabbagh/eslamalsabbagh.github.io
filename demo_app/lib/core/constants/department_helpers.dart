import 'package:hrms_demo/core/constants/department.dart';
import 'package:flutter/material.dart';

/// Helper class for common department operations
class DepartmentHelpers {
  /// Search departments by name (case-insensitive)
  static List<Department> searchDepartments(String searchTerm) {
    if (searchTerm.isEmpty) return Department.allDepartments;

    return Department.allDepartments.where((dept) {
      return dept.label.toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();
  }

  /// Get department by exact label match
  static Department? getDepartmentByLabel(String label) {
    return Department.fromString(label);
  }

  /// Get localized department names for search suggestions
  static List<String> getSearchSuggestions(BuildContext context) {
    return Department.getAllLabels(context);
  }

  /// Get Arabic department names for search suggestions
  static List<String> getArabicSearchSuggestions(BuildContext context) {
    return Department.getAllArabicLabels(context);
  }

  /// Get Arabic department names regardless of current locale
  static List<String> getArabicTextSuggestions() {
    return Department.getAllArabicTextLabels();
  }

  /// Get English department names regardless of current locale
  static List<String> getEnglishTextSuggestions() {
    return Department.getAllEnglishTextLabels();
  }

  /// Check if a string matches any department label
  static bool isDepartmentLabel(String label) {
    return Department.fromString(label) != null;
  }

  /// Get all department labels as a simple string list
  static List<String> getAllDepartmentLabels() {
    return Department.values.map((dept) => dept.label).toList();
  }

  /// Filter departments by category (if needed in the future)
  static List<Department> getDepartmentsByCategory(String category) {
    // This can be extended to group departments by categories
    // For now, returning all departments
    return Department.allDepartments;
  }

  /// Get department display name based on current locale
  static String getDisplayName(
    Department department,
    BuildContext context,
    bool isArabic,
  ) {
    if (isArabic) {
      return department.localizedLabelArabic(context);
    }
    return department.localizedLabel(context);
  }
}
