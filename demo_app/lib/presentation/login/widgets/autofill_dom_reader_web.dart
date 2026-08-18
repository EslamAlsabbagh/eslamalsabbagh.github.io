import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Reads credential values the browser's password manager injected into the
/// engine's autofill `<form>` inputs, keyed by the engine's autofill names
/// (`username`, `current-password` — from BrowserAutofillHints).
///
/// The engine keeps that form in the DOM even after the text-input connection
/// closes (dormant state), so a fill triggered behind a Windows Hello dialog
/// lands in these inputs without ever reaching the framework. Harvesting the
/// DOM directly is the only way to recover those values.
Map<String, String> readBrowserAutofillValues() {
  final values = <String, String>{};
  final inputs = web.document.querySelectorAll('input[name="username"], input[name="current-password"]');
  for (var i = 0; i < inputs.length; i++) {
    final node = inputs.item(i);
    if (node != null && node.isA<web.HTMLInputElement>()) {
      final input = node as web.HTMLInputElement;
      if (input.value.isNotEmpty) {
        values[input.name] = input.value;
      }
    }
  }
  return values;
}
