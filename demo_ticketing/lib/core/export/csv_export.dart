import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// [rows] as CSV for Excel: UTF-8 with a BOM (so Arabic opens correctly),
/// CRLF line ends, and a formula guard on text cells (ADR-0031).
String encodeCsv(List<List<Object?>> rows) {
  final out = StringBuffer('﻿');
  for (final row in rows) {
    out
      ..write(row.map(_cell).join(','))
      ..write('\r\n');
  }
  return out.toString();
}

String _cell(Object? value) {
  if (value == null) return '';
  if (value is num) return value.toString();
  var text = value.toString();
  if (text.isNotEmpty && '=+-@\t\r'.contains(text[0])) text = "'$text";
  if (text.contains(RegExp('[",\r\n]'))) {
    text = '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

// Production writes the file to the Windows Downloads folder and can show it
// in Explorer. In a browser the download itself is the file, so these keep
// the same shapes for the pages and hand the CSV to the browser instead.

class Directory {
  const Directory(this.path);

  final String path;
}

class File {
  const File(this.path);

  final String path;
}

class FileSystemException implements Exception {
  const FileSystemException();
}

Directory? downloadsFolder() => const Directory('Downloads');

Future<File> saveCsv(Directory folder, String name, String csv) async {
  final bytes = utf8.encode(csv);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body!.append(link);
  link.click();
  link.remove();
  web.URL.revokeObjectURL(url);
  return File('${folder.path}/$name');
}

/// The browser already shows the download; nothing to open.
Future<void> showInFolder(File file) async {}
