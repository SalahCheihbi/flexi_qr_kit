import 'package:flutter/painting.dart';

import '../../core/models/qr_corner.dart';
import '../matrix/qr_matrix.dart';
import '../styles/qr_design.dart';
import '../styles/qr_module_shape.dart';
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
    final n = matrix.size;
    final engine = design.smartCornerEngine;
    final styles = List<QrModuleStyle?>.filled(n * n, null);
    final batches = <QrModuleStyle, Path>{};
    var hasSmooth = false;

    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        if (!matrix.isDark(row, col)) continue;
        final module = matrix.moduleAt(row, col);
        final style = styles[row * n + col] = design.styleFor(module);
        hasSmooth |= style.shape == QrModuleShape.smooth;
        final path = buildModulePath(
          layout.cellRect(row, col),
          module,
          style,
          engine: engine,
        );
        (batches[style] ??= Path()).addPath(path, Offset.zero);
      }
    }

    if (hasSmooth) {
      QrModuleStyle? styleAt(int r, int c) =>
          r < 0 || c < 0 || r >= n || c >= n ? null : styles[r * n + c];

      for (var row = 0; row < n; row++) {
        for (var col = 0; col < n; col++) {
          if (matrix.isDark(row, col)) continue;
          final concave = engine.concaveCorners(matrix.neighborsOf(row, col));
          for (final corner in concave) {
            final (dr, dc) = switch (corner) {
              QrCorner.topLeft => (-1, -1),
              QrCorner.topRight => (-1, 1),
              QrCorner.bottomRight => (1, 1),
              QrCorner.bottomLeft => (1, -1),
            };
            // Both modules forming the junction must share a smooth style.
            final style = styleAt(row + dr, col);
            if (style == null ||
                style != styleAt(row, col + dc) ||
                !_supportsFillets(style)) {
              continue;
            }
            final cell = layout.cellRect(row, col);
            final radius =
                style.borderRadius ?? defaultModuleRadius(style.shape, cell);
            batches[style]!.addPath(
              buildConcaveFillet(cell, corner, _radiusAt(radius, corner).x),
              Offset.zero,
            );
          }
        }
      }
    }

    for (final MapEntry(key: style, value: path) in batches.entries) {
      canvas.drawPath(path, _paintFor(style, layout.matrixRect));
    }
  }

  static bool _supportsFillets(QrModuleStyle style) =>
      style.shape == QrModuleShape.smooth &&
      style.renderer == null &&
      style.scale == 1 &&
      style.spacing == 0 &&
      style.rotation == 0;

  static Radius _radiusAt(BorderRadius r, QrCorner corner) => switch (corner) {
    QrCorner.topLeft => r.topLeft,
    QrCorner.topRight => r.topRight,
    QrCorner.bottomRight => r.bottomRight,
    QrCorner.bottomLeft => r.bottomLeft,
  };

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
