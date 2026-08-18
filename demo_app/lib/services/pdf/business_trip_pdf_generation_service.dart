import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/business_trips.dart';
import '../../core/constants/pdf_constants.dart';
import '../../data/models/businesstrip_request_model.dart';

class BusinessTripPDFGenerationService {
  Future<String> generateBusinessTripPDF(BusinesstripRequestModel request, String locale) async {
    try {
      final pdfBytes = await buildPDFDocument(request, locale);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'business_trip_${request.id}_$timestamp${PDFConstants.fileExtension}';
      return await _savePDFToStorage(pdfBytes, fileName);
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  Future<Uint8List> buildPDFDocument(BusinesstripRequestModel request, String locale) async {
    final pdf = pw.Document();
    final isArabic = locale == 'ar';

    final font = await _loadFont();
    final arabicFont = await _loadArabicFont();
    final logoImage = await _loadLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(PDFConstants.pageMargin),
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (pw.Context context) => [
          _buildHeader(logoImage),
          pw.SizedBox(height: 8),
          _buildDocumentTitle(isArabic, font, arabicFont),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildSection(
                  title: isArabic ? 'بيانات الموظف' : 'Employee Information',
                  isArabic: isArabic,
                  font: font,
                  arabicFont: arabicFont,
                  children: [
                    _buildInfoRow(
                      isArabic ? 'الاسم' : 'Name',
                      isArabic
                          ? (request.userArabicName ?? request.userEnglishName ?? 'N/A')
                          : (request.userEnglishName ?? request.userArabicName ?? 'N/A'),
                      isArabic,
                      font,
                      arabicFont,
                    ),
                    _buildInfoRow(
                      isArabic ? 'الكود' : 'Employee Code',
                      request.userId.toString(),
                      isArabic,
                      font,
                      arabicFont,
                    ),
                    _buildInfoRow(
                      isArabic ? 'القسم' : 'Department',
                      isArabic
                          ? (request.userDepartment ?? request.userEnglishDepartment ?? 'N/A')
                          : (request.userEnglishDepartment ?? request.userDepartment ?? 'N/A'),
                      isArabic,
                      font,
                      arabicFont,
                    ),
                    _buildInfoRow(
                      isArabic ? 'المسمى الوظيفي' : 'Job Title',
                      isArabic
                          ? (request.userTitle ?? request.userEnglishTitle ?? 'N/A')
                          : (request.userEnglishTitle ?? request.userTitle ?? 'N/A'),
                      isArabic,
                      font,
                      arabicFont,
                    ),
                    if (request.userHireDate != null)
                      _buildInfoRow(
                        isArabic ? 'تاريخ التعيين' : 'Hire Date',
                        request.userHireDate!,
                        isArabic,
                        font,
                        arabicFont,
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildSection(
                  title: isArabic ? 'تفاصيل الرحلة' : 'Trip Details',
                  isArabic: isArabic,
                  font: font,
                  arabicFont: arabicFont,
                  children: [
                    _buildInfoRow(
                      isArabic ? 'رقم الطلب' : 'Request ID',
                      request.id?.toString() ?? 'N/A',
                      isArabic,
                      font,
                      arabicFont,
                    ),
                    _buildInfoRow(
                      isArabic ? 'تاريخ الإنشاء' : 'Created Date',
                      request.createdAt != null
                          ? DateFormat('dd/MM/yyyy').format(request.tzCreatedAt)
                          : 'N/A',
                      isArabic,
                      font,
                      arabicFont,
                    ),
                    _buildInfoRow(
                      isArabic ? 'من تاريخ' : 'Date From',
                      request.dateFrom != null
                          ? DateFormat('dd/MM/yyyy').format(request.dateFrom!)
                          : 'N/A',
                      isArabic,
                      font,
                      arabicFont,
                    ),
                    _buildInfoRow(
                      isArabic ? 'إلى تاريخ' : 'Date To',
                      request.dateTo != null
                          ? DateFormat('dd/MM/yyyy').format(request.dateTo!)
                          : 'N/A',
                      isArabic,
                      font,
                      arabicFont,
                    ),
                    _buildInfoRow(
                      isArabic ? 'الموقع' : 'Location',
                      request.location ?? 'N/A',
                      isArabic,
                      font,
                      arabicFont,
                    ),
                    if (locationDeservesTransportationFees(request.location))
                      _buildTransportationFeeRow(isArabic, font, arabicFont),
                    if (request.transportationFeeRequested)
                      _buildInfoRow(
                        isArabic ? 'بدل الانتقالات' : 'Transportation Fee',
                        request.transportationFeeAmount != null
                            ? '${_formatFeeAmount(request.transportationFeeAmount!)} ${isArabic ? 'ج.م' : 'EGP'}'
                            : 'N/A',
                        isArabic,
                        font,
                        arabicFont,
                      ),
                    _buildInfoRow(
                      isArabic ? 'عدد الأيام' : 'Number of Days',
                      request.numberOfDays?.toString() ?? 'N/A',
                      isArabic,
                      font,
                      arabicFont,
                    ),
                    if (request.numberOfHours != null) ...[
                      _buildInfoRow(
                        isArabic ? 'عدد الساعات' : 'Number of Hours',
                        request.numberOfHours!.toString(),
                        isArabic,
                        font,
                        arabicFont,
                      ),
                      if (request.amPm != null)
                        _buildInfoRow(
                          isArabic ? 'الفترة' : 'Period',
                          request.amPm!,
                          isArabic,
                          font,
                          arabicFont,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(width: double.infinity, height: 1, color: PdfColors.grey),
          pw.SizedBox(height: 16),
          _buildApprovalsSection(request, isArabic, font, arabicFont),
          pw.SizedBox(height: 16),
          _buildFooter(isArabic, font, arabicFont),
        ],
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildHeader(pw.MemoryImage logoImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Container(width: 200, height: 100, child: pw.Image(logoImage, fit: pw.BoxFit.contain)),
      ],
    );
  }

  pw.Widget _buildDocumentTitle(bool isArabic, pw.Font font, pw.Font arabicFont) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            isArabic ? 'طلب رحلة عمل' : 'Business Trip Request',
            style: _createTextStyle(
              isArabic: isArabic,
              font: font,
              arabicFont: arabicFont,
              fontSize: PDFConstants.titleFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Container(width: 220, height: 2, color: PdfColors.black),
        ],
      ),
    );
  }

  pw.Widget _buildApprovalsSection(
    BusinesstripRequestModel request,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    final n1Name = isArabic
        ? (request.n1ArabicName ?? request.n1EnglishName ?? 'N/A')
        : (request.n1EnglishName ?? request.n1ArabicName ?? 'N/A');
    final n2Name = isArabic
        ? (request.n2ArabicName ?? request.n2EnglishName ?? 'N/A')
        : (request.n2EnglishName ?? request.n2ArabicName ?? 'N/A');
    final hrName = isArabic
        ? (request.hrArabicName ?? request.hrEnglishName ?? 'N/A')
        : (request.hrEnglishName ?? request.hrArabicName ?? 'N/A');

    return _buildSection(
      title: isArabic ? 'الموافقات' : 'Approvals',
      isArabic: isArabic,
      font: font,
      arabicFont: arabicFont,
      children: [
        pw.SizedBox(height: 8),
        pw.Container(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
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
                flex: 8,
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
              pw.Expanded(
                flex: 4,
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
        if (request.n1ApprovalDate != null) ...[
          _buildApprovalRow(
            isArabic ? 'المدير المباشر' : 'First-Line Manager',
            n1Name,
            DateFormat('dd/MM/yyyy').format(request.n1ApprovalDate!),
            isArabic,
            font,
            arabicFont,
          ),
          pw.Container(height: 0.5, color: PdfColors.grey400),
        ],
        if (request.n2ApprovalDate != null) ...[
          _buildApprovalRow(
            isArabic ? 'مدير المدير' : 'Second-Line Manager',
            n2Name,
            DateFormat('dd/MM/yyyy').format(request.n2ApprovalDate!),
            isArabic,
            font,
            arabicFont,
          ),
          pw.Container(height: 0.5, color: PdfColors.grey400),
        ],
        _buildApprovalRow(
          isArabic ? 'الموارد البشرية' : 'HR',
          hrName,
          request.hrApprovalDate != null
              ? DateFormat('dd/MM/yyyy').format(request.hrApprovalDate!)
              : 'N/A',
          isArabic,
          font,
          arabicFont,
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: PdfColors.black),
      ],
    );
  }

  pw.Widget _buildApprovalRow(
    String approverTitle,
    String name,
    String approvalDate,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        children: [
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
          pw.Expanded(
            flex: 8,
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
          pw.Expanded(
            flex: 4,
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
    );
  }

  pw.Widget _buildFooter(bool isArabic, pw.Font font, pw.Font arabicFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          isArabic
              ? 'طُبع في ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'
              : 'Printed on ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
          style: _createTextStyle(
            isArabic: isArabic,
            font: font,
            arabicFont: arabicFont,
            fontSize: PDFConstants.smallFontSize,
          ).copyWith(color: PdfColors.grey600),
        ),
        pw.Text(
          PDFConstants.companyName,
          style: _createTextStyle(
            isArabic: isArabic,
            font: font,
            arabicFont: arabicFont,
            fontSize: PDFConstants.smallFontSize,
          ).copyWith(color: PdfColors.grey600),
        ),
      ],
    );
  }

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
          pw.SizedBox(height: 4),
        ],
        ...children,
      ],
    );
  }

  /// Formats a fee amount for display, dropping a trailing ".0".
  String _formatFeeAmount(double amount) {
    return amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toString();
  }

  /// Highlighted note shown under the location when it is eligible for
  /// transportation fees (e.g. North Square).
  pw.Widget _buildTransportationFeeRow(bool isArabic, pw.Font font, pw.Font arabicFont) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        isArabic
            ? 'هذا الموقع يستحق بدل انتقالات.'
            : 'This location is eligible for transportation fees.',
        style: _createTextStyle(
          isArabic: isArabic,
          font: font,
          arabicFont: arabicFont,
          fontSize: PDFConstants.bodyFontSize - 1,
          fontWeight: pw.FontWeight.bold,
        ).copyWith(color: PdfColors.blue800),
      ),
    );
  }

  pw.Widget _buildInfoRow(
    String label,
    String value,
    bool isArabic,
    pw.Font font,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(vertical: isArabic ? 6 : 10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 120,
                child: pw.Text(
                  '$label:',
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

  Future<pw.Font> _loadFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  }

  Future<pw.Font> _loadArabicFont() async {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
  }

  Future<pw.MemoryImage> _loadLogo() async {
    final logoData = await rootBundle.load('assets/logo.png');
    return pw.MemoryImage(logoData.buffer.asUint8List());
  }

  Future<String> _savePDFToStorage(Uint8List pdfBytes, String fileName) async {
    if (kIsWeb) {
      throw UnsupportedError('Use buildPDFDocument + downloadPdfWeb for web downloads');
    }

    Directory directory;
    try {
      directory = await getApplicationDocumentsDirectory();
    } catch (_) {
      directory = await getTemporaryDirectory();
    }

    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return filePath;
  }
}
