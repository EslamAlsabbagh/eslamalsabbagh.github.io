import 'dart:typed_data';

// Web-specific PDF download functionality
void downloadPdfWeb(Uint8List bytes, String fileName) {
  // This will only work on web
  // Implementation will be provided in platform-specific files
  throw UnsupportedError('Web PDF download not available on this platform');
}