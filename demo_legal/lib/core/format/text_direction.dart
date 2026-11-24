import 'package:flutter/painting.dart' show TextDirection;
import 'package:intl/intl.dart' show Bidi;

/// The direction typed or stored text reads in. It is mostly Arabic, but a
/// brand name or a whole note may be in English (the brief: detect direction
/// per field). Blank text is RTL, so an empty field starts on the right.
TextDirection textDirectionOf(String text) =>
    text.trim().isEmpty || Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;
