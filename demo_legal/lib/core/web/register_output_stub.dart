import 'dart:typed_data';

import 'register_output.dart';

/// Off the web (the VM tests): there is no browser to hand files to.
class PlatformRegisterOutput implements RegisterOutput {
  @override
  Future<void> saveFile(Uint8List bytes, {required String name, required String mimeType}) =>
      throw UnsupportedError('Downloads need a browser');

  @override
  Future<void> printHtml(String html) => throw UnsupportedError('Printing needs a browser');

  @override
  String assetUrl(String asset) => asset;
}
