import 'package:flutter/painting.dart';

import '../matrix/qr_matrix.dart';
import '../styles/qr_design.dart';
import '../styles/qr_module_style.dart';
import 'modules/module_geometry.dart';
import 'qr_render_layout.dart';

/// Draws a [QrMatrix] with a [QrDesign] onto any [Canvas].
///
/// The on-screen widget and image export share this pipeline, so both
/// produce identical output.
class QrRenderPipeline {
  /// Creates a pipeline for [matrix] and [design].
  const QrRenderPipeline({required this.matrix, required this.design});

  /// Matrix to draw.
  final QrMatrix matrix;

  /// Visual configuration.
  final QrDesign design;

  /// Paints the code centered in [size].
  void paint(Canvas canvas, Size size) {
    final layout = QrRenderLayout.compute(size, matrix.size, design.quietZone);

    if (design.backgroundColor.a > 0) {
      canvas.drawRect(layout.bounds, Paint()..color = design.backgroundColor);
    }

    // Modules sharing a style are merged into one path and filled once, so
    // touching modules have no anti-aliasing seams between them.
    final batches = <QrModuleStyle, Path>{};
    for (var row = 0; row < matrix.size; row++) {
      for (var col = 0; col < matrix.size; col++) {
        if (!matrix.isDark(row, col)) continue;
        final module = matrix.moduleAt(row, col);
        final style = design.styleFor(module);
        final path = buildModulePath(layout.cellRect(row, col), module, style);
        (batches[style] ??= Path()).addPath(path, Offset.zero);
      }
    }

    for (final MapEntry(key: style, value: path) in batches.entries) {
      canvas.drawPath(path, _paintFor(style, layout.matrixRect));
    }
  }

  static Paint _paintFor(QrModuleStyle style, Rect area) {
    final paint = Paint()..isAntiAlias = true;
    final gradient = style.gradient;
    if (gradient != null) {
      // With a shader, only the paint's alpha is used.
      paint
        ..shader = gradient.createShader(area)
        ..color = Color.fromRGBO(0, 0, 0, style.opacity);
    } else {
      paint.color = style.color.withValues(
        alpha: style.color.a * style.opacity,
      );
    }
    return paint;
  }
}
