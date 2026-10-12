import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../core/models/qr_corner.dart';
import '../../core/models/qr_finder_position.dart';
import '../../core/models/qr_module_type.dart';
import '../matrix/qr_matrix.dart';
import '../styles/qr_design.dart';
import '../styles/qr_finder_style.dart';
import '../styles/qr_module_shape.dart';
import '../styles/qr_module_style.dart';
import 'finders/qr_finder_renderer.dart';
import 'logo/qr_logo_layout.dart';
import 'logo/qr_logo_renderer.dart';
import 'modules/module_geometry.dart';
import 'qr_render_layout.dart';

/// Draws a [QrMatrix] with a [QrDesign] onto any [Canvas].
///
/// The on-screen widget and image export share this pipeline, so both
/// produce identical output.
class QrRenderPipeline {
  /// Creates a pipeline for [matrix] and [design].
  ///
  /// [logoImage] is the decoded `QrDesign.logo` image. When it is null the
  /// logo container is still laid out and filled, so the code does not shift
  /// once the image loads.
  const QrRenderPipeline({
    required this.matrix,
    required this.design,
    this.logoImage,
  });

  /// Matrix to draw.
  final QrMatrix matrix;

  /// Visual configuration.
  final QrDesign design;

  /// Decoded logo image, if any.
  final ui.Image? logoImage;

  /// Paints the code centered in [size]: background, modules, finders, then
  /// the logo.
  void paint(Canvas canvas, Size size) {
    final layout = QrRenderLayout.compute(size, matrix.size, design.quietZone);

    final background = design.backgroundRenderer;
    if (background != null) {
      background.paint(canvas, layout);
    } else if (design.backgroundColor.a > 0) {
      canvas.drawRect(layout.bounds, Paint()..color = design.backgroundColor);
    }

    final finderStyles = {
      for (final position in QrFinderPosition.values)
        position: design.effectiveFinderStyleFor(position),
    };

    final logo = design.logo;
    final logoLayout = logo == null
        ? null
        : QrLogoLayout.compute(layout, matrix.size, logo);
    final clearUnderLogo = logoLayout != null && logo!.clearModules;

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
        // Only data modules are cleared: protected structures stay intact.
        if (clearUnderLogo &&
            logoLayout.coversModule(row, col) &&
            matrix.typeAt(row, col) == QrModuleType.data) {
          continue;
        }
        final module = matrix.moduleAt(row, col);
        // Styled finders are drawn as whole shapes below.
        if (module.type == QrModuleType.finder &&
            finderStyles[QrFinderPosition.at(row, col, n)] != null) {
          continue;
        }
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

    for (final MapEntry(key: position, value: style) in finderStyles.entries) {
      if (style != null) _paintFinder(canvas, layout, position, style);
    }

    if (logo != null && logoLayout != null) {
      (logo.renderer ?? const DefaultQrLogoRenderer()).paint(
        canvas,
        QrLogoGeometry(
          containerRect: logoLayout.containerRect,
          imageRect: logoLayout.imageRect,
          logo: logo,
          backgroundColor: logo.backgroundColor ?? design.backgroundColor,
          image: logoImage,
        ),
      );
    }
  }

  void _paintFinder(
    Canvas canvas,
    QrRenderLayout layout,
    QrFinderPosition position,
    QrFinderStyle style,
  ) {
    final (row, col) = position.origin(matrix.size);
    final extent = layout.moduleExtent;
    final rect = layout.cellRect(row, col).topLeft & Size.square(7 * extent);
    final geometry = QrFinderGeometry(
      position: position,
      rect: rect,
      separatorRect: rect.inflate(extent).intersect(layout.matrixRect),
      moduleExtent: extent,
      style: style,
    );
    final renderer = style.renderer;
    final area = layout.matrixRect;
    final separator = style.separator;
    if (separator != null) {
      canvas.drawPath(
        renderer.buildSeparator(geometry),
        _fill(separator.color, separator.gradient, 1, area),
      );
    }
    for (final (path, part) in [
      (renderer.buildOuter(geometry), style.outer),
      (renderer.buildInner(geometry), style.inner),
    ]) {
      canvas.drawPath(path, _fill(part.color, part.gradient, 1, area));
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

  static Paint _paintFor(QrModuleStyle style, Rect area) =>
      _fill(style.color, style.gradient, style.opacity, area);

  static Paint _fill(
    Color color,
    Gradient? gradient,
    double opacity,
    Rect area,
  ) {
    final paint = Paint()..isAntiAlias = true;
    if (gradient != null) {
      // With a shader, only the paint's alpha is used.
      paint
        ..shader = gradient.createShader(area)
        ..color = Color.fromRGBO(0, 0, 0, opacity);
    } else {
      paint.color = color.withValues(alpha: color.a * opacity);
    }
    return paint;
  }
}
