import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../matrix/qr_matrix.dart';
import '../renderers/qr_render_pipeline.dart';
import '../styles/qr_design.dart';

/// [CustomPainter] that draws a [QrMatrix] with a [QrDesign].
///
/// Use it directly to embed a QR code in your own `CustomPaint` tree;
/// `FlexiQrGenerator` uses it internally.
class FlexiQrPainter extends CustomPainter {
  /// Creates a painter.
  FlexiQrPainter({required this.matrix, required this.design, this.logoImage});

  /// Matrix to draw.
  final QrMatrix matrix;

  /// Visual configuration.
  final QrDesign design;

  /// Decoded `QrDesign.logo` image, or null while loading / without logo.
  final ui.Image? logoImage;

  @override
  void paint(Canvas canvas, Size size) => QrRenderPipeline(
    matrix: matrix,
    design: design,
    logoImage: logoImage,
  ).paint(canvas, size);

  @override
  bool shouldRepaint(FlexiQrPainter oldDelegate) =>
      oldDelegate.matrix != matrix ||
      oldDelegate.design != design ||
      oldDelegate.logoImage != logoImage;
}
