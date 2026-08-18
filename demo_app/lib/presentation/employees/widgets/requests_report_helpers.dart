import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart' as excel_package;

// Web support
import 'dart:html' as html;

class RequestsReportHelpers {
  /// Scroll handling for back to top functionality
  static void onScroll(ScrollController scrollController, Function(bool) setShowBackToTop) {
    if (scrollController.offset >= 400) {
      setShowBackToTop(true);
    } else {
      setShowBackToTop(false);
    }
  }

  static List<dynamic> removeEmployeeRequests(List<dynamic> requests, List<dynamic> selectedUsers) {
    return requests.where((request) {
      return selectedUsers.any((user) => user.id == request.userId);
    }).toList();
  }

  /// Scroll to top with animation
  static void scrollToTop(ScrollController scrollController) {
    scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  /// Apply filters to requests based on selected criteria
  static List<dynamic> applyFilters(
    List<dynamic> allRequests,
    DateTime? selectedDateFrom,
    DateTime? selectedDateTo,
    List<String> selectedRequestTypes,
    String? selectedRequestStatus, [
    List<dynamic>? selectedUsers,
    String dateMode = 'effective',
  ]) {
    return allRequests.where((request) {
      bool matchesType = true;
      bool matchesDateRange = true;
      bool matchesStatus = true;
      bool matchesUser = true;

      // Filter by request type
      if (selectedRequestTypes.isNotEmpty) {
        matchesType = selectedRequestTypes.contains(request.requestType?.toString() ?? 'unknown');
      }

      // Filter by date range
      if (selectedDateFrom != null || selectedDateTo != null) {
        final requestDate = getRequestDate(request, dateMode: dateMode);
        if (requestDate != null) {
          // Strip time so comparison is date-only, inclusive on both ends.
          final reqDay = DateTime(requestDate.year, requestDate.month, requestDate.day);
          if (selectedDateFrom != null && selectedDateTo != null) {
            final fromDay = DateTime(selectedDateFrom.year, selectedDateFrom.month, selectedDateFrom.day);
            final toDay = DateTime(selectedDateTo.year, selectedDateTo.month, selectedDateTo.day);
            matchesDateRange = !reqDay.isBefore(fromDay) && !reqDay.isAfter(toDay);
          } else if (selectedDateFrom != null) {
            final fromDay = DateTime(selectedDateFrom.year, selectedDateFrom.month, selectedDateFrom.day);
            matchesDateRange = !reqDay.isBefore(fromDay);
          } else if (selectedDateTo != null) {
            final toDay = DateTime(selectedDateTo.year, selectedDateTo.month, selectedDateTo.day);
            matchesDateRange = !reqDay.isAfter(toDay);
          }
        }
      }

      // Filter by request status — semantic groupings mirror calculateStatusCounts
      if (selectedRequestStatus != null && selectedRequestStatus.isNotEmpty) {
        final s = request.status?.toString().toLowerCase() ?? '';
        switch (selectedRequestStatus.toLowerCase()) {
          case 'pending':
            matchesStatus =
                s == 'pending' || s == 'waiting' || s == 'submitted' || s == 'acknowledged' || s == 'on_hold';
            break;
          case 'approved':
            matchesStatus = s == 'approved' || s == 'completed' || s == 'closed';
            break;
          case 'converted_to_investigation':
            matchesStatus = s == 'converted_to_investigation';
            break;
          case 'declined':
            matchesStatus = s == 'declined' || s == 'rejected';
            break;
          case 'cancelled':
            matchesStatus = s == 'cancelled';
            break;
          default:
            matchesStatus = s == selectedRequestStatus.toLowerCase();
        }
      }

      // Filter by selected users — handles single-userId types, DA (requestorCode/employeeCode),
      // and Investigation (requestorCode / employeeCodes list).
      if (selectedUsers != null && selectedUsers.isNotEmpty) {
        matchesUser = selectedUsers.any((user) {
          // Standard request types expose userId — guard against types that don't have it
          dynamic singleId;
          try {
            singleId = request.userId ?? request.user?.id;
          } catch (_) {}
          if (singleId != null) return user.id == singleId;
          // DA: match either the filer (requestorCode) or the target (employeeCode)
          try {
            final requestorCode = request.requestorCode as int?;
            final employeeCode = request.employeeCode as int?;
            if (requestorCode != null || employeeCode != null) {
              return user.id == requestorCode || user.id == employeeCode;
            }
          } catch (_) {}
          // Investigation: match requestorCode or any of employeeCodes
          try {
            final requestorCode = request.requestorCode as int?;
            final employeeCodes = request.employeeCodes as List<int>?;
            return user.id == requestorCode || (employeeCodes?.contains(user.id) == true);
          } catch (_) {}
          return false;
        });
      }

      return matchesType && matchesDateRange && matchesStatus && matchesUser;
    }).toList();
  }

  /// Extract request date from request object
  static DateTime? getRequestDate(dynamic request, {String dateMode = 'effective'}) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return v is DateTime ? v : DateTime.tryParse(v.toString());
    }

    // Created-at mode short-circuits the per-type effective-date logic: every
    // request model carries createdAt, so we use it directly regardless of type.
    if (dateMode == 'created_at') {
      try {
        return parseDate(request.createdAt);
      } catch (_) {
        return null;
      }
    }

    final type = request.requestType?.toString();

    switch (type) {
      case 'missing_punching':
        return parseDate(request.date);
      case 'disciplinary_action':
      case 'investigation':
        return parseDate(request.violationDate) ?? parseDate(request.createdAt);
      case 'hr_letter':
      case 'advance_on_salary':
        return parseDate(request.createdAt);
      default:
        // leave, overtime, business_trip — use dateFrom
        try {
          final dateFrom = parseDate(request.dateFrom);
          if (dateFrom != null) return dateFrom;
        } catch (_) {}
        return parseDate(request.createdAt);
    }
  }

  /// Show multi-select dialog for request types
  static void showRequestTypeMultiSelect(BuildContext context, List<String> selectedRequestTypes, Function() onApply) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.filterByRequestType),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.leaveRequestsFilter),
                    value: selectedRequestTypes.contains('leave'),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          if (!selectedRequestTypes.contains('leave')) {
                            selectedRequestTypes.add('leave');
                          }
                        } else {
                          selectedRequestTypes.remove('leave');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.overtimeRequestsFilter),
                    value: selectedRequestTypes.contains('overtime'),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          if (!selectedRequestTypes.contains('overtime')) {
                            selectedRequestTypes.add('overtime');
                          }
                        } else {
                          selectedRequestTypes.remove('overtime');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.businessTripRequestsFilter),
                    value: selectedRequestTypes.contains('business_trip'),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          if (!selectedRequestTypes.contains('business_trip')) {
                            selectedRequestTypes.add('business_trip');
                          }
                        } else {
                          selectedRequestTypes.remove('business_trip');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.missingPunchRequestsFilter),
                    value: selectedRequestTypes.contains('missing_punching'),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          if (!selectedRequestTypes.contains('missing_punching')) {
                            selectedRequestTypes.add('missing_punching');
                          }
                        } else {
                          selectedRequestTypes.remove('missing_punching');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.advanceOnSalaryRequestsFilter),
                    value: selectedRequestTypes.contains('advance_on_salary'),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          if (!selectedRequestTypes.contains('advance_on_salary')) {
                            selectedRequestTypes.add('advance_on_salary');
                          }
                        } else {
                          selectedRequestTypes.remove('advance_on_salary');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.hrLetterRequests),
                    value: selectedRequestTypes.contains('hr_letter'),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          if (!selectedRequestTypes.contains('hr_letter')) {
                            selectedRequestTypes.add('hr_letter');
                          }
                        } else {
                          selectedRequestTypes.remove('hr_letter');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.disciplinaryActionRequests),
                    value: selectedRequestTypes.contains('disciplinary_action'),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          if (!selectedRequestTypes.contains('disciplinary_action')) {
                            selectedRequestTypes.add('disciplinary_action');
                          }
                        } else {
                          selectedRequestTypes.remove('disciplinary_action');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.investigations),
                    value: selectedRequestTypes.contains('investigation'),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          if (!selectedRequestTypes.contains('investigation')) {
                            selectedRequestTypes.add('investigation');
                          }
                        } else {
                          selectedRequestTypes.remove('investigation');
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedRequestTypes.clear();
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.clear),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onApply();
                  },
                  child: Text(AppLocalizations.of(context)!.submit),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Generate grouped data for Excel export
  static Map<String, List<List<dynamic>>> generateGroupedData(String csvLikeText) {
    final lines = csvLikeText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final Map<String, List<List<dynamic>>> groupedData = {};
    String? currentSheet;

    for (final line in lines) {
      if (!line.contains(',')) {
        // This is a sheet title (e.g., "leave requests")
        currentSheet = line.trim();
        groupedData[currentSheet] = [];
      } else {
        // This is a row of data
        final row = line.split(',').map((e) => e.trim()).toList();
        if (currentSheet != null) {
          groupedData[currentSheet]!.add(row);
        }
      }
    }

    return groupedData;
  }

  /// Export data to Excel format using structured data to maintain column types
  static void exportToExcel(
    List<Map<String, dynamic>> csvData,
    String csvContent,
    BuildContext context,
    Function(String) showCSVDialog,
  ) {
    if (kIsWeb) {
      final excel = excel_package.Excel.createExcel();

      // Use structured csvData instead of csvContent to maintain proper data types
      // Group data by request type directly from csvData
      final Map<String, List<Map<String, dynamic>>> groupedData = {};
      String? currentRequestType;

      for (final row in csvData) {
        final requestType = row[AppLocalizations.of(context)!.requestType];
        if (requestType != null && requestType != currentRequestType) {
          currentRequestType = requestType;
          if (!groupedData.containsKey(requestType)) {
            groupedData[requestType] = [];
          }
        }
        if (currentRequestType != null) {
          groupedData[currentRequestType]!.add(row);
        }
      }

      groupedData.forEach((requestType, rows) {
        if (rows.isEmpty) return;
        final sheetName = getRequestsTypeDisplayName(requestType, context);
        final sheet = excel[sheetName];
        _populateSheet(sheet, rows, context);
      });

      // Remove the default sheet that Excel creates
      if (excel.sheets.isNotEmpty) {
        excel.delete(excel.sheets.keys.first);
      }

      final bytes = excel.encode();
      if (bytes == null) return;

      final blob = html.Blob([
        Uint8List.fromList(bytes),
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', 'requests_report_${DateTime.now().millisecondsSinceEpoch}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile platform - show a dialog with the CSV content
      showCSVDialog(csvContent);
    }
  }

  static void _populateSheet(excel_package.Sheet sheet, List<Map<String, dynamic>> rows, BuildContext context) {
    if (rows.isEmpty) return;

    final headers = rows.first.keys.toList();
    sheet.appendRow(headers.map((h) => excel_package.TextCellValue(h)).toList());

    final timeFromHeader = AppLocalizations.of(context)!.timeFrom;
    final timeToHeader = AppLocalizations.of(context)!.timeTo;
    final timeHeader = AppLocalizations.of(context)!.time;

    for (final row in rows) {
      final dataRow =
          headers.map((header) {
            final value = row[header];

            if (value == null) return excel_package.TextCellValue('');

            if (value is num) {
              if (value == value.roundToDouble()) return excel_package.IntCellValue(value.round());
              return excel_package.DoubleCellValue(value.toDouble());
            }

            if (value is DateTime) {
              final isTimeField =
                  header.toLowerCase().contains('time') ||
                  header == timeFromHeader ||
                  header == timeToHeader ||
                  header == timeHeader;
              final hasTimeData = value.hour != 0 || value.minute != 0 || value.second != 0;

              if (isTimeField && hasTimeData) {
                return excel_package.TimeCellValue(hour: value.hour, minute: value.minute, second: value.second);
              } else if (isTimeField && !hasTimeData) {
                return excel_package.TextCellValue(formatTime(value));
              } else {
                return excel_package.DateCellValue(year: value.year, month: value.month, day: value.day);
              }
            }

            if (value is String) {
              if (value.isEmpty) return excel_package.TextCellValue('');

              final isTimeField =
                  header.toLowerCase().contains('time') ||
                  header == timeFromHeader ||
                  header == timeToHeader ||
                  header == timeHeader;

              if (isTimeField &&
                  RegExp(r'^\d{1,2}:\d{2}(:\d{2})?(\s*(AM|PM))?$', caseSensitive: false).hasMatch(value.trim())) {
                try {
                  final parts = value.split(':');
                  final hour = int.parse(parts[0]);
                  final minute = int.parse(parts[1]);
                  final second = parts.length > 2 ? int.parse(parts[2]) : 0;
                  return excel_package.TimeCellValue(hour: hour, minute: minute, second: second);
                } catch (_) {
                  return excel_package.TextCellValue(value);
                }
              }

              final intValue = int.tryParse(value);
              if (intValue != null) return excel_package.IntCellValue(intValue);

              final doubleValue = double.tryParse(value);
              if (doubleValue != null) {
                if (doubleValue == doubleValue.roundToDouble()) return excel_package.IntCellValue(doubleValue.round());
                return excel_package.DoubleCellValue(doubleValue);
              }

              return excel_package.TextCellValue(value);
            }

            return excel_package.TextCellValue(value.toString());
          }).toList();

      sheet.appendRow(dataRow);
    }

    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnAutoFit(i);
    }
  }

  static String _sanitizeSheetName(String name, Set<String> usedNames) {
    var s = name.replaceAll(RegExp(r'''[\\/?*\[\]:'"]'''), '_').trim();
    if (s.isEmpty) s = 'Unknown';
    if (s.length > 31) s = s.substring(0, 31).trimRight();
    if (usedNames.contains(s)) {
      int counter = 2;
      String candidate;
      do {
        final suffix = ' ($counter)';
        candidate = s.length + suffix.length > 31 ? '${s.substring(0, 31 - suffix.length)}$suffix' : '$s$suffix';
        counter++;
      } while (usedNames.contains(candidate));
      s = candidate;
    }
    usedNames.add(s);
    return s;
  }

  /// Exports one workbook per request type, one sheet per employee.
  /// [grouped]: raw typeKey (e.g. 'leave') → employeeName → pre-generated csvRows.
  /// csvRows come from generateCSVData so column sets are already correct per type.
  static void exportToExcelGroupedByEmployee(
    Map<String, Map<String, List<Map<String, dynamic>>>> grouped,
    BuildContext context,
    Function(String) showCSVDialog,
  ) {
    if (!kIsWeb) {
      showCSVDialog('');
      return;
    }

    // Pre-encode all workbooks before scheduling downloads
    final List<(String filename, List<int> bytes)> workbooks = [];

    for (final typeEntry in grouped.entries) {
      final typeKey = typeEntry.key;
      final byEmployee = typeEntry.value;
      if (byEmployee.isEmpty) continue;

      final excel = excel_package.Excel.createExcel();
      final usedSheetNames = <String>{};

      for (final empEntry in byEmployee.entries) {
        if (empEntry.value.isEmpty) continue;
        final sheetName = _sanitizeSheetName(empEntry.key, usedSheetNames);
        final sheet = excel[sheetName];
        _populateSheet(sheet, empEntry.value, context);
      }

      if (excel.sheets.isNotEmpty) {
        excel.delete(excel.sheets.keys.first);
      }

      final bytes = excel.encode();
      if (bytes == null) continue;

      // Derive plural display name from the raw typeKey via existing helpers
      final singularName = getRequestTypeDisplayName(typeKey, context);
      final pluralName = getRequestsTypeDisplayName(singularName, context);
      final filename = '${pluralName}_by_employee_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      workbooks.add((filename, bytes));
    }

    // Stagger downloads 600ms apart to avoid browser popup blockers
    for (int i = 0; i < workbooks.length; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () {
        final (filename, bytes) = workbooks[i];
        final blob = html.Blob([
          Uint8List.fromList(bytes),
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
      });
    }
  }

  static double toExcelSerialDate(DateTime date) {
    final excelEpoch = DateTime(1899, 12, 30);
    return date.difference(excelEpoch).inDays.toDouble() +
        (date.hour / 24) +
        (date.minute / 1440) +
        (date.second / 86400);
  }

  /// Convert DateTime to Excel time value (fractional part of day)
  static double toExcelTime(DateTime dateTime) {
    return (dateTime.hour / 24.0) +
        (dateTime.minute / 1440.0) +
        (dateTime.second / 86400.0) +
        (dateTime.millisecond / 86400000.0);
  }

  /// Create Excel time cell value from DateTime
  static excel_package.TimeCellValue createExcelTimeValue(DateTime dateTime) {
    return excel_package.TimeCellValue(hour: dateTime.hour, minute: dateTime.minute, second: dateTime.second);
  }

  /// Show CSV dialog for mobile platforms
  static void showCSVDialog(BuildContext context, String csvContent) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.csvExport),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.csvContentGenerated),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.csvMobileInstructions),
                const SizedBox(height: 16),
                Container(
                  width: double.maxFinite,
                  height: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(csvContent, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  /// Generate CSV data from filtered requests
  static List<Map<String, dynamic>> generateCSVData(List<dynamic> filteredRequests, BuildContext context) {
    // Define the order we want
    const order = [
      'leave',
      'overtime',
      'business_trip',
      'missing_punching',
      'advance_on_salary',
      'hr_letter',
      'disciplinary_action',
      'investigation',
    ];
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    // Group requests by type
    final Map<String, List<dynamic>> groupedRequests = {};
    for (final request in filteredRequests) {
      final requestType = request.requestType?.toString() ?? 'unknown';
      if (!groupedRequests.containsKey(requestType)) {
        groupedRequests[requestType] = [];
      }
      groupedRequests[requestType]!.add(request);
    }

    // Build the CSV data in the specified order
    final List<Map<String, dynamic>> csvData = [];

    for (final requestType in order) {
      final requests = groupedRequests[requestType];
      if (requests != null && requests.isNotEmpty) {
        // Add all requests of this type
        for (final request in requests) {
          // New types build their own data maps and don't use the legacy n1/n2 approver chain.
          // Handle them early to avoid NoSuchMethodError on currentApprover.
          if (requestType == 'hr_letter') {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            final l10n = AppLocalizations.of(context)!;
            csvData.add({
              l10n.requestType: getRequestTypeDisplayName(requestType, context),
              l10n.createdAt: request.createdAt != null ? DateTime.parse(request.createdAt.toString()) : '',
              l10n.status: request.getLocalizedStatus(context),
              l10n.name:
                  isAr
                      ? (request.employeeArabicName ?? request.employeeEnglishName ?? 'N/A')
                      : (request.employeeEnglishName ?? request.employeeArabicName ?? 'N/A'),
              l10n.id: request.employeeCode?.toString() ?? 'N/A',
              l10n.nationalId: request.nationalId?.toString() ?? '',
              l10n.title:
                  isAr
                      ? (request.employeeTitle ?? request.employeeEnglishTitle ?? '')
                      : (request.employeeEnglishTitle ?? request.employeeTitle ?? ''),
              l10n.department:
                  isAr
                      ? (request.employeeDepartment ?? request.employeeEnglishDepartment ?? 'N/A')
                      : (request.employeeEnglishDepartment ?? request.employeeDepartment ?? 'N/A'),
              l10n.hireDate: request.employeeHireDate?.toString() ?? '',
              l10n.letterPurpose: request.getLocalizedLetterPurpose(context),
              l10n.travelFromDate:
                  request.travelFromDate != null ? DateTime.parse(request.travelFromDate.toString()) : '',
              l10n.travelToDate: request.travelToDate != null ? DateTime.parse(request.travelToDate.toString()) : '',
              l10n.hrLetterDetails: request.details?.toString() ?? '',
              l10n.hrHandler:
                  isAr
                      ? (request.hrHandlerArabicName ?? request.hrHandlerEnglishName ?? '')
                      : (request.hrHandlerEnglishName ?? request.hrHandlerArabicName ?? ''),
              l10n.acknowledgedAt:
                  request.acknowledgedAt != null ? DateTime.parse(request.acknowledgedAt.toString()) : '',
              l10n.completedAt: request.completedAt != null ? DateTime.parse(request.completedAt.toString()) : '',
              l10n.declinedAt: request.declinedAt != null ? DateTime.parse(request.declinedAt.toString()) : '',
              l10n.cancelledAt: request.cancelledAt != null ? DateTime.parse(request.cancelledAt.toString()) : '',
              l10n.lastActionAt: request.lastActionAt != null ? DateTime.parse(request.lastActionAt.toString()) : '',
              l10n.declineReason: request.declineReason?.toString() ?? '',
            });
            continue;
          }

          if (requestType == 'disciplinary_action') {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            final l10n = AppLocalizations.of(context)!;
            csvData.add({
              l10n.requestType: getRequestTypeDisplayName(requestType, context),
              l10n.createdAt: request.createdAt != null ? DateTime.parse(request.createdAt.toString()) : '',
              l10n.status: request.getLocalizedStatus(context),
              l10n.currentApprover: request.getLocalizedApproverName(context),
              // Employee
              l10n.name:
                  isAr
                      ? (request.employeeArabicName ?? request.employeeEnglishName ?? 'N/A')
                      : (request.employeeEnglishName ?? request.employeeArabicName ?? 'N/A'),
              l10n.id: request.employeeCode?.toString() ?? 'N/A',
              l10n.title:
                  isAr
                      ? (request.employeeTitle ?? request.employeeEnglishTitle ?? '')
                      : (request.employeeEnglishTitle ?? request.employeeTitle ?? ''),
              l10n.department:
                  isAr
                      ? (request.employeeDepartment ?? request.employeeEnglishDepartment ?? 'N/A')
                      : (request.employeeEnglishDepartment ?? request.employeeDepartment ?? 'N/A'),
              l10n.hireDate: request.employeeHireDate?.toString() ?? '',
              // Requestor
              l10n.requestor:
                  isAr
                      ? (request.requestorArabicName ?? request.requestorEnglishName ?? 'N/A')
                      : (request.requestorEnglishName ?? request.requestorArabicName ?? 'N/A'),
              l10n.requestorTitle:
                  isAr
                      ? (request.requestorTitle ?? request.requestorEnglishTitle ?? '')
                      : (request.requestorEnglishTitle ?? request.requestorTitle ?? ''),
              l10n.requestorDepartment:
                  isAr
                      ? (request.requestorDepartment ?? request.requestorEnglishDepartment ?? '')
                      : (request.requestorEnglishDepartment ?? request.requestorDepartment ?? ''),
              // N+2
              l10n.n2Manager:
                  isAr
                      ? (request.n2ArabicName ?? request.n2EnglishName ?? '')
                      : (request.n2EnglishName ?? request.n2ArabicName ?? ''),
              // Incident
              l10n.violationDate: request.violationDate != null ? DateTime.parse(request.violationDate.toString()) : '',
              l10n.violationCategory: request.violationCategory?.toString() ?? '',
              l10n.violation: request.violation?.toString() ?? '',
              l10n.actionType: request.getLocalizedActionType(context),
              l10n.incidentDescription: request.incidentDescription?.toString() ?? '',
              // Written warning
              l10n.deductDays:
                  (request.writtenWarningOptions?.deductDays ?? 0) > 0
                      ? request.writtenWarningOptions!.deductDays.toString()
                      : '',
              l10n.suspensionDays:
                  (request.writtenWarningOptions?.suspensionDays ?? 0) > 0
                      ? request.writtenWarningOptions!.suspensionDays.toString()
                      : '',
              // Approval chain
              l10n.n2ApprovalDate:
                  request.n2ApprovalDate != null ? DateTime.parse(request.n2ApprovalDate.toString()) : '',
              l10n.n2ApprovalReason: request.n2ApprovalReason?.toString() ?? '',
              l10n.hrApprovalDate:
                  request.hrApprovalDate != null ? DateTime.parse(request.hrApprovalDate.toString()) : '',
              l10n.hrApprovalReason: request.hrApprovalReason?.toString() ?? '',
              // HR final decision
              l10n.hrFinalDecision: request.hrFinalAction?.toString() ?? '',
              l10n.suspensionPeriod: request.suspensionDaysField?.toString() ?? '',
              l10n.suspensionStartDate:
                  request.suspensionStartDate != null ? DateTime.parse(request.suspensionStartDate.toString()) : '',
              l10n.suspensionEndDate:
                  request.suspensionEndDate != null ? DateTime.parse(request.suspensionEndDate.toString()) : '',
              l10n.terminationRecommendedDate:
                  request.terminationRecommendedDate != null
                      ? DateTime.parse(request.terminationRecommendedDate.toString())
                      : '',
              // Legal escalation
              l10n.legalEscalation: (request.escalatedToLegal == true) ? l10n.yes : '',
              l10n.legalEscalationDate:
                  request.legalEscalationDate != null ? DateTime.parse(request.legalEscalationDate.toString()) : '',
              l10n.legalEscalationReason: request.legalEscalationReason?.toString() ?? '',
              l10n.legalCompletionDate:
                  request.legalCompletionDate != null ? DateTime.parse(request.legalCompletionDate.toString()) : '',
              (isAr ? 'الشؤون القانونية' : 'Legal'):
                  isAr
                      ? (request.legalArabicName ?? request.legalEnglishName ?? '')
                      : (request.legalEnglishName ?? request.legalArabicName ?? ''),
              // Employee acknowledgment
              l10n.employeeAcknowledgmentDate:
                  request.employeeAcknowledgmentDate != null
                      ? DateTime.parse(request.employeeAcknowledgmentDate.toString())
                      : '',
              l10n.employeeAcknowledgmentType: request.employeeAcknowledgmentType?.toString() ?? '',
              l10n.employeeAcknowledgmentRemark: request.employeeAcknowledgmentRemark?.toString() ?? '',
              // Outcome & links
              l10n.holdReason: request.holdReason?.toString() ?? '',
              l10n.declineReason: request.declineReason?.toString() ?? '',
              l10n.linkedInvestigation: request.investigationId?.toString() ?? '',
              l10n.lastActionAt: request.lastActionAt != null ? DateTime.parse(request.lastActionAt.toString()) : '',
            });
            continue;
          }

          if (requestType == 'investigation') {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            final l10n = AppLocalizations.of(context)!;
            final employeeInfoMap = request.employeeInfoMap as Map? ?? {};
            final employeeNames = (request.employeeCodes as List<int>? ?? [])
                .map((code) {
                  final info = employeeInfoMap[code];
                  if (info == null) return code.toString();
                  return isAr
                      ? (info.arabicName ?? info.englishName ?? code.toString())
                      : (info.englishName ?? info.arabicName ?? code.toString());
                })
                .join(', ');
            csvData.add({
              l10n.requestType: getRequestTypeDisplayName(requestType, context),
              l10n.createdAt: request.createdAt != null ? DateTime.parse(request.createdAt.toString()) : '',
              l10n.status: request.getLocalizedStatus(context),
              l10n.currentApprover: request.getLocalizedCurrentApprover(isAr),
              l10n.requestor:
                  isAr
                      ? (request.requestorArabicName ?? request.requestorEnglishName ?? 'N/A')
                      : (request.requestorEnglishName ?? request.requestorArabicName ?? 'N/A'),
              l10n.name: employeeNames.isNotEmpty ? employeeNames : 'N/A',
              l10n.violationDate: request.violationDate != null ? DateTime.parse(request.violationDate.toString()) : '',
              l10n.violationCategory: request.violationCategory?.toString() ?? '',
              l10n.violation: request.violation?.toString() ?? '',
              l10n.incidentDescription: request.incidentDescription?.toString() ?? '',
              l10n.hrHandler:
                  isAr
                      ? (request.hrArabicName ?? request.hrEnglishName ?? '')
                      : (request.hrEnglishName ?? request.hrArabicName ?? ''),
              l10n.legalEscalation: (request.escalatedToLegal == true) ? l10n.yes : '',
              l10n.legalEscalationDate:
                  request.legalEscalationDate != null ? DateTime.parse(request.legalEscalationDate.toString()) : '',
              l10n.legalEscalationReason: request.legalEscalationReason?.toString() ?? '',
              (isAr ? 'الشؤون القانونية' : 'Legal'):
                  isAr
                      ? (request.legalArabicName ?? request.legalEnglishName ?? '')
                      : (request.legalEnglishName ?? request.legalArabicName ?? ''),
              (isAr ? 'الإدارة العليا' : 'Top Management'):
                  isAr
                      ? (request.topManagementArabicName ?? request.topManagementEnglishName ?? '')
                      : (request.topManagementEnglishName ?? request.topManagementArabicName ?? ''),
              l10n.linkedDisciplinaryAction:
                  (request.escalatedFromDisciplinary == true)
                      ? (request.escalatedDisciplinaryActionId?.toString() ?? '')
                      : '',
              l10n.lastActionAt: request.lastActionAt != null ? DateTime.parse(request.lastActionAt.toString()) : '',
            });
            continue;
          }

          final baseData = {
            AppLocalizations.of(context)!.requestType: getRequestTypeDisplayName(requestType, context),
            AppLocalizations.of(context)!.createdAt: DateTime.parse(request.createdAt.toString()),
            AppLocalizations.of(context)!.approver: getCurrentApprover(request, context),
            AppLocalizations.of(context)!.status: request.getLocalizedStatus(context),
            AppLocalizations.of(context)!.name: getEmployeeName(request, context) ?? 'N/A',
            AppLocalizations.of(context)!.id: getEmployeeId(request) ?? 'N/A',
            AppLocalizations.of(context)!.department: getEmployeeDepartment(request, context),
          };

          // Add type-specific fields based on request type
          switch (requestType) {
            case 'leave':
            case 'طلب إجازة':
              csvData.add({
                ...baseData,
                // Leave-specific fields
                AppLocalizations.of(context)!.dateFrom: DateTime.parse(request.dateFrom.toString()),
                AppLocalizations.of(context)!.dateTo: DateTime.parse(request.dateTo.toString()),
                AppLocalizations.of(context)!.leaveType: request.getLocalizedLeaveType(context) ?? 'N/A',
                AppLocalizations.of(context)!.numberOfDays: ensureNumericValue(request.numberOfDays),
                AppLocalizations.of(context)!.declineReason: request.declineReason?.toString() ?? '',
              });
              break;

            case 'overtime':
              csvData.add({
                ...baseData,
                // Overtime-specific fields
                AppLocalizations.of(context)!.date: DateTime.parse(request.date.toString()),
                AppLocalizations.of(context)!.timeFrom:
                    request.timeFrom is DateTime ? request.timeFrom : formatTime(request.timeFrom),
                AppLocalizations.of(context)!.timeTo:
                    request.timeTo is DateTime ? request.timeTo : formatTime(request.timeTo),
                AppLocalizations.of(context)!.numOfHours: request.numberOfHours,
                AppLocalizations.of(context)!.overtimeType: request.getLocalizedOvertimeType(context) ?? 'N/A',
                AppLocalizations.of(context)!.reason: request.reason?.toString() ?? 'N/A',
                AppLocalizations.of(context)!.declineReason: request.declineReason?.toString() ?? '',
              });
              break;

            case 'business_trip':
              csvData.add({
                ...baseData,
                // Business trip-specific fields
                AppLocalizations.of(context)!.dateFrom: DateTime.parse(request.dateFrom.toString()),
                AppLocalizations.of(context)!.dateTo: DateTime.parse(request.dateTo.toString()),
                AppLocalizations.of(context)!.numberOfDays: ensureNumericValue(request.numberOfDays),
                AppLocalizations.of(context)!.numOfHours: ensureNumericValue(request.numberOfHours),
                AppLocalizations.of(context)!.location: request.getLocalizedLocation(context),
                AppLocalizations.of(context)!.declineReason: request.declineReason?.toString() ?? '',
              });
              break;

            case 'missing_punching':
              csvData.add({
                ...baseData,
                // Missing punch-specific fields
                AppLocalizations.of(context)!.date: DateTime.parse(request.date.toString()),
                AppLocalizations.of(context)!.time: request.time is DateTime ? request.time : formatTime(request.time),
                AppLocalizations.of(context)!.missingpunchType: request.getLocalizedType(context) ?? 'N/A',
                AppLocalizations.of(context)!.declineReason: request.declineReason?.toString() ?? '',
              });
              break;

            case 'advance_on_salary':
              // Remove generic department and add specific requestor/borrower departments
              final advanceData = Map<String, dynamic>.from(baseData);
              advanceData.remove(AppLocalizations.of(context)!.department);
              advanceData.remove(AppLocalizations.of(context)!.name);

              csvData.add({
                ...advanceData,
                // Add requestor department and borrower department as separate columns
                AppLocalizations.of(context)!.requestor: getEmployeeName(request, context) ?? 'N/A',
                isArabic
                        ? 'قسم مقدم الطلب'
                        : '${AppLocalizations.of(context)!.requestor} ${AppLocalizations.of(context)!.department}':
                    getEmployeeDepartment(request, context),
                AppLocalizations.of(context)!.borrower:
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? request.borrowerArabicName ?? 'N/A'
                        : request.borrowerEnglishName ?? 'N/A',
                isArabic
                        ? 'قسم المقترض'
                        : '${AppLocalizations.of(context)!.borrower} ${AppLocalizations.of(context)!.department}':
                    getBorrowerDepartment(request, context),
                // Other advance on salary-specific fields
                AppLocalizations.of(context)!.amount: ensureNumericValue(request.amount),
                AppLocalizations.of(context)!.period:
                    '${request.periodInMonths ?? 'N/A'} ${AppLocalizations.of(context)!.months}',
                AppLocalizations.of(context)!.monthlyPayment: ensureNumericValue(request.monthlyPayment),
                AppLocalizations.of(context)!.paymentStartDate: DateTime.parse(request.paymentStartDate.toString()),
                AppLocalizations.of(context)!.paymentEndDate: DateTime.parse(request.paymentEndDate.toString()),
                AppLocalizations.of(context)!.declineReason: request.declineReason?.toString() ?? '',
              });
              break;

            default:
              break;
          }
        }
      }
    }

    return csvData;
  }

  /// Extract employee name from request
  static String? getEmployeeName(dynamic request, BuildContext context) {
    // For advance on salary requests, use requestor name
    if (request.requestType == 'advance_on_salary') {
      if (Localizations.localeOf(context).languageCode == "en" &&
          request.requestorEnglishName != null &&
          request.requestorEnglishName.toString().isNotEmpty) {
        return request.requestorEnglishName.toString();
      }
      if (Localizations.localeOf(context).languageCode == "ar" &&
          request.requestorArabicName != null &&
          request.requestorArabicName.toString().isNotEmpty) {
        return request.requestorArabicName.toString();
      }
    }

    // For other request types, use user name
    if (Localizations.localeOf(context).languageCode == "en" &&
        request.userEnglishName != null &&
        request.userEnglishName.toString().isNotEmpty) {
      return request.userEnglishName.toString();
    }
    if (Localizations.localeOf(context).languageCode == "ar" &&
        request.userArabicName != null &&
        request.userArabicName.toString().isNotEmpty) {
      return request.userArabicName.toString();
    }

    return null;
  }

  /// Extract employee ID from request
  static String? getEmployeeId(dynamic request) {
    // For advance on salary requests, use requestor code
    if (request.requestType == 'advance_on_salary') {
      if (request.requestorCode != null) {
        return request.requestorCode.toString();
      }
    }

    // For other request types, use user ID
    if (request.userId != null) {
      return request.userId.toString();
    }
    return null;
  }

  /// Extract employee department from request (user department for most requests, requestor for advance on salary)
  static String getEmployeeDepartment(dynamic request, BuildContext context) {
    // For advance on salary requests, use requestor department
    if (request.requestType == 'advance_on_salary') {
      if (Localizations.localeOf(context).languageCode == "en" &&
          request.requestorEnglishDepartment != null &&
          request.requestorEnglishDepartment.toString().isNotEmpty) {
        return request.requestorEnglishDepartment.toString();
      }
      if (Localizations.localeOf(context).languageCode == "ar" &&
          request.requestorDepartment != null &&
          request.requestorDepartment.toString().isNotEmpty) {
        return request.requestorDepartment.toString();
      }
    }

    // For other request types, use user department
    if (Localizations.localeOf(context).languageCode == "en" &&
        request.userEnglishDepartment != null &&
        request.userEnglishDepartment.toString().isNotEmpty) {
      return request.userEnglishDepartment.toString();
    }
    if (Localizations.localeOf(context).languageCode == "ar" &&
        request.userDepartment != null &&
        request.userDepartment.toString().isNotEmpty) {
      return request.userDepartment.toString();
    }

    return 'N/A';
  }

  /// Extract borrower department from advance on salary request
  static String getBorrowerDepartment(dynamic request, BuildContext context) {
    if (Localizations.localeOf(context).languageCode == "en" &&
        request.borrowerEnglishDepartment != null &&
        request.borrowerEnglishDepartment.toString().isNotEmpty) {
      return request.borrowerEnglishDepartment.toString();
    }
    if (Localizations.localeOf(context).languageCode == "ar" &&
        request.borrowerDepartment != null &&
        request.borrowerDepartment.toString().isNotEmpty) {
      return request.borrowerDepartment.toString();
    }

    return 'N/A';
  }

  /// Get current approver display name for CSV/Excel export
  static String getCurrentApprover(dynamic request, [BuildContext? context]) {
    if (request.currentApprover == null) {
      return 'N/A';
    }

    // If context is provided, return localized strings
    if (context != null) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';

      switch (request.currentApprover.toString().toLowerCase()) {
        case "hr":
          return isArabic ? "الموارد البشرية" : "HR";
        case "finance":
          return isArabic ? "المالية" : "Finance";
        case "n1":
          return isArabic ? "المدير المباشر (N+1)" : "N+1";
        case "n2":
          return isArabic ? "مدير المدير (N+2)" : "N+2";
      }
    } else {
      // Fallback for backward compatibility when no context is provided
      switch (request.currentApprover.toString().toLowerCase()) {
        case "hr":
          return "HR";
        case "finance":
          return "Finance";
        case "n1":
          return "N+1";
        case "n2":
          return "N+2";
      }
    }

    // For other cases, just return the approver code/identifier
    return request.currentApprover.toString();
  }

  /// Ensure a value is properly converted to a numeric type for Excel export
  static dynamic ensureNumericValue(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      // If it's a whole number, return as int to avoid .00
      if (value == value.roundToDouble()) {
        return value.round();
      }
      return value; // Already numeric
    }

    if (value is String) {
      // Try to parse as int first (to avoid .00 for whole numbers)
      final intValue = int.tryParse(value);
      if (intValue != null) return intValue;

      // Try to parse as double
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        // Check if it's actually a whole number
        if (doubleValue == doubleValue.roundToDouble()) {
          return doubleValue.round();
        }
        return doubleValue;
      }

      return 0; // Fallback to 0 if parsing fails
    }

    // For other types, try to convert to string and parse
    try {
      final stringValue = value.toString();
      final intValue = int.tryParse(stringValue);
      if (intValue != null) return intValue;

      final doubleValue = double.tryParse(stringValue);
      if (doubleValue != null) {
        // Check if it's actually a whole number
        if (doubleValue == doubleValue.roundToDouble()) {
          return doubleValue.round();
        }
        return doubleValue;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get request type display name
  static String getRequestTypeDisplayName(String? requestType, BuildContext context) {
    switch (requestType) {
      case 'leave':
      case 'طلب إجازة':
        return AppLocalizations.of(context)!.leaveRequest;
      case 'overtime':
      case 'طلب أوفرتايم':
        return AppLocalizations.of(context)!.overtimeRequest;
      case 'business_trip':
      case 'طلب مأمورية عمل':
        return AppLocalizations.of(context)!.businessTripRequest;
      case 'missing_punching':
      case 'طلب إثبات بصمة':
        return AppLocalizations.of(context)!.missingPunchRequest;
      case 'advance_on_salary':
      case 'طلب سلفة راتب':
        return AppLocalizations.of(context)!.advanceOnSalaryRequest;
      case 'hr_letter':
        return AppLocalizations.of(context)!.hrLetterRequest;
      case 'disciplinary_action':
        return AppLocalizations.of(context)!.disciplinaryActionRequest;
      case 'investigation':
        return AppLocalizations.of(context)!.investigation;
      default:
        return AppLocalizations.of(context)!.unknown;
    }
  }

  /// Get request type display name (plural)
  static String getRequestsTypeDisplayName(String? requestType, BuildContext context) {
    switch (requestType) {
      case 'Leave Request':
      case 'طلب إجازة':
        return AppLocalizations.of(context)!.leaveRequests;
      case 'Overtime Request':
      case 'طلب أوفرتايم':
        return AppLocalizations.of(context)!.overtimeRequests;
      case 'Business Trip Request':
      case 'طلب مأمورية عمل':
        return AppLocalizations.of(context)!.businessTripRequests;
      case 'Missing Punch Request':
      case 'طلب إثبات بصمة':
        return AppLocalizations.of(context)!.missingPunchRequests;
      case 'Advance on Salary Request':
      case 'طلب سلفة راتب':
        return AppLocalizations.of(context)!.advanceOnSalaryRequests;
      default:
        // Fallback: Check if it matches any AppLocalizations value
        if (requestType == AppLocalizations.of(context)!.leaveRequest) {
          return AppLocalizations.of(context)!.leaveRequests;
        } else if (requestType == AppLocalizations.of(context)!.overtimeRequest) {
          return AppLocalizations.of(context)!.overtimeRequests;
        } else if (requestType == AppLocalizations.of(context)!.businessTripRequest) {
          return AppLocalizations.of(context)!.businessTripRequests;
        } else if (requestType == AppLocalizations.of(context)!.missingPunchRequest) {
          return AppLocalizations.of(context)!.missingPunchRequests;
        } else if (requestType == AppLocalizations.of(context)!.advanceOnSalaryRequest) {
          return AppLocalizations.of(context)!.advanceOnSalaryRequests;
        }
        return requestType ?? AppLocalizations.of(context)!.unknown;
    }
  }

  /// Convert data to CSV format
  static String convertToCSV(List<Map<String, dynamic>> data, BuildContext context) {
    if (data.isEmpty) return '';

    final csvRows = <String>[];
    String? currentRequestType;

    for (final row in data) {
      // Check if this is a new request type
      final requestType = row[AppLocalizations.of(context)!.requestType];
      if (requestType != null && requestType != currentRequestType) {
        // Add empty row before new section (except for the first section)
        if (currentRequestType != null) {
          csvRows.add('');
        }

        // Add section header
        csvRows.add('"${getRequestsTypeDisplayName(requestType, context)}"');
        csvRows.add('');

        // Add column headers only once per section
        final headers = row.keys.toList();
        csvRows.add(headers.map((header) => '"$header"').join(','));

        currentRequestType = requestType;
      }

      // Add data values with proper formatting
      final values = row.values
          .map((value) {
            if (value is DateTime) {
              // Check if this is likely a time value (has non-zero time components)
              if (value.hour != 0 || value.minute != 0 || value.second != 0) {
                return '"${formatTime(value)}"';
              } else {
                // This is likely a date value
                return '"${value.toString().split(' ')[0]}"';
              }
            }
            return '"$value"';
          })
          .join(',');
      csvRows.add(values);
    }

    return csvRows.join('\n');
  }

  /// Format time value for display
  static String formatTime(dynamic timeValue) {
    if (timeValue is DateTime) {
      return '${timeValue.hour.toString().padLeft(2, '0')}:${timeValue.minute.toString().padLeft(2, '0')}';
    }
    // Fallback for non-DateTime values
    return timeValue.toString();
  }

  /// Get time value for Excel export (returns DateTime for Excel, string for display)
  static dynamic getTimeValueForExport(dynamic timeValue, {bool forExcel = false}) {
    if (timeValue is DateTime) {
      if (forExcel) {
        // Return the DateTime object for Excel to handle as time
        return timeValue;
      } else {
        // Return formatted string for display/CSV
        return formatTime(timeValue);
      }
    }
    // Fallback for non-DateTime values
    return timeValue.toString();
  }

  /// Get status color based on status string
  static Color getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('pending') || lowerStatus == 'on_hold') {
      return Colors.orange;
    } else if (lowerStatus.contains('approved') ||
        lowerStatus.contains('completed') ||
        lowerStatus == 'acknowledged' ||
        lowerStatus == 'closed') {
      return Colors.green;
    } else if (lowerStatus.contains('declined')) {
      return Colors.red;
    } else if (lowerStatus == 'converted_to_investigation') {
      return Colors.blueGrey;
    } else if (lowerStatus.contains('cancelled')) {
      return Colors.grey;
    }
    return Colors.grey;
  }

  /// Get request title based on request type
  static String getRequestTitle(dynamic request, BuildContext context) {
    if (request.requestType == 'leave') {
      return AppLocalizations.of(context)!.leaveRequest;
    } else if (request.requestType == 'overtime') {
      return AppLocalizations.of(context)!.overtimeRequest;
    } else if (request.requestType == 'business_trip') {
      return AppLocalizations.of(context)!.businessTripRequest;
    } else if (request.requestType == 'missing_punching') {
      return AppLocalizations.of(context)!.missingPunchRequest;
    } else if (request.requestType == 'advance_on_salary') {
      return AppLocalizations.of(context)!.advanceOnSalaryRequest;
    }
    return AppLocalizations.of(context)!.request;
  }

  /// Calculate status counts for requests
  static Map<String, int> calculateStatusCounts(List<dynamic> requests) {
    int pendingCount = 0;
    int approvedCount = 0;
    int declinedCount = 0;
    int cancelledCount = 0;
    int otherCount = 0;

    for (final r in requests) {
      final s = r.status?.toString().toLowerCase() ?? '';
      if (s == 'pending' || s == 'waiting' || s == 'submitted' || s == 'acknowledged' || s == 'on_hold') {
        pendingCount++;
      } else if (s == 'approved' || s == 'completed' || s == 'closed' || s == 'converted_to_investigation') {
        approvedCount++;
      } else if (s == 'declined' || s == 'rejected') {
        declinedCount++;
      } else if (s == 'cancelled') {
        cancelledCount++;
      } else if (s.isNotEmpty) {
        otherCount++;
      }
    }

    return {
      'pending': pendingCount,
      'approved': approvedCount,
      'declined': declinedCount,
      'cancelled': cancelledCount,
      'other': otherCount,
    };
  }
}
