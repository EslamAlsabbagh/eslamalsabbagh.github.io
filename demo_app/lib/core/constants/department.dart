import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum Department {
  topManagement(label: 'Top Management'),
  financialDepartment(label: 'Financial Department'),
  administrativeAffairs(label: 'Administrative Affairs'),
  eventsDepartment(label: 'Events Department'),
  marketingDepartment(label: 'Marketing Department'),
  leasingDepartment(label: 'Leasing Department'),
  licensingDepartment(label: 'Regulatory affairs & Licensing solutions'),
  internalSecurity(label: 'internal security'),
  maintenanceDepartment(label: 'Maintenance Department'),
  projectsDepartment(label: 'Projects Department'),
  legalDepartment(label: 'Legal Department'),
  operationsDepartment(label: 'Operations Department'),
  safetyDepartment(label: 'Safety Department'),
  prDepartment(label: 'PR Department'),
  purchasingDepartment(label: 'Purchasing Department'),
  cashierDepartment(label: 'Cashier Department'),
  humanResourcesDepartment(label: 'Human Resources Department'),
  itDepartment(label: 'IT Department'),
  warehousesDepartment(label: 'Warehouses Department'),
  collectionDepartment(label: 'Collection Department'),
  receptionDepartment(label: 'Reception Department');

  const Department({required this.label});

  final String label;

  String localizedLabel(BuildContext context) {
    switch (this) {
      case Department.topManagement:
        return AppLocalizations.of(context)!.topManagement;
      case Department.financialDepartment:
        return AppLocalizations.of(context)!.financialDepartment;
      case Department.administrativeAffairs:
        return AppLocalizations.of(context)!.administrativeAffairs;
      case Department.eventsDepartment:
        return AppLocalizations.of(context)!.eventsDepartment;
      case Department.marketingDepartment:
        return AppLocalizations.of(context)!.marketingDepartment;
      case Department.leasingDepartment:
        return AppLocalizations.of(context)!.leasingDepartment;
      case Department.licensingDepartment:
        return AppLocalizations.of(context)!.licensingDepartment;
      case Department.internalSecurity:
        return AppLocalizations.of(context)!.internalSecurity;
      case Department.maintenanceDepartment:
        return AppLocalizations.of(context)!.maintenanceDepartment;
      case Department.projectsDepartment:
        return AppLocalizations.of(context)!.projectsDepartment;
      case Department.legalDepartment:
        return AppLocalizations.of(context)!.legalDepartment;
      case Department.operationsDepartment:
        return AppLocalizations.of(context)!.operationsDepartment;
      case Department.safetyDepartment:
        return AppLocalizations.of(context)!.safetyDepartment;
      case Department.prDepartment:
        return AppLocalizations.of(context)!.prDepartment;
      case Department.purchasingDepartment:
        return AppLocalizations.of(context)!.purchasingDepartment;
      case Department.cashierDepartment:
        return AppLocalizations.of(context)!.cashierDepartment;
      case Department.humanResourcesDepartment:
        return AppLocalizations.of(context)!.humanResourcesDepartment;
      case Department.itDepartment:
        return AppLocalizations.of(context)!.itDepartment;
      case Department.warehousesDepartment:
        return AppLocalizations.of(context)!.warehousesDepartment;
      case Department.collectionDepartment:
        return AppLocalizations.of(context)!.collectionDepartment;
      case Department.receptionDepartment:
        return AppLocalizations.of(context)!.receptionDepartment;
    }
  }

  String localizedLabelArabic(BuildContext context) {
    switch (this) {
      case Department.topManagement:
        return AppLocalizations.of(context)!.topManagement;
      case Department.financialDepartment:
        return AppLocalizations.of(context)!.financialDepartment;
      case Department.administrativeAffairs:
        return AppLocalizations.of(context)!.administrativeAffairs;
      case Department.eventsDepartment:
        return AppLocalizations.of(context)!.eventsDepartment;
      case Department.marketingDepartment:
        return AppLocalizations.of(context)!.marketingDepartment;
      case Department.leasingDepartment:
        return AppLocalizations.of(context)!.leasingDepartment;
      case Department.licensingDepartment:
        return AppLocalizations.of(context)!.licensingDepartment;
      case Department.internalSecurity:
        return AppLocalizations.of(context)!.internalSecurity;
      case Department.maintenanceDepartment:
        return AppLocalizations.of(context)!.maintenanceDepartment;
      case Department.projectsDepartment:
        return AppLocalizations.of(context)!.projectsDepartment;
      case Department.legalDepartment:
        return AppLocalizations.of(context)!.legalDepartment;
      case Department.operationsDepartment:
        return AppLocalizations.of(context)!.operationsDepartment;
      case Department.safetyDepartment:
        return AppLocalizations.of(context)!.safetyDepartment;
      case Department.prDepartment:
        return AppLocalizations.of(context)!.prDepartment;
      case Department.purchasingDepartment:
        return AppLocalizations.of(context)!.purchasingDepartment;
      case Department.cashierDepartment:
        return AppLocalizations.of(context)!.cashierDepartment;
      case Department.humanResourcesDepartment:
        return AppLocalizations.of(context)!.humanResourcesDepartment;
      case Department.itDepartment:
        return AppLocalizations.of(context)!.itDepartment;
      case Department.warehousesDepartment:
        return AppLocalizations.of(context)!.warehousesDepartment;
      case Department.collectionDepartment:
        return AppLocalizations.of(context)!.collectionDepartment;
      case Department.receptionDepartment:
        return AppLocalizations.of(context)!.receptionDepartment;
    }
  }

  // Helper method to get department from string value
  static Department? fromString(String? value) {
    if (value == null) return null;

    for (Department dept in Department.values) {
      if (dept.label == value) return dept;
    }
    return null;
  }

  // Helper method to get department from Arabic string value
  static Department? fromArabicString(String? value) {
    if (value == null) return null;

    // This would need to be implemented based on the actual Arabic values used in the system
    // For now, returning null as we need to map the actual Arabic strings
    return null;
  }

  // Get all departments as a list for dropdowns
  static List<Department> get allDepartments => Department.values.toList();

  // Get all department labels for dropdowns
  static List<String> getAllLabels(BuildContext context) {
    return Department.values.map((dept) => dept.localizedLabel(context)).toList();
  }

  // Get all Arabic department labels for dropdowns
  static List<String> getAllArabicLabels(BuildContext context) {
    return Department.values.map((dept) => dept.localizedLabelArabic(context)).toList();
  }

  // Get Arabic text regardless of current locale
  String getArabicText() {
    switch (this) {
      case Department.topManagement:
        return 'الإدارة العليا';
      case Department.financialDepartment:
        return 'الإدارة المالية';
      case Department.administrativeAffairs:
        return 'إدارة الشئون الإدارية';
      case Department.eventsDepartment:
        return 'إدارة الفعاليات';
      case Department.marketingDepartment:
        return 'إدارة التسويق';
      case Department.leasingDepartment:
        return 'إدارة التأجير';
      case Department.licensingDepartment:
        return 'إدارة التراخيص';
      case Department.internalSecurity:
        return 'الامن الداخلى';
      case Department.maintenanceDepartment:
        return 'إدارة الصيانة';
      case Department.projectsDepartment:
        return 'إدارة المشروعات';
      case Department.legalDepartment:
        return 'إدارة الشئون القانونية';
      case Department.operationsDepartment:
        return 'إدارة العمليات';
      case Department.safetyDepartment:
        return 'إدارة السلامة والصحة المهنية';
      case Department.prDepartment:
        return 'إدارة العلاقات العامة';
      case Department.purchasingDepartment:
        return 'إدارة المشتريات';
      case Department.cashierDepartment:
        return 'إدارة الكاشير';
      case Department.humanResourcesDepartment:
        return 'إدارة الموارد البشرية';
      case Department.itDepartment:
        return 'إدارة تكنولوجيا المعلومات';
      case Department.warehousesDepartment:
        return 'إدارة المخازن';
      case Department.collectionDepartment:
        return 'ادارة التحصيلات';
      case Department.receptionDepartment:
        return 'إدارة الاستقبال';
    }
  }

  // Get English text regardless of current locale
  String getEnglishText() {
    switch (this) {
      case Department.topManagement:
        return 'Top Management';
      case Department.financialDepartment:
        return 'Financial Department';
      case Department.administrativeAffairs:
        return 'Administrative Affairs';
      case Department.eventsDepartment:
        return 'Events Department';
      case Department.marketingDepartment:
        return 'Marketing Department';
      case Department.leasingDepartment:
        return 'Leasing Department';
      case Department.licensingDepartment:
        return 'Regulatory affairs & Licensing solutions';
      case Department.internalSecurity:
        return 'Internal Security';
      case Department.maintenanceDepartment:
        return 'Maintenance Department';
      case Department.projectsDepartment:
        return 'Projects Department';
      case Department.legalDepartment:
        return 'Legal Department';
      case Department.operationsDepartment:
        return 'Operations Department';
      case Department.safetyDepartment:
        return 'Safety Department';
      case Department.prDepartment:
        return 'PR Department';
      case Department.purchasingDepartment:
        return 'Purchasing Department';
      case Department.cashierDepartment:
        return 'Cashier Department';
      case Department.humanResourcesDepartment:
        return 'Human Resources Department';
      case Department.itDepartment:
        return 'IT Department';
      case Department.warehousesDepartment:
        return 'Warehouses Department';
      case Department.collectionDepartment:
        return 'Collection Department';
      case Department.receptionDepartment:
        return 'Reception Department';
    }
  }

  // Get all Arabic text labels for dropdowns (regardless of locale)
  static List<String> getAllArabicTextLabels() {
    return Department.values.map((dept) => dept.getArabicText()).toList();
  }

  // Get all English text labels for dropdowns (regardless of locale)
  static List<String> getAllEnglishTextLabels() {
    return Department.values.map((dept) => dept.getEnglishText()).toList();
  }

  // Convert Arabic text to corresponding English text
  static String? getEnglishFromArabic(String arabicText) {
    for (Department dept in Department.values) {
      if (dept.getArabicText() == arabicText) {
        return dept.getEnglishText();
      }
    }
    return null;
  }

  // Convert English text to corresponding Arabic text
  static String? getArabicFromEnglish(String englishText) {
    for (Department dept in Department.values) {
      if (dept.getEnglishText() == englishText) {
        return dept.getArabicText();
      }
    }
    return null;
  }
}
