import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'register_output.dart';

/// The browser's [RegisterOutput].
class PlatformRegisterOutput implements RegisterOutput {
  static const String _frameId = 'register-print-frame';

  /// A Blob and a temporary `<a download>` click.
  @override
  Future<void> saveFile(Uint8List bytes, {required String name, required String mimeType}) async {
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = name
      ..style.display = 'none';
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    // Some browsers read the URL after `click` returns.
    Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
  }

  /// A hidden, same-origin `<iframe srcdoc>`. It prints once its fonts have
  /// loaded, and goes on `afterprint` (or before the next print, in a
  /// browser that doesn't send it).
  @override
  Future<void> printHtml(String html) async {
    web.document.getElementById(_frameId)?.remove();
    final frame = web.HTMLIFrameElement()
      ..id = _frameId
      ..setAttribute('aria-hidden', 'true')
      ..tabIndex = -1;
    frame.style
      ..position = 'fixed'
      ..width = '0'
      ..height = '0'
      ..border = '0'
      ..insetInlineEnd = '0'
      ..bottom = '0';
    final loaded = frame.onLoad.first;
    frame.srcdoc = html.toJS;
    web.document.body!.append(frame);
    await loaded;
    final window = frame.contentWindow!;
    await window.document.fonts.ready.toDart;
    window.addEventListener('afterprint', ((web.Event _) => frame.remove()).toJS);
    window
      ..focus()
      ..print();
  }

  @override
  String assetUrl(String asset) =>
      Uri.parse(web.document.baseURI).resolve(ui_web.assetManager.getAssetUrl(asset)).toString();
}
