import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../matrix/qr_matrix.dart';
import '../renderers/qr_render_pipeline.dart';
import '../styles/qr_design.dart';

/// Renders [matrix] with [design] into an image of
/// `size * pixelRatio` physical pixels.
///
/// [size] is in logical pixels, like the on-screen widget, so corner radii
/// and spacing keep their on-screen proportions at any [pixelRatio]. Uses
/// the same [QrRenderPipeline] as the widget.
Future<ui.Image> renderQrImage({
  required QrMatrix matrix,
  required QrDesign design,
  required double size,
  double pixelRatio = 1,
  ui.Image? logoImage,
}) async {
  assert(size > 0 && pixelRatio > 0, 'size and pixelRatio must be positive');
  final pixels = (size * pixelRatio).round();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(pixelRatio);
  QrRenderPipeline(
    matrix: matrix,
    design: design,
    logoImage: logoImage,
  ).paint(canvas, Size.square(size));
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(pixels, pixels);
  } finally {
    picture.dispose();
  }
}

/// Premultiplied RGBA bytes of [image], row-major.
Future<Uint8List> imageToRgba(ui.Image image) async {
  final data = await image.toByteData();
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// Loads [provider] into a decoded image, e.g. a `QrLogo.image` for export.
///
/// Requires the Flutter bindings (any running app has them).
Future<ui.Image> resolveQrLogoImage(
  ImageProvider provider, {
  ImageConfiguration configuration = ImageConfiguration.empty,
}) {
  final completer = Completer<ui.Image>();
  final stream = provider.resolve(configuration);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(info.image.clone());
      info.dispose();
    },
    onError: (error, stackTrace) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    },
  );
  stream.addListener(listener);
  return completer.future;
}
