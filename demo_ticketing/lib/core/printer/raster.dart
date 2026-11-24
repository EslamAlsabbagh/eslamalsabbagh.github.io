import 'dart:typed_data';

/// A 1-bit image as the printer takes it: rows of bytes, the leftmost dot in
/// the high bit, 1 = black. The width is padded to whole bytes with white.
class MonoBitmap {
  MonoBitmap({required this.width, required this.height, required this.data})
      : assert(data.length == ((width + 7) ~/ 8) * height);

  /// A white bitmap to draw into with [setBlack].
  MonoBitmap.blank(this.width, this.height) : data = Uint8List(((width + 7) ~/ 8) * height);

  final int width;
  final int height;
  final Uint8List data;

  int get bytesPerRow => (width + 7) ~/ 8;

  bool isBlack(int x, int y) => data[y * bytesPerRow + (x >> 3)] & (0x80 >> (x & 7)) != 0;

  void setBlack(int x, int y) => data[y * bytesPerRow + (x >> 3)] |= 0x80 >> (x & 7);
}

/// Rows per `GS v 0` command. Some printers have small receive buffers and
/// drop or garble one large image, so a tall ticket goes in bands.
const rasterBandRows = 256;

/// The ESC/POS bytes of one print job: reset, [bitmap] as `GS v 0` raster
/// bands, then feed and cut. Raster rather than text, because ESC/POS code
/// pages can't shape Arabic (ADR-0010).
List<int> rasterJobBytes(MonoBitmap bitmap) {
  final bytesPerRow = bitmap.bytesPerRow;
  final out = BytesBuilder(copy: false)..add(_init);
  for (var top = 0; top < bitmap.height; top += rasterBandRows) {
    final rows = bitmap.height - top < rasterBandRows ? bitmap.height - top : rasterBandRows;
    out
      // GS v 0 m xL xH yL yH: m = 0 (normal size), x = bytes per row, y = rows.
      ..add([0x1D, 0x76, 0x30, 0x00, bytesPerRow & 0xFF, bytesPerRow >> 8, rows & 0xFF, rows >> 8])
      ..add(Uint8List.sublistView(bitmap.data, top * bytesPerRow, (top + rows) * bytesPerRow));
  }
  out
    ..add(_feed4)
    ..add(_cut);
  return out.takeBytes();
}

/// The image a job from [rasterJobBytes] prints: its `GS v 0` bands stacked,
/// everything else skipped. For the virtual printer (`tool/`) and tests; it
/// reads only what this file writes, not any ESC/POS. Throws
/// [FormatException] on a band that runs past the end, or bands of
/// different widths.
MonoBitmap decodeRasterJob(List<int> bytes) {
  final data = BytesBuilder(copy: false);
  int? bytesPerRow;
  var height = 0;
  var i = 0;
  while (i < bytes.length) {
    final isBand = i + 8 <= bytes.length &&
        bytes[i] == 0x1D &&
        bytes[i + 1] == 0x76 &&
        bytes[i + 2] == 0x30;
    if (!isBand) {
      i++;
      continue;
    }
    final width = bytes[i + 4] | bytes[i + 5] << 8;
    final rows = bytes[i + 6] | bytes[i + 7] << 8;
    final end = i + 8 + width * rows;
    if (end > bytes.length) throw const FormatException('raster band runs past the end');
    if (bytesPerRow != null && bytesPerRow != width) {
      throw const FormatException('raster bands of different widths');
    }
    bytesPerRow = width;
    data.add(bytes.sublist(i + 8, end));
    height += rows;
    i = end;
  }
  return MonoBitmap(width: (bytesPerRow ?? 0) * 8, height: height, data: data.takeBytes());
}

const _init = [0x1B, 0x40]; // ESC @
const _feed4 = [0x1B, 0x64, 0x04]; // ESC d 4
const _cut = [0x1D, 0x56, 0x42, 0x00]; // GS V 66 0: feed to the cutter, partial cut
