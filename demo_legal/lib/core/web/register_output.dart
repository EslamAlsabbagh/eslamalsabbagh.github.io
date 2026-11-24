import 'dart:typed_data';

import 'register_output_stub.dart' if (dart.library.js_interop) 'register_output_web.dart' as platform;

/// Hands the exported contracts register to the browser: a file to
/// download, or a page to print. Built in `main.dart` and injected, so
/// tests can fake it.
abstract interface class RegisterOutput {
  /// The browser's, or one that throws where there is no browser.
  factory RegisterOutput() = platform.PlatformRegisterOutput;

  /// Downloads [bytes] as [name].
  Future<void> saveFile(Uint8List bytes, {required String name, required String mimeType});

  /// Opens the browser's print dialog for [html], from a hidden frame.
  Future<void> printHtml(String html);

  /// The absolute URL of a bundled asset, such as a font, which the print
  /// page loads from the app's own origin.
  String assetUrl(String asset);
}
