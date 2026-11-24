import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'raster.dart';

/// Renders [widget] off screen, [logicalWidth] wide and as tall as it lays
/// out, at [pixelRatio] image pixels per logical pixel.
///
/// The widget gets its own tree with no app around it: no theme, no
/// localizations, no media query except the pixel ratio (which the QR uses
/// to snap its modules to whole dots). Text defaults to the bundled font, in
/// black. Must run outside a widget test's fake async (`tester.runAsync`).
Future<ui.Image> renderWidgetImage(
  Widget widget, {
  required double logicalWidth,
  required double pixelRatio,
}) async {
  final view = WidgetsBinding.instance.platformDispatcher.implicitView ??
      WidgetsBinding.instance.platformDispatcher.views.first;
  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    child: boundary,
    configuration: ViewConfiguration(
      // Loose height: the view takes the content's height.
      logicalConstraints: BoxConstraints(minWidth: logicalWidth, maxWidth: logicalWidth),
      devicePixelRatio: pixelRatio,
    ),
  );
  final pipelineOwner = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final buildOwner = BuildOwner(focusManager: FocusManager());
  RenderObjectToWidgetElement<RenderBox>? root;
  try {
    root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        data: MediaQueryData(devicePixelRatio: pixelRatio),
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: AppSizes.fontFamily,
            color: Color(0xFF000000),
            fontSize: 14,
          ),
          child: widget,
        ),
      ),
    ).attachToRenderTree(buildOwner);
    buildOwner
      ..buildScope(root)
      ..finalizeTree();
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    return await boundary.toImage(pixelRatio: pixelRatio);
  } finally {
    // Unmount the page, so its states and render objects are disposed, then
    // take the tree down.
    if (root != null) {
      RenderObjectToWidgetAdapter<RenderBox>(container: boundary).attachToRenderTree(buildOwner, root);
      buildOwner
        ..buildScope(root)
        ..finalizeTree();
    }
    pipelineOwner.rootNode = null;
    pipelineOwner.dispose();
    renderView.dispose();
    buildOwner.focusManager.dispose();
  }
}

/// [image] as black and white dots: a pixel is black when it is darker than
/// mid grey over white paper. A threshold rather than dithering, because text
/// and QR modules need clean edges, and the ticket is black on white anyway.
Future<MonoBitmap> toMonoBitmap(ui.Image image) async {
  final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final pixels = Uint8List.sublistView(rgba);
  final bitmap = MonoBitmap.blank(image.width, image.height);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final i = (y * image.width + x) * 4;
      // Premultiplied channels; what isn't painted is white paper.
      final alpha = pixels[i + 3];
      final luminance =
          (299 * pixels[i] + 587 * pixels[i + 1] + 114 * pixels[i + 2]) ~/ 1000 + (255 - alpha);
      if (luminance < 128) bitmap.setBlack(x, y);
    }
  }
  return bitmap;
}
