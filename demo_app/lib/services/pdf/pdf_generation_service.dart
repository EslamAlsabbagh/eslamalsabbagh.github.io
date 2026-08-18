import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/pdf_constants.dart';
import '../../data/models/advance_on_salary_request_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repos/users/users_repo.dart';

class PDFGenerationService {
  final UsersRepo? _usersRepo;

  PDFGenerationService({UsersRepo? usersRepo}) : _usersRepo = usersRepo;

  /// Generate PDF for advance on salary request
  Future<String> generateAdvanceRequestPDF(AdvanceOnSalaryRequestModel request, String locale) async {
    try {
      final pdfBytes = await buildPDFDocument(request, locale);
      final fileName = _generateFileName(request);
      final filePath = await _savePDFToStorage(pdfBytes, fileName);

      return filePath;
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  /// Generate PDF and upload to Supabase Storage (for email attachments)
  Future<String> generateAndUploadAdvanceRequestPDF(AdvanceOnSalaryRequestModel request, String locale) async {
    try {
      final pdfBytes = await buildPDFDocument(request, locale);
      final fileName = _generateCloudFileName(request);

      // Upload to Supabase Storage
      final pdfUrl = await _uploadPDFToSupabaseStorage(pdfBytes, fileName);

      return pdfUrl;
    } catch (e) {
      throw Exception('Failed to generate and upload PDF: $e');
    }
  }

  /// Generate request updates PDF
  Future<String?> generateRequestUpdatesPDF(AdvanceOnSalaryRequestModel request, String locale) async {
    try {
      final pdfBytes = await buildRequestUpdatesPDFDocument(request, locale);

      // If no updates exist, return null
      if (pdfBytes == null) {
        return null;
      }

      final fileName = _generateUpdatesFileName(request);
      final filePath = await _savePDFToStorage(pdfBytes, fileName);

      return filePath;
    } catch (e) {
      throw Exception('Failed to generate updates PDF: $e');
    }
  }

  /// Generate and upload request updates PDF to Supabase Storage
  Future<String?> generateAndUploadRequestUpdatesPDF(AdvanceOnSalaryRequestModel request, String locale) async {
    try {
      final pdfBytes = await buildRequestUpdatesPDFDocument(request, locale);

      // If no updates exist, return null
      if (pdfBytes == null) {
        return null;
      }

      final fileName = _generateUpdatesCloudFileName(request);

      // Upload to Supabase Storage
      final pdfUrl = await _uploadPDFToSupabaseStorage(pdfBytes, fileName);

      return pdfUrl;
    } catch (e) {
      throw Exception('Failed to generate and upload updates PDF: $e');
    }
  }

  /// Build the complete PDF document with dynamic pagination
  Future<Uint8List> buildPDFDocument(AdvanceOnSalaryRequestModel request, String locale) async {
    final pdf = pw.Document();
    final isArabic = locale == 'ar';

    // Load fonts and logo for proper rendering
    final font = await _loadFont();
    final arabicFont = await _loadArabicFont();
    final logoImage = await _loadLogo();

    // Fetch borrower user data if available
    UserModel? borrowerUser;

    if (_usersRepo != null && request.borrowerCode != null) {
      try {
        borrowerUser = await _usersRepo.getEmployeeById(request.borrowerCode!);
      } catch (e) {
        borrowerUser = null;
      }
    }

    // Check if there are any updates to add to additional pages
    final hasFinanceUpdates =
        request.updatedPeriod != null || request.updatedMonthlyPayment != null || request.updatedPaymentEndDate != null;

    final hasUnscheduledPayments = request.unscheduledPayments != null && request.unscheduledPayments!.isNotEmpty;

    // Check if we should show scheduled payments (actual from DB or calculated expected)
    final mergedScheduledPayments = _getMergedScheduledPayments(request);
    final hasScheduledPayments = mergedScheduledPayments.isNotEmpty;

    // Get updates pages structure to calculate actual total pages
    List<List<_ContentSection>> updatesPages = [];
    if (hasFinanceUpdates || hasUnscheduledPayments || hasScheduledPayments) {
      updatesPages = await _calculateUpdatesPagesStructure(
        request,
        isArabic,
        font,
        arabicFont,
        hasFinanceUpdates,
        hasUnscheduledPayments,
        hasScheduledPayments,
      );
    }

    // Calculate actual total pages: main page + updates pages
    final actualTotalPages = 1 + updatesPages.length;

    // Pre-build the approval chain widget with actual total pages
    final approvalChainWidget = await _buildApprovalChainWithTotal(
      request,
      isArabic,
      font,
      arabicFont,
      actualTotalPages,
    );

    // Add main request page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(PDFConstants.pageMargin),
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(isArabic, font, arabicFont, logoImage),
              _buildDocumentTitle(isArabic, font, arabicFont),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      children: [
                        _buildRequestInfo(request, isArabic, font, arabicFont),
                        _buildEmployeeDetails(request, borrowerUser, isArabic, font, arabicFont),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(flex: 1, child: _buildFinancialDetails(request, isArabic, font, arabicFont)),
                ],
              ),
              pw.Container(width: double.infinity, height: 1, color: PdfColors.grey),
              pw.SizedBox(height: 8),
              approvalChainWidget,
              pw.Positioned(
                bottom: 75,
                left: 0,
                right: 0,
                child: _buildEmployeeSignatureSection(request, isArabic, font, arabicFont),
              ),
              pw.Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: _buildUpdatesPrintInfoWithPaging(isArabic, font, arabicFont, 1, actualTotalPages),
              ),
            ],
          );
        },
      ),
    );

    // Add updates pages from pre-calculated structure
    if (updatesPages.isNotEmpty) {
      await _addUpdatesPagesFromStructure(pdf, request, isArabic, font, arabicFont, logoImage, updatesPages);
    }

    return await pdf.save();
  }

  /// Build the final state PDF document with complete payment schedule
  /// This PDF shows the expected final state with all scheduled payments filled out
  /// Used for settlement notifications and represents zero remaining amount
  Future<Uint8List> buildFinalStatePDFDocument(AdvanceOnSalaryRequestModel request, String locale) async {
    final pdf = pw.Document();
    final isArabic = locale == 'ar';

    // Load fonts and logo for proper rendering
    final font = await _loadFont();
    final arabicFont = await _loadArabicFont();
    final logoImage = await _loadLogo();

    // Fetch borrower user data if available
    UserModel? borrowerUser;

    if (_usersRepo != null && request.borrowerCode != null) {
      try {
        borrowerUser = await _usersRepo.getEmployeeById(request.borrowerCode!);
      } catch (e) {
        borrowerUser = null;
      }
    }

    // For final state PDF, always show complete payment schedule
    final hasFinanceUpdates =
        request.updatedPeriod != null || request.updatedMonthlyPayment != null || request.updatedPaymentEndDate != null;

    final hasUnscheduledPayments = request.unscheduledPayments != null && request.unscheduledPayments!.isNotEmpty;

    // Get complete scheduled payments (actual + calculated to fill remaining)
    final completeScheduledPayments = _getCompleteScheduledPayments(request);
    final hasScheduledPayments = completeScheduledPayments.isNotEmpty;

    // Create a modified request with complete scheduled payments for rendering
    final modifiedRequest = request.copyWith(scheduledPayments: completeScheduledPayments);

    // Get updates pages structure to calculate actual total pages
    List<List<_ContentSection>> updatesPages = [];
    if (hasFinanceUpdates || hasUnscheduledPayments || hasScheduledPayments) {
      updatesPages = await _calculateUpdatesPagesStructure(
        modifiedRequest,
        isArabic,
        font,
        arabicFont,
        hasFinanceUpdates,
        hasUnscheduledPayments,
        hasScheduledPayments,
      );
    }

    // Calculate actual total pages: main page + updates pages
    final actualTotalPages = 1 + updatesPages.length;

    // Pre-build the approval chain widget with actual total pages
    final approvalChainWidget = await _buildApprovalChainWithTotal(
      request,
      isArabic,
      font,
      arabicFont,
      actualTotalPages,
    );

    // Add main request page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(PDFConstants.pageMargin),
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(isArabic, font, arabicFont, logoImage),
              _buildDocumentTitle(isArabic, font, arabicFont),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      children: [
                        _buildRequestInfo(request, isArabic, font, arabicFont),
                        _buildEmployeeDetails(request, borrowerUser, isArabic, font, arabicFont),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(flex: 1, child: _buildFinancialDetails(request, isArabic, font, arabicFont)),
                ],
              ),
              pw.Container(width: double.infinity, height: 1, color: PdfColors.grey),
              pw.SizedBox(height: 8),
              approvalChainWidget,
              pw.Spacer(),
              _buildEmployeeSignatureSection(request, isArabic, font, arabicFont),
              _buildUpdatesPrintInfoWithPaging(isArabic, font, arabicFont, 1, actualTotalPages),
            ],
          );
        },
      ),
    );

    // Add updates pages from pre-calculated structure (with complete scheduled payments)
    if (updatesPages.isNotEmpty) {
      await _addUpdatesPagesFromStructure(pdf, modifiedRequest, isArabic, font, arabicFont, logoImage, updatesPages);
    }

    return await pdf.save();
  }

  /// Build the request updates PDF document with dynamic pagination
  Future<Uint8List?> buildRequestUpdatesPDFDocument(AdvanceOnSalaryRequestModel request, String locale) async {
    final isArabic = locale == 'ar';

    // Check if there are any updates to show
    final hasFinanceUpdates =
        request.updatedPeriod != null || request.updatedMonthlyPayment != null || request.updatedPaymentEndDate != null;

    final hasUnscheduledPayments = request.unscheduledPayments != null && request.unscheduledPayments!.isNotEmpty;

    final hasScheduledPayments = request.scheduledPayments != null && request.scheduledPayments!.isNotEmpty;

    // If no updates exist, return null (don't create page)
    if (!hasFinanceUpdates && !hasUnscheduledPayments && !hasScheduledPayments) {
      return null;
    }

    final pdf = pw.Document();

    // Load fonts and logo for proper rendering
    final font = await _loadFont();
    final arabicFont = await _loadArabicFont();
    final logoImage = await _loadLogo();

    // Add updates pages with dynamic pagination
    await _addUpdatesPagesWithPagination(
      pdf,
      request,
      isArabic,
      font,
      arabicFont,
      logoImage,
      hasFinanceUpdates,
      hasUnscheduledPayments,
      hasScheduledPayments,
    );

    return await pdf.save();
  }

  /// Calculate updates pages structure to determine actual page count
  Future<List<List<_ContentSection>>> _calculateUpdatesPagesStructure(
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
    bool hasFinanceUpdates,
    bool hasUnscheduledPayments,
    bool hasScheduledPayments,
  ) async {
    // Calculate content sections and their estimated heights
    final sections = <_ContentSection>[];

    if (hasFinanceUpdates) {
      sections.add(
        _ContentSection(
          widget: _buildFinanceUpdatesSection(request, isArabic, font, arabicFont),
          estimatedHeight: isArabic ? 100 : 80, // More space for Arabic
          isRequired: false,
        ),
      );
    }

    if (hasUnscheduledPayments) {
      final paymentCount = request.unscheduledPayments?.length ?? 0;
      final itemHeight = isArabic ? 50 : 35; // Even larger height for Arabic items
      final maxItemsPerSection = isArabic ? 6 : 10; // Fewer items per section for Arabic

      if (paymentCount <= maxItemsPerSection) {
        sections.add(
          _ContentSection(
            widget: _buildUnscheduledPaymentsSection(request, isArabic, font, arabicFont),
            estimatedHeight: (isArabic ? 40.0 : 20.0) + (paymentCount * itemHeight),
            isRequired: false,
          ),
        );
      } else {
        // Split into multiple smaller sections for Arabic
        final chunks = <List>[];
        for (int i = 0; i < paymentCount; i += maxItemsPerSection) {
          final end = (i + maxItemsPerSection > paymentCount) ? paymentCount : i + maxItemsPerSection;
          chunks.add(request.unscheduledPayments!.sublist(i, end));
        }

        for (int i = 0; i < chunks.length; i++) {
          final chunkRequest = request.copyWith(unscheduledPayments: chunks[i].cast<UnscheduledPayment>());

          sections.add(
            _ContentSection(
              widget: _buildUnscheduledPaymentsSection(chunkRequest, isArabic, font, arabicFont),
              estimatedHeight: (isArabic ? 40.0 : 20.0) + (chunks[i].length * itemHeight),
              isRequired: false,
            ),
          );
        }
      }
    }

    if (hasScheduledPayments) {
      final paymentCount = request.scheduledPayments?.length ?? 0;
      final itemHeight = isArabic ? 50 : 35; // Larger height for Arabic items
      final maxItemsPerSection = isArabic ? 8 : 12; // Fewer items per section for Arabic

      if (paymentCount <= maxItemsPerSection) {
        sections.add(
          _ContentSection(
            widget: _buildScheduledPaymentsPaginated(request, isArabic, font, arabicFont),
            estimatedHeight: (isArabic ? 40.0 : 20.0) + (paymentCount * itemHeight),
            isRequired: false,
          ),
        );
      } else {
        // Split into multiple smaller sections for Arabic
        final chunks = <List>[];
        for (int i = 0; i < paymentCount; i += maxItemsPerSection) {
          final end = (i + maxItemsPerSection > paymentCount) ? paymentCount : i + maxItemsPerSection;
          chunks.add(request.scheduledPayments!.sublist(i, end));
        }

        for (int i = 0; i < chunks.length; i++) {
          final chunkRequest = request.copyWith(scheduledPayments: chunks[i].cast<ScheduledPayment>());

          sections.add(
            _ContentSection(
              widget: _buildScheduledPaymentsPaginated(chunkRequest, isArabic, font, arabicFont),
              estimatedHeight: (isArabic ? 40.0 : 20.0) + (chunks[i].length * itemHeight),
              isRequired: false,
            ),
          );
        }
      }
    }

    if (hasUnscheduledPayments || hasScheduledPayments || request.manuallySettled == true) {
      sections.add(
        _ContentSection(
          widget: _buildPaymentSummarySection(request, isArabic, font, arabicFont),
          estimatedHeight: isArabic ? 100 : 80, // More space for Arabic
          isRequired: false,
        ),
      );
    }

    // Available content height (A4 page minus margins and header)
    const double pageHeight = 842; // A4 height in points
    final double headerHeight = isArabic ? 170 : 150; // More space for Arabic headers
    const double signatureHeight = 50; // Employee signature section
    const double footerHeight = 30; // Footer height ("Printed on" section)
    const double margins = PDFConstants.pageMargin * 2;
    final double availableHeight = pageHeight - headerHeight - signatureHeight - footerHeight - margins - 100;

    // Group sections into pages with more conservative height checking for Arabic
    final pages = <List<_ContentSection>>[];
    var currentPage = <_ContentSection>[];
    var currentPageHeight = 0.0;
    // Use 80% of available height for Arabic to ensure no overflow, 90% for English
    final safeAvailableHeight = availableHeight * (isArabic ? 0.50 : 0.60);

    for (final section in sections) {
      // Check if section fits in current page
      if (currentPageHeight + section.estimatedHeight <= safeAvailableHeight && currentPage.isNotEmpty) {
        currentPage.add(section);
        currentPageHeight += section.estimatedHeight;
      } else {
        // Start new page
        if (currentPage.isNotEmpty) {
          pages.add(List.from(currentPage));
        }
        currentPage = [section];
        currentPageHeight = section.estimatedHeight;
      }
    }

    // Add the last page if it has content
    if (currentPage.isNotEmpty) {
      pages.add(currentPage);
    }

    return pages;
  }

  /// Add updates pages from pre-calculated structure
  Future<void> _addUpdatesPagesFromStructure(
    pw.Document pdf,
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
    pw.MemoryImage logoImage,
    List<List<_ContentSection>> pagesStructure,
  ) async {
    // Create PDF pages from structure
    for (int pageIndex = 0; pageIndex < pagesStructure.length; pageIndex++) {
      final pageContent = pagesStructure[pageIndex];
      // Calculate page numbers: main page (1) + updates pages
      final currentPageNumber = 2 + pageIndex; // Updates start from page 2
      // Total pages will be main page + all updates pages
      final totalPages = 1 + pagesStructure.length;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(PDFConstants.pageMargin),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Main content
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header and content
                    _buildHeader(isArabic, font, arabicFont, logoImage),
                    _buildUpdatesDocumentTitle(isArabic, font, arabicFont),
                    pw.SizedBox(height: 16),
                    _buildRequestBasicInfo(request, isArabic, font, arabicFont),
                    // Main content
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Add page content (basic info will be included from sections)
                        ...pageContent.map((section) => section.widget),
                      ],
                    ),
                  ],
                ),

                // Signature section at bottom (above footer)
                pw.Positioned(
                  bottom: 75,
                  left: 0,
                  right: 0,
                  child: pw.Container(
                    color: PdfColors.white,
                    child: _buildEmployeeSignatureSection(request, isArabic, font, arabicFont),
                  ),
                ),

                // Footer at very bottom
                pw.Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: pw.Container(
                    color: PdfColors.white,
                    padding: const pw.EdgeInsets.only(top: 10),
                    child: _buildUpdatesPrintInfoWithPaging(isArabic, font, arabicFont, currentPageNumber, totalPages),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  /// Add updates pages with dynamic pagination to handle content overflow
  Future<void> _addUpdatesPagesWithPagination(
    pw.Document pdf,
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
    pw.MemoryImage logoImage,
    bool hasFinanceUpdates,
    bool hasUnscheduledPayments,
    bool hasScheduledPayments,
  ) async {
    // Calculate content sections and their estimated heights
    final sections = <_ContentSection>[];

    if (hasFinanceUpdates) {
      sections.add(
        _ContentSection(
          widget: _buildFinanceUpdatesSection(request, isArabic, font, arabicFont),
          estimatedHeight: isArabic ? 100 : 80, // More space for Arabic
          isRequired: false,
        ),
      );
    }

    if (hasUnscheduledPayments) {
      final paymentCount = request.unscheduledPayments?.length ?? 0;
      final itemHeight = isArabic ? 50 : 35; // Even larger height for Arabic items
      final maxItemsPerSection = isArabic ? 6 : 10; // Fewer items per section for Arabic

      if (paymentCount <= maxItemsPerSection) {
        sections.add(
          _ContentSection(
            widget: _buildUnscheduledPaymentsSection(request, isArabic, font, arabicFont),
            estimatedHeight: (isArabic ? 40.0 : 20.0) + (paymentCount * itemHeight),
            isRequired: false,
          ),
        );
      } else {
        // Split into multiple smaller sections for Arabic
        final chunks = <List>[];
        for (int i = 0; i < paymentCount; i += maxItemsPerSection) {
          final end = (i + maxItemsPerSection > paymentCount) ? paymentCount : i + maxItemsPerSection;
          chunks.add(request.unscheduledPayments!.sublist(i, end));
        }

        for (int i = 0; i < chunks.length; i++) {
          final chunkRequest = request.copyWith(unscheduledPayments: chunks[i].cast<UnscheduledPayment>());

          sections.add(
            _ContentSection(
              widget: _buildUnscheduledPaymentsSection(chunkRequest, isArabic, font, arabicFont),
              estimatedHeight: (isArabic ? 40.0 : 20.0) + (chunks[i].length * itemHeight),
              isRequired: false,
            ),
          );
        }
      }
    }

    if (hasScheduledPayments) {
      final paymentCount = request.scheduledPayments?.length ?? 0;
      final itemHeight = isArabic ? 50 : 35; // Larger height for Arabic items
      final maxItemsPerSection = isArabic ? 8 : 12; // Fewer items per section for Arabic

      if (paymentCount <= maxItemsPerSection) {
        sections.add(
          _ContentSection(
            widget: _buildScheduledPaymentsPaginated(request, isArabic, font, arabicFont),
            estimatedHeight: (isArabic ? 40.0 : 20.0) + (paymentCount * itemHeight),
            isRequired: false,
          ),
        );
      } else {
        // Split into multiple smaller sections for Arabic
        final chunks = <List>[];
        for (int i = 0; i < paymentCount; i += maxItemsPerSection) {
          final end = (i + maxItemsPerSection > paymentCount) ? paymentCount : i + maxItemsPerSection;
          chunks.add(request.scheduledPayments!.sublist(i, end));
        }

        for (int i = 0; i < chunks.length; i++) {
          final chunkRequest = request.copyWith(scheduledPayments: chunks[i].cast<ScheduledPayment>());

          sections.add(
            _ContentSection(
              widget: _buildScheduledPaymentsPaginated(chunkRequest, isArabic, font, arabicFont),
              estimatedHeight: (isArabic ? 40.0 : 20.0) + (chunks[i].length * itemHeight),
              isRequired: false,
            ),
          );
        }
      }
    }

    if (hasUnscheduledPayments || hasScheduledPayments) {
      sections.add(
        _ContentSection(
          widget: _buildPaymentSummarySection(request, isArabic, font, arabicFont),
          estimatedHeight: isArabic ? 100 : 80, // More space for Arabic
          isRequired: false,
        ),
      );
    }

    // Available content height (A4 page minus margins and header)
    const double pageHeight = 842; // A4 height in points
    final double headerHeight = isArabic ? 170 : 150; // More space for Arabic headers
    const double signatureHeight = 50; // Employee signature section
    const double footerHeight = 30; // Footer height ("Printed on" section)
    const double margins = PDFConstants.pageMargin * 2;
    final double availableHeight = pageHeight - headerHeight - signatureHeight - footerHeight - margins;

    // Group sections into pages with more conservative height checking for Arabic
    final pages = <List<_ContentSection>>[];
    var currentPage = <_ContentSection>[];
    var currentPageHeight = 0.0;
    // Use 80% of available height for Arabic to ensure no overflow, 90% for English
    final safeAvailableHeight = availableHeight * (isArabic ? 0.50 : 0.60);

    for (final section in sections) {
      // Check if section fits in current page
      if (currentPageHeight + section.estimatedHeight <= safeAvailableHeight && currentPage.isNotEmpty) {
        currentPage.add(section);
        currentPageHeight += section.estimatedHeight;
      } else {
        // Start new page
        if (currentPage.isNotEmpty) {
          pages.add(List.from(currentPage));
        }
        currentPage = [section];
        currentPageHeight = section.estimatedHeight;
      }
    }

    // Add the last page if it has content
    if (currentPage.isNotEmpty) {
      pages.add(currentPage);
    }

    // Create PDF pages
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageContent = pages[pageIndex];
      final isLastPage = pageIndex == pages.length - 1;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(PDFConstants.pageMargin),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(isArabic, font, arabicFont, logoImage),
                _buildUpdatesDocumentTitle(isArabic, font, arabicFont),
                pw.SizedBox(height: 16),

                // Add page content
                ...pageContent.map((section) => section.widget),

                // Add spacer and footer on last page
                if (isLastPage) ...[
                  pw.SizedBox(height: 44),

                  _buildUpdatesPrintInfoWithPaging(isArabic, font, arabicFont, 1 + pageIndex, pages.length),
                ],
              ],
            );
          },
        ),
      );
    }
  }

  /// Build updates document title
  pw.Widget _buildUpdatesDocumentTitle(bool isArabic, pw.Font font, pw.Font arabicFont) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            isArabic ? 'تحديثات طلب السلفة' : 'Advance Request Updates',
            style: _createTextStyle(
              isArabic: isArabic,
              font: font,
              arabicFont: arabicFont,
              fontSize: PDFConstants.titleFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Container(width: 200, height: 2, color: PdfColors.black),
        ],
      ),
    );
  }

  /// Build request basic information for updates page
  pw.Widget _buildRequestBasicInfo(
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    final currency = isArabic ? 'جنيه' : 'EGP';

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? 'معلومات أساسية' : 'Basic Information',
            style: _createTextStyle(
              isArabic: isArabic,
              font: font,
              arabicFont: arabicFont,
              fontSize: PDFConstants.bodyFontSize + 2,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSimpleInfoRow(
                  isArabic ? 'رقم الطلب:' : 'Request ID:',
                  request.id?.toString() ?? 'N/A',
                  isArabic,
                  font,
                  arabicFont,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildSimpleInfoRow(
                  isArabic ? 'كود المقترض:' : 'Borrower Code:',
                  request.borrowerCode?.toString() ?? 'N/A',
                  isArabic,
                  font,
                  arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          _buildSimpleInfoRow(
            isArabic ? 'اسم المقترض:' : 'Borrower Name:',
            _getDisplayName(isArabic, request.borrowerEnglishName, request.borrowerArabicName),
            isArabic,
            font,
            arabicFont,
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSimpleInfoRow(
                  isArabic ? 'المبلغ:' : 'Amount:',
                  '${NumberFormat('#,##0.00').format(request.amount ?? 0)} $currency',
                  isArabic,
                  font,
                  arabicFont,
                ),
              ),
            ],
          ),
          _buildAmountInWordsRow(
            'Amount in Words',
            isArabic ? 'المبلغ بالحروف' : 'Amount in Words',
            isArabic ? (request.amountInLettersArabic ?? 'N/A') : (request.amountInLettersEnglish ?? 'N/A'),
            isArabic,
            font,
            arabicFont,
          ),
        ],
      ),
    );
  }

  /// Build finance updates section
  pw.Widget _buildFinanceUpdatesSection(
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    final currency = isArabic ? 'جنيه' : 'EGP';
    final monthsText = isArabic ? 'أشهر' : 'months';

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? 'التحديثات المالية' : 'Finance Updates',
            style: _createTextStyle(
              isArabic: isArabic,
              font: font,
              arabicFont: arabicFont,
              fontSize: PDFConstants.bodyFontSize + 2,
              fontWeight: pw.FontWeight.bold,
            ).copyWith(color: PdfColors.black),
          ),
          pw.SizedBox(height: 8),
          if (request.updatedPeriod != null)
            _buildSimpleInfoRow(
              isArabic ? 'الفترة المحدثة:' : 'Updated Period:',
              '${request.updatedPeriod} $monthsText',
              isArabic,
              font,
              arabicFont,
              labelWidth: 200,
            ),
          if (request.currentMonthlyPayment != null)
            _buildSimpleInfoRow(
              isArabic ? 'القسط الشهري الحالي:' : 'Current Monthly Payment:',
              '${NumberFormat('#,##0.00').format(request.currentMonthlyPayment!)} $currency',
              isArabic,
              font,
              arabicFont,
              fontWeight: pw.FontWeight.bold,
              valueColor: PdfColors.black,
              labelWidth: 200,
            ),
          if (request.updatedPaymentEndDate != null)
            _buildSimpleInfoRow(
              isArabic ? 'تاريخ انتهاء السداد المحدث:' : 'Updated Payment End Date:',
              DateFormat('dd/MM/yyyy').format(request.updatedPaymentEndDate!),
              isArabic,
              font,
              arabicFont,
              labelWidth: 200,
            ),
        ],
      ),
    );
  }

  /// Build unscheduled payments section
  pw.Widget _buildUnscheduledPaymentsSection(
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    final currency = isArabic ? 'جنيه' : 'EGP';

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? 'الدفعات غير المجدولة' : 'Unscheduled Payments',
            style: _createTextStyle(
              isArabic: isArabic,
              font: font,
              arabicFont: arabicFont,
              fontSize: PDFConstants.bodyFontSize + 2,
              fontWeight: pw.FontWeight.bold,
            ).copyWith(color: PdfColors.black),
          ),
          pw.SizedBox(height: 8),
          ...request.unscheduledPayments!.map(
            (payment) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 4),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.grey50, borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 150,
                    child: pw.Text(
                      '${NumberFormat('#,##0.00').format(payment.amount)} $currency',
                      style: _createTextStyle(
                        isArabic: isArabic,
                        font: font,
                        arabicFont: arabicFont,
                        fontSize: PDFConstants.bodyFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(
                    width: 150,
                    child: pw.Text(
                      DateFormat('dd/MM/yyyy').format(payment.paymentDate),
                      style: _createTextStyle(
                        isArabic: isArabic,
                        font: font,
                        arabicFont: arabicFont,
                        fontSize: PDFConstants.bodyFontSize,
                      ),
                    ),
                  ),

                  if (payment.notes != null && payment.notes!.isNotEmpty)
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        payment.notes!,
                        style: _createTextStyle(
                          isArabic: isArabic,
                          font: font,
                          arabicFont: arabicFont,
                          fontSize: PDFConstants.bodyFontSize - 1,
                        ),
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build payment summary section
  pw.Widget _buildPaymentSummarySection(
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    final currency = isArabic ? 'جنيه' : 'EGP';
    final hasUnscheduled = request.unscheduledPayments != null && request.unscheduledPayments!.isNotEmpty;
    final hasScheduled = request.scheduledPayments != null && request.scheduledPayments!.isNotEmpty;

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? 'ملخص الدفعات' : 'Payments Summary',
            style: _createTextStyle(
              isArabic: isArabic,
              font: font,
              arabicFont: arabicFont,
              fontSize: PDFConstants.bodyFontSize + 2,
              fontWeight: pw.FontWeight.bold,
            ).copyWith(color: PdfColors.black),
          ),
          pw.SizedBox(height: 8),
          if (hasUnscheduled)
            _buildSimpleInfoRow(
              isArabic ? 'إجمالي الدفعات غير المجدولة:' : 'Total Unscheduled Payments:',
              '${NumberFormat('#,##0.00').format(request.totalUnscheduledPayments)} $currency',
              isArabic,
              font,
              arabicFont,
              labelWidth: 200,
            ),
          if (hasScheduled)
            _buildSimpleInfoRow(
              isArabic ? 'إجمالي الدفعات المجدولة:' : 'Total Scheduled Payments:',
              '${NumberFormat('#,##0.00').format(request.totalScheduledPayments)} $currency',
              isArabic,
              font,
              arabicFont,
              labelWidth: 200,
            ),
          if (hasUnscheduled && hasScheduled)
            _buildSimpleInfoRow(
              isArabic ? 'إجمالي جميع الدفعات:' : 'Total All Payments:',
              '${NumberFormat('#,##0.00').format(request.totalUnscheduledPayments + request.totalScheduledPayments)} $currency',
              isArabic,
              font,
              arabicFont,
              fontWeight: pw.FontWeight.bold,
              labelWidth: 200,
            ),
          pw.Container(height: 1, color: PdfColors.grey200, margin: const pw.EdgeInsets.symmetric(vertical: 8)),
          if (request.manuallySettled == false)
            _buildSimpleInfoRow(
              isArabic ? 'المبلغ المتبقي:' : 'Remaining Amount:',
              '${NumberFormat('#,##0.00').format(request.remainingAmount)} $currency',
              isArabic,
              font,
              arabicFont,
              fontWeight: pw.FontWeight.bold,
              valueColor: PdfColors.black,
              labelWidth: 200,
            ),
          if (request.manuallySettled == true)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                isArabic
                    ? 'تم تسوية هذا الطلب يدويًا بواسطة ${request.getLatestSettlerName(isArabic)} في ${request.getLatestSettlementDate() != null ? DateFormat('dd/MM/yyyy').format(request.getLatestSettlementDate()!) : ''}.'
                    : 'This request has been manually settled by ${request.getLatestSettlerName(isArabic)} on ${request.getLatestSettlementDate() != null ? DateFormat('dd/MM/yyyy').format(request.getLatestSettlementDate()!) : ''}.',
                style: _createTextStyle(
                  isArabic: isArabic,
                  font: font,
                  arabicFont: arabicFont,
                  fontSize: PDFConstants.bodyFontSize - 1,
                  fontWeight: pw.FontWeight.bold,
                ).copyWith(color: PdfColors.black),
              ),
            ),
        ],
      ),
    );
  }

  /// Build simple info row for updates sections
  pw.Widget _buildSimpleInfoRow(
    String label,
    String value,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont, {
    pw.FontWeight? fontWeight,
    PdfColor? valueColor,
    double labelWidth = 120, // Default width, can be overridden for longer labels
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(
              label,
              style: _createTextStyle(
                isArabic: isArabic,
                font: font,
                arabicFont: arabicFont,
                fontSize: PDFConstants.bodyFontSize - 1,
                fontWeight: pw.FontWeight.bold,
              ).copyWith(color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: _createTextStyle(
                isArabic: isArabic,
                font: font,
                arabicFont: arabicFont,
                fontSize: PDFConstants.bodyFontSize - 1,
                fontWeight: fontWeight ?? pw.FontWeight.normal,
              ).copyWith(color: valueColor ?? PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  /// Build print info with page numbering for updates page
  pw.Widget _buildUpdatesPrintInfoWithPaging(
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
    int currentPage,
    int totalPages,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          isArabic
              ? 'طُبع في ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'
              : 'printed on ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
          style: _createTextStyle(
            isArabic: isArabic,
            font: font,
            arabicFont: arabicFont,
            fontSize: PDFConstants.bodyFontSize - 1,
          ).copyWith(color: PdfColors.grey600),
        ),
        pw.Text(
          isArabic ? 'صفحة $currentPage من $totalPages' : 'Page $currentPage of $totalPages',
          style: _createTextStyle(
            isArabic: isArabic,
            font: font,
            arabicFont: arabicFont,
            fontSize: PDFConstants.bodyFontSize - 1,
          ).copyWith(color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Build employee signature section for all pages
  pw.Widget _buildEmployeeSignatureSection(
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20, bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Employee Signature
          pw.Row(
            children: [
              pw.Text(
                isArabic ? 'توقيع الموظف:' : 'Employee Signature:',
                style: _createTextStyle(isArabic: isArabic, font: font, arabicFont: arabicFont, fontSize: 10),
              ),
              pw.SizedBox(width: 10),
              pw.Container(width: 150),
            ],
          ),
          // Date
          pw.Row(
            children: [
              pw.Text(
                isArabic ? 'التاريخ:' : 'Date:',
                style: _createTextStyle(isArabic: isArabic, font: font, arabicFont: arabicFont, fontSize: 10),
              ),
              pw.SizedBox(width: 10),
              pw.Container(width: 100),
            ],
          ),
        ],
      ),
    );
  }

  /// Build document header with logo and company info
  pw.Widget _buildHeader(bool isArabic, pw.Font font, pw.Font arabicFont, pw.MemoryImage logoImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            // Company logo
            pw.Container(width: 200, height: 100, child: pw.Image(logoImage, fit: pw.BoxFit.contain)),
          ],
        ),
      ],
    );
  }

  /// Build document title section
  pw.Widget _buildDocumentTitle(bool isArabic, pw.Font font, pw.Font arabicFont) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            isArabic ? 'طلب سلفة' : PDFConstants.documentTitle,
            style: _createTextStyle(
              isArabic: isArabic,
              font: font,
              arabicFont: arabicFont,
              fontSize: PDFConstants.titleFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Container(width: 200, height: 2, color: PdfColors.black),
        ],
      ),
    );
  }

  /// Build request information section
  pw.Widget _buildRequestInfo(AdvanceOnSalaryRequestModel request, bool isArabic, pw.Font font, pw.Font arabicFont) {
    final requestorName =
        isArabic
            ? (request.requestorArabicName ?? request.requestorEnglishName ?? 'N/A')
            : (request.requestorEnglishName ?? request.requestorArabicName ?? 'N/A');
    return _buildSection(
      isArabic: isArabic,
      font: font,
      arabicFont: arabicFont,
      children: [
        _buildInfoRow(
          'Requestor Name',
          isArabic ? 'مقدم الطلب' : 'Requestor',
          requestorName,
          isArabic,
          font,
          arabicFont,
        ),
        _buildInfoRow(
          'Requestor Code',
          isArabic ? 'كود مقدم الطلب' : 'Requestor Code',
          request.requestorCode?.toString() ?? 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
      ],
    );
  }

  /// Build employee details section
  pw.Widget _buildEmployeeDetails(
    AdvanceOnSalaryRequestModel request,
    UserModel? borrowerUser,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    // Use UserModel data if available, fallback to request data
    final employeeName =
        isArabic
            ? (borrowerUser?.arabicName ??
                request.borrowerArabicName ??
                borrowerUser?.englishName ??
                request.borrowerEnglishName ??
                'N/A')
            : (borrowerUser?.englishName ??
                request.borrowerEnglishName ??
                borrowerUser?.arabicName ??
                request.borrowerArabicName ??
                'N/A');

    final department =
        isArabic
            ? (borrowerUser?.department ?? borrowerUser?.englishDepartment ?? 'N/A')
            : (borrowerUser?.englishDepartment ?? borrowerUser?.department ?? 'N/A');

    final title =
        isArabic
            ? (borrowerUser?.title ?? borrowerUser?.englishTitle ?? 'N/A')
            : (borrowerUser?.englishTitle ?? borrowerUser?.title ?? 'N/A');

    return _buildSection(
      isArabic: isArabic,
      font: font,
      arabicFont: arabicFont,
      children: [
        _buildInfoRow('Name', isArabic ? 'المقترض' : 'Borrower', employeeName, isArabic, font, arabicFont),
        _buildInfoRow(
          'Employee Code',
          isArabic ? 'كود المقترض' : 'Borrower Code',
          request.borrowerCode?.toString() ?? 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
        _buildInfoRow('Department', isArabic ? 'القسم' : 'Department', department, isArabic, font, arabicFont),
        _buildInfoRow('Job Title', isArabic ? 'المسمى الوظيفي' : 'Job Title', title, isArabic, font, arabicFont),
        if (borrowerUser?.location != null)
          _buildInfoRow(
            'Location',
            isArabic ? 'الموقع' : 'Location',
            borrowerUser!.location!,
            isArabic,
            font,
            arabicFont,
          ),
        if (borrowerUser?.hireDate != null)
          _buildInfoRow(
            'Hire Date',
            isArabic ? 'تاريخ التعيين' : 'Hire Date',
            borrowerUser!.hireDate!,
            isArabic,
            font,
            arabicFont,
          ),
      ],
    );
  }

  /// Build financial details section
  pw.Widget _buildFinancialDetails(
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    final currency = isArabic ? 'جنيه' : 'EGP';
    final monthsText = isArabic ? 'أشهر' : 'months';

    return _buildSection(
      isArabic: isArabic,
      font: font,
      arabicFont: arabicFont,
      children: [
        _buildInfoRow(
          'Request ID',
          isArabic ? 'رقم الطلب' : 'Request ID',
          request.id?.toString() ?? 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
        _buildInfoRow(
          'Date Created',
          isArabic ? 'تاريخ الإنشاء' : 'Date Created',
          request.createdAt != null ? DateFormat('dd/MM/yyyy').format(request.createdAt!) : 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
        _buildInfoRow(
          'Amount Requested',
          isArabic ? 'المبلغ' : 'Amount Requested',
          '${NumberFormat('#,##0.00').format(request.amount ?? 0)} $currency',
          isArabic,
          font,
          arabicFont,
        ),
        _buildAmountInWordsRow(
          'Amount Requested in Words',
          isArabic ? 'المبلغ بالحروف' : 'Amount Requested in Words',
          isArabic ? (request.amountInLettersArabic ?? 'N/A') : (request.amountInLettersEnglish ?? 'N/A'),
          isArabic,
          font,
          arabicFont,
        ),
        pw.Container(height: 0.5, color: PdfColors.grey300),
        _buildInfoRow(
          'Period',
          isArabic ? 'الفترة' : 'Period',
          '${request.periodInMonths ?? 0} $monthsText',
          isArabic,
          font,
          arabicFont,
        ),
        _buildInfoRow(
          'Monthly Payment',
          isArabic ? 'السداد الشهري' : 'Monthly Payment',
          '${NumberFormat('#,##0.00').format(request.monthlyPayment ?? 0)} $currency',
          isArabic,
          font,
          arabicFont,
        ),
        _buildInfoRow(
          'Payment Start Date',
          isArabic ? 'تاريخ بداية السداد' : 'Payment Start Date',
          request.paymentStartDate != null ? DateFormat('dd/MM/yyyy').format(request.paymentStartDate!) : 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
        _buildInfoRow(
          'Payment End Date',
          isArabic ? 'تاريخ انتهاء السداد' : 'Payment End Date',
          request.paymentEndDate != null ? DateFormat('dd/MM/yyyy').format(request.paymentEndDate!) : 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
      ],
    );
  }

  /// Build approval chain section with total pages info
  Future<pw.Widget> _buildApprovalChainWithTotal(
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
    int totalPages,
  ) async {
    // Fetch approver user data
    UserModel? n2User, hrUser, financeUser;

    if (_usersRepo != null) {
      try {
        // Get N+2 user
        if (request.n2Code != null) {
          n2User = await _usersRepo.getEmployeeById(request.n2Code!);
        }

        // Get HR user
        if (request.hrApproverCode != null) {
          hrUser = await _usersRepo.getEmployeeById(request.hrApproverCode!);
        }

        // Get Finance user
        if (request.financeApproverCode != null) {
          financeUser = await _usersRepo.getEmployeeById(request.financeApproverCode!);
        }
      } catch (e) {
        // If fetching fails, continue with null users
      }
    }

    return _buildSection(
      title: isArabic ? 'الموافقات' : 'Approvals',
      isArabic: isArabic,
      font: font,
      arabicFont: arabicFont,
      children: [
        pw.SizedBox(height: isArabic ? 0 : 8),
        // Header row
        pw.Container(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  isArabic ? 'المراجع' : 'Approver',
                  style: _createTextStyle(
                    isArabic: isArabic,
                    font: font,
                    arabicFont: arabicFont,
                    fontSize: PDFConstants.bodyFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 10,
                child: pw.Center(
                  child: pw.Text(
                    isArabic ? 'الاسم' : 'Name',
                    style: _createTextStyle(
                      isArabic: isArabic,
                      font: font,
                      arabicFont: arabicFont,
                      fontSize: PDFConstants.bodyFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                flex: 3,
                child: pw.Center(
                  child: pw.Text(
                    isArabic ? 'الكود' : 'Code',
                    style: _createTextStyle(
                      isArabic: isArabic,
                      font: font,
                      arabicFont: arabicFont,
                      fontSize: PDFConstants.bodyFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  isArabic ? 'تاريخ الموافقة' : 'Approval Date',
                  style: _createTextStyle(
                    isArabic: isArabic,
                    font: font,
                    arabicFont: arabicFont,
                    fontSize: PDFConstants.bodyFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        // N+1 row
        _buildApprovalRow(
          isArabic ? 'المدير المباشر' : 'First-Line Manager',
          _getDisplayName(isArabic, request.requestorEnglishName, request.requestorArabicName),
          request.requestorCode?.toString() ?? 'N/A',
          request.createdAt != null ? DateFormat('dd/MM/yyyy').format(request.createdAt!) : 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
        // Underline for the row
        pw.Container(height: 0.5, color: PdfColors.grey400),
        // N+2 row
        _buildApprovalRow(
          isArabic ? 'مدير المدير' : 'Second-Line Manager',
          _getDisplayName(isArabic, n2User?.englishName, n2User?.arabicName),
          request.n2Code?.toString() ?? 'N/A',
          request.n2ApprovalDate != null ? DateFormat('dd/MM/yyyy').format(request.n2ApprovalDate!) : 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
        // Underline for the row
        pw.Container(height: 0.5, color: PdfColors.grey400),
        // HR row
        _buildApprovalRow(
          isArabic ? 'الموارد البشرية' : 'HR',
          _getDisplayName(isArabic, hrUser?.englishName, hrUser?.arabicName),
          request.hrApproverCode?.toString() ?? 'N/A',
          request.hrApprovalDate != null ? DateFormat('dd/MM/yyyy').format(request.hrApprovalDate!) : 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
        // Underline for the row
        pw.Container(height: 0.5, color: PdfColors.grey400),
        // Finance row
        _buildApprovalRow(
          isArabic ? 'المالية' : 'Finance',
          _getDisplayName(isArabic, financeUser?.englishName, financeUser?.arabicName),
          request.financeApproverCode?.toString() ?? 'N/A',
          request.financeApprovalDate != null ? DateFormat('dd/MM/yyyy').format(request.financeApprovalDate!) : 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
        pw.SizedBox(height: isArabic ? 0 : 16),
        pw.Container(height: 2, color: PdfColors.black),
      ],
    );
  }

  /// Build approval row with approver title and underline
  pw.Widget _buildApprovalRow(
    String approverTitle,
    String name,
    String code,
    String approvalDate,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      children: [
        pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: isArabic ? 2 : 5),
          child: pw.Row(
            children: [
              // Approver title
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  approverTitle,
                  style: _createTextStyle(
                    isArabic: isArabic,
                    font: font,
                    arabicFont: arabicFont,
                    fontSize: PDFConstants.bodyFontSize,
                  ),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
              ),
              // Name
              pw.Expanded(
                flex: 7,
                child: pw.Text(
                  name,
                  style: _createTextStyle(
                    isArabic: isArabic,
                    font: font,
                    arabicFont: arabicFont,
                    fontSize: PDFConstants.bodyFontSize,
                  ),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
              ),
              // Code
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  code,
                  style: _createTextStyle(
                    isArabic: isArabic,
                    font: font,
                    arabicFont: arabicFont,
                    fontSize: PDFConstants.bodyFontSize,
                  ),
                ),
              ),
              // Approval Date
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  approvalDate,
                  style: _createTextStyle(
                    isArabic: isArabic,
                    font: font,
                    arabicFont: arabicFont,
                    fontSize: PDFConstants.bodyFontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  /// Helper method to get localized display name
  String _getDisplayName(bool isArabic, String? englishName, String? arabicName) {
    if (isArabic) {
      return arabicName ?? englishName ?? 'N/A';
    } else {
      return englishName ?? arabicName ?? 'N/A';
    }
  }

  /// Build a section with title and content
  pw.Widget _buildSection({
    String? title,
    required bool isArabic,
    required pw.Font font,
    required pw.Font arabicFont,
    required List<pw.Widget> children,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          pw.Text(
            title,
            style: _createTextStyle(
              isArabic: isArabic,
              font: font,
              arabicFont: arabicFont,
              fontSize: PDFConstants.titleFontSize - 3,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        ...children,
      ],
    );
  }

  /// Build amount in words row with proper Arabic text handling
  pw.Widget _buildAmountInWordsRow(
    String keyEn,
    String keyLocalized,
    String value,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont, {
    PdfColor? statusColor,
  }) {
    // Detect if the value contains Arabic characters
    final containsArabic = value.contains(RegExp(r'[\u0600-\u06FF]'));

    return pw.Column(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 120,
                child: pw.Text(
                  '$keyLocalized:',
                  style: _createTextStyle(
                    isArabic: isArabic,
                    font: font,
                    arabicFont: arabicFont,
                    fontSize: PDFConstants.bodyFontSize - 1,
                    fontWeight: pw.FontWeight.bold,
                  ).copyWith(color: PdfColors.grey700),
                ),
              ),
              pw.Expanded(
                child: pw.Directionality(
                  textDirection: containsArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  child: pw.Text(
                    value,
                    style: _createTextStyle(
                      isArabic: containsArabic, // Use Arabic font if text contains Arabic
                      font: font,
                      arabicFont: arabicFont,
                      fontSize: PDFConstants.bodyFontSize - 1,
                      fontWeight: statusColor != null ? pw.FontWeight.bold : pw.FontWeight.normal,
                    ).copyWith(color: PdfColors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build information row
  pw.Widget _buildInfoRow(
    String keyEn,
    String keyLocalized,
    String value,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont, {
    PdfColor? statusColor,
  }) {
    return pw.Column(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(vertical: isArabic ? 6 : 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 120,
                child: pw.Text(
                  '$keyLocalized:',
                  style: _createTextStyle(
                    isArabic: isArabic,
                    font: font,
                    arabicFont: arabicFont,
                    fontSize: PDFConstants.bodyFontSize - 1,
                    fontWeight: pw.FontWeight.bold,
                  ).copyWith(color: PdfColors.grey700),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  value,
                  style: _createTextStyle(
                    isArabic: isArabic,
                    font: font,
                    arabicFont: arabicFont,
                    fontSize: PDFConstants.bodyFontSize - 1,
                    fontWeight: statusColor != null ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ).copyWith(color: PdfColors.black),
                ),
              ),
            ],
          ),
        ),
        pw.Container(width: double.infinity, height: 0.5, color: PdfColors.grey300),
      ],
    );
  }

  /// Generate file name for PDF
  String _generateFileName(AdvanceOnSalaryRequestModel request) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'advance_salary_${request.id}_$timestamp${PDFConstants.fileExtension}';
  }

  /// Generate file name for cloud storage
  String _generateCloudFileName(AdvanceOnSalaryRequestModel request) {
    final timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
    return 'advance_request_${request.id}_$timestamp.pdf';
  }

  /// Generate file name for updates PDF
  String _generateUpdatesFileName(AdvanceOnSalaryRequestModel request) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'advance_updates_${request.id}_$timestamp${PDFConstants.fileExtension}';
  }

  /// Generate file name for updates cloud storage
  String _generateUpdatesCloudFileName(AdvanceOnSalaryRequestModel request) {
    final timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
    return 'advance_updates_${request.id}_$timestamp.pdf';
  }

  /// Save PDF to device storage
  Future<String> _savePDFToStorage(Uint8List pdfBytes, String fileName) async {
    try {
      // Web platform handling - trigger download
      if (kIsWeb) {
        _downloadFileWeb(pdfBytes, fileName);
        return 'Downloads/$fileName';
      }

      Directory directory;

      // Try different directory approaches with proper error handling for mobile/desktop
      try {
        // First try: Application documents directory
        directory = await getApplicationDocumentsDirectory();
      } catch (pluginException) {
        try {
          // Second try: External storage (Android) or temporary directory
          if (Platform.isAndroid) {
            directory = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
          } else {
            // For iOS, desktop, or other platforms
            directory = await getTemporaryDirectory();
          }
        } catch (fallbackException) {
          // Final fallback: Use temporary directory
          directory = await getTemporaryDirectory();
        }
      }

      final pdfDir = Directory('${directory.path}/${PDFConstants.pdfDirectory}');

      // Ensure directory exists
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final file = File('${pdfDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      return file.path;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  /// Download file on web platform
  void _downloadFileWeb(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      // Use the printing package's web download functionality
      // This is a simple fallback that should work
      throw Exception('Web download not implemented - please use Print PDF instead');
    }
  }

  /// Load default font
  Future<pw.Font> _loadFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  }

  /// Load Arabic font
  Future<pw.Font> _loadArabicFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
  }

  /// Load company logo
  Future<pw.MemoryImage> _loadLogo() async {
    final logoData = await rootBundle.load('assets/logo.png');
    return pw.MemoryImage(logoData.buffer.asUint8List());
  }

  /// Stands in for the Supabase Storage upload.
  ///
  /// The demo has no object store and makes no network calls. The PDF is still
  /// generated in full — it is simply handed back as a data URI instead of a
  /// bucket URL, so the download/print path works exactly as it does in
  /// production while staying entirely local.
  Future<String> _uploadPDFToSupabaseStorage(Uint8List pdfBytes, String fileName) async {
    return 'data:application/pdf;base64,${base64Encode(pdfBytes)}';
  }

  /// Create text style with proper font fallback for Arabic support
  pw.TextStyle _createTextStyle({
    required bool isArabic,
    required pw.Font font,
    required pw.Font arabicFont,
    required double fontSize,
    pw.FontWeight? fontWeight,
  }) {
    return pw.TextStyle(
      font: isArabic ? arabicFont : font,
      fontFallback: isArabic ? [font] : [arabicFont],
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  /// Get actual scheduled payments from database for current state PDF
  /// Only returns payments that actually exist in DB, does NOT calculate expected payments
  List<ScheduledPayment> _getMergedScheduledPayments(AdvanceOnSalaryRequestModel request) {
    // For current state PDF: ONLY show actual payments from database
    // Do NOT calculate expected payments - that's only for final state PDF
    return request.scheduledPayments ?? [];
  }

  /// Calculate complete scheduled payments for final state PDF
  /// Combines actual scheduled payments from DB with calculated remaining payments
  /// Ensures the payment schedule is complete from start to end date with zero remaining
  List<ScheduledPayment> _getCompleteScheduledPayments(AdvanceOnSalaryRequestModel request) {
    // Get payment dates
    final effectiveStartDate = request.paymentStartDate;
    final effectiveEndDate = request.updatedPaymentEndDate ?? request.paymentEndDate;
    final totalAmount = request.amount ?? 0.0;

    if (effectiveStartDate == null || effectiveEndDate == null) {
      return [];
    }

    // Get actual scheduled payments from database
    final actualPayments = request.scheduledPayments ?? [];

    // Calculate total paid through unscheduled payments
    final unscheduledTotal = (request.unscheduledPayments ?? []).fold<double>(
      0.0,
      (sum, payment) => sum + payment.amount,
    );

    // Calculate total from actual scheduled payments
    final scheduledTotal = actualPayments.fold<double>(0.0, (sum, payment) => sum + payment.amount);

    // Calculate remaining amount
    final remainingAmount = totalAmount - unscheduledTotal - scheduledTotal;

    // If fully paid, return only actual payments
    if (remainingAmount <= 0) {
      return actualPayments;
    }

    // Create a map of months that have actual payments
    final actualPaymentMonths = <String, ScheduledPayment>{};
    for (final payment in actualPayments) {
      final key = '${payment.paymentDate.year}-${payment.paymentDate.month}';
      actualPaymentMonths[key] = payment;
    }

    // Generate complete payment schedule from start to end date
    final List<ScheduledPayment> completePayments = [];
    int remainingMonthsCount = 0;

    // First pass: count remaining months from current month to end that need payments
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    DateTime checkDate = DateTime(effectiveStartDate.year, effectiveStartDate.month, 1);

    while (checkDate.isBefore(effectiveEndDate) ||
        (checkDate.year == effectiveEndDate.year && checkDate.month == effectiveEndDate.month)) {
      final key = '${checkDate.year}-${checkDate.month}';

      // Count months that don't have actual payments and are in current month or future
      if (!actualPaymentMonths.containsKey(key) &&
          (checkDate.isAfter(currentMonth) ||
              (checkDate.year == currentMonth.year && checkDate.month == currentMonth.month))) {
        remainingMonthsCount++;
      }

      checkDate = DateTime(checkDate.year, checkDate.month + 1, 1);
    }

    // Calculate payment amount for remaining months
    final paymentPerRemainingMonth = remainingMonthsCount > 0 ? remainingAmount / remainingMonthsCount : 0.0;

    // Second pass: build complete payment list from start to end
    checkDate = DateTime(effectiveStartDate.year, effectiveStartDate.month, 1);

    while (checkDate.isBefore(effectiveEndDate) ||
        (checkDate.year == effectiveEndDate.year && checkDate.month == effectiveEndDate.month)) {
      final key = '${checkDate.year}-${checkDate.month}';

      if (actualPaymentMonths.containsKey(key)) {
        // Use actual payment from database
        completePayments.add(actualPaymentMonths[key]!);
      } else {
        // Add calculated payment for remaining month
        completePayments.add(
          ScheduledPayment(
            id: null,
            advanceRequestId: request.id ?? 0,
            amount: paymentPerRemainingMonth,
            paymentDate: checkDate,
          ),
        );
      }

      checkDate = DateTime(checkDate.year, checkDate.month + 1, 1);
    }

    return completePayments;
  }

  pw.Widget _buildScheduledPaymentsPaginated(
    AdvanceOnSalaryRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    final currency = isArabic ? 'جنيه' : 'EGP';

    // Get merged payments (actual from DB or calculated expected)
    final scheduledPayments = _getMergedScheduledPayments(request);

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? 'الدفعات المجدولة' : 'Scheduled Payments',
            style: _createTextStyle(
              isArabic: isArabic,
              font: font,
              arabicFont: arabicFont,
              fontSize: PDFConstants.bodyFontSize + 2,
              fontWeight: pw.FontWeight.bold,
            ).copyWith(color: PdfColors.black),
          ),
          pw.SizedBox(height: 8),
          // Show ALL payments (no limit) - pagination will handle overflow
          ...scheduledPayments.map(
            (payment) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 4),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.grey50, borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 150,
                    child: pw.Text(
                      '${NumberFormat('#,##0.00').format(payment.amount)} $currency',
                      style: _createTextStyle(
                        isArabic: isArabic,
                        font: font,
                        arabicFont: arabicFont,
                        fontSize: PDFConstants.bodyFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy').format(payment.paymentDate),
                    style: _createTextStyle(
                      isArabic: isArabic,
                      font: font,
                      arabicFont: arabicFont,
                      fontSize: PDFConstants.bodyFontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Content section class for pagination calculations
class _ContentSection {
  final pw.Widget widget;
  final double estimatedHeight;
  final bool isRequired;

  _ContentSection({required this.widget, required this.estimatedHeight, required this.isRequired});
}
