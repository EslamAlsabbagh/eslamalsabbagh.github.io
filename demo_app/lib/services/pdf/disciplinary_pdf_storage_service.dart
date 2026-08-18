import 'dart:convert';
import 'dart:typed_data';

/// PDF storage for disciplinary and investigation documents.
///
/// Production uploads to a Supabase Storage bucket and persists the public URL.
/// The demo keeps the bytes in memory as a data URI — no network call, same
/// user-facing behaviour.
class DisciplinaryPDFStorageService {
  DisciplinaryPDFStorageService();

  final Map<int, String> _urls = <int, String>{};

  String _toDataUri(Uint8List bytes) =>
      'data:application/pdf;base64,${base64Encode(bytes)}';

  Future<String> uploadInvestigationPDF(
    int requestId,
    Uint8List pdfBytes,
    String originalFileName,
  ) async {
    final uri = _toDataUri(pdfBytes);
    _urls[requestId] = uri;
    return uri;
  }

  Future<String> uploadLegalInvestigationPDF(
    int requestId,
    Uint8List pdfBytes,
    String originalFileName,
  ) async {
    final uri = _toDataUri(pdfBytes);
    _urls[requestId] = uri;
    return uri;
  }

  Future<void> updateRequestWithPDFUrl(int requestId, String pdfUrl) async {
    _urls[requestId] = pdfUrl;
  }

  Future<String?> getPDFUrl(int requestId) async => _urls[requestId];

  Future<bool> hasPDF(int requestId) async => (_urls[requestId] ?? '').isNotEmpty;

  /// Client-side validation of a user-picked attachment: must be a PDF, must
  /// be non-empty, and must be under 10 MB. Unchanged from production — this
  /// never touched the backend.
  static bool validatePDF(Uint8List bytes, String fileName) {
    if (bytes.isEmpty) return false;
    if (!fileName.toLowerCase().endsWith('.pdf')) return false;
    if (bytes.lengthInBytes > 10 * 1024 * 1024) return false;
    // %PDF magic number.
    if (bytes.length < 4) return false;
    return bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;
  }

  Future<Uint8List> downloadPDFBytes(String pdfUrl) async {
    const marker = 'base64,';
    final i = pdfUrl.indexOf(marker);
    if (i == -1) return Uint8List(0);
    return base64Decode(pdfUrl.substring(i + marker.length));
  }
}
