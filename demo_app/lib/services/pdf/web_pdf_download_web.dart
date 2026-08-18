import 'dart:html' as html;
import 'dart:typed_data';

// Web-specific implementation
void downloadPdfWeb(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor =
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();

  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
