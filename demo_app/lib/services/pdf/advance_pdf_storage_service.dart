import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/advance_on_salary_request_model.dart';
import 'pdf_generation_service.dart';

/// PDF generation and storage for advance-on-salary requests.
///
/// Production renders the PDF locally and uploads it to a Supabase Storage
/// bucket, persisting the returned public URL on the request row. The demo has
/// no object store and makes no network calls, so it renders the *same* PDF and
/// keeps it in memory as a data URI. Everything the user sees — generate,
/// preview, download, regenerate — behaves the same; only the bytes' resting
/// place differs.
class AdvancePDFStorageService {
  AdvancePDFStorageService({required PDFGenerationService pdfService})
      : _pdfService = pdfService;

  final PDFGenerationService _pdfService;

  /// requestId -> data URI, for the "current state" PDF.
  final Map<int, String> _current = <int, String>{};

  /// requestId -> data URI, for the post-approval "final state" PDF.
  final Map<int, String> _final = <int, String>{};

  String _toDataUri(Uint8List bytes) =>
      'data:application/pdf;base64,${base64Encode(bytes)}';

  Future<String> generateAndStorePDF(
    AdvanceOnSalaryRequestModel request,
    String locale,
  ) async {
    final bytes = await _pdfService.buildPDFDocument(request, locale);
    final uri = _toDataUri(bytes);
    if (request.id != null) _current[request.id!] = uri;
    return uri;
  }

  Future<void> _updateRequestWithPDFUrl(int requestId, String pdfUrl) async {
    _current[requestId] = pdfUrl;
  }

  Future<String?> getPDFUrl(int requestId) async => _current[requestId];

  Future<bool> hasPDF(int requestId) async =>
      (_current[requestId] ?? '').isNotEmpty;

  Future<Uint8List> downloadPDFBytes(String pdfUrl) async {
    final marker = 'base64,';
    final i = pdfUrl.indexOf(marker);
    if (i == -1) return Uint8List(0);
    return base64Decode(pdfUrl.substring(i + marker.length));
  }

  Future<String> ensurePDFExists(
    AdvanceOnSalaryRequestModel request,
    String locale,
  ) async {
    final existing = await getPDFUrl(request.id ?? -1);
    if (existing != null && existing.isNotEmpty) return existing;
    return generateAndStorePDF(request, locale);
  }

  Future<Uint8List> generateCurrentStatePDFBytes(
    AdvanceOnSalaryRequestModel request,
    String locale,
  ) async =>
      _pdfService.buildPDFDocument(request, locale);

  Future<String> generateAndStoreFinalPDF(
    AdvanceOnSalaryRequestModel request,
    String locale,
  ) async {
    final bytes = await _pdfService.buildFinalStatePDFDocument(request, locale);
    final uri = _toDataUri(bytes);
    if (request.id != null) _final[request.id!] = uri;
    return uri;
  }

  Future<void> _updateRequestWithFinalPDFUrl(int requestId, String pdfUrl) async {
    _final[requestId] = pdfUrl;
  }

  Future<String?> getFinalPDFUrl(int requestId) async => _final[requestId];

  Future<Map<String, String>> generateBothPDFs(
    AdvanceOnSalaryRequestModel request,
    String locale,
  ) async {
    final current = await generateAndStorePDF(request, locale);
    final finalUrl = await generateAndStoreFinalPDF(request, locale);
    await _updateRequestWithPDFUrl(request.id ?? -1, current);
    await _updateRequestWithFinalPDFUrl(request.id ?? -1, finalUrl);
    return {'current': current, 'final': finalUrl};
  }
}
