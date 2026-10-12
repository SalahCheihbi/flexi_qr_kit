import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../styles/qr_logo.dart';
import '../modules/module_geometry.dart';

/// Where and what to draw for the logo, in canvas coordinates.
@immutable
class QrLogoGeometry {
  /// Creates logo geometry.
  const QrLogoGeometry({
    required this.containerRect,
    required this.imageRect,
    required this.logo,
    required this.backgroundColor,
    this.image,
  });

  /// The module-aligned container square.
  final Rect containerRect;

  /// [containerRect] reduced by the logo padding.
  final Rect imageRect;

  /// Logo configuration.
  final QrLogo logo;

  /// Resolved container fill.
  final Color backgroundColor;

  /// Decoded image, or `null` while it is still loading.
  final ui.Image? image;
}

/// Contract for drawing the logo on top of the modules.
abstract class QrLogoRenderer {
  /// Const constructor for subclasses.
  const QrLogoRenderer();

  /// Draws the logo described by [geometry].
  void paint(Canvas canvas, QrLogoGeometry geometry);
}

/// Fills the container with its background and paints the image inside it,
/// clipped to the container's corner radii.
class DefaultQrLogoRenderer extends QrLogoRenderer {
  /// Creates the default logo renderer.
  const DefaultQrLogoRenderer();

  @override
  void paint(Canvas canvas, QrLogoGeometry geometry) {
    final container = resolveModuleRRect(
      geometry.containerRect,
      geometry.logo.borderRadius,
    );
    if (geometry.backgroundColor.a > 0) {
      canvas.drawRRect(container, Paint()..color = geometry.backgroundColor);
    }
    final image = geometry.image;
    if (image == null || geometry.imageRect.isEmpty) return;
    // Fitted manually (not via paintImage) so the pipeline also works
    // without a Flutter binding, e.g. for headless export.
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(
      geometry.logo.fit,
      imageSize,
      geometry.imageRect.size,
    );
    final src = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & imageSize,
    );
    final dst = Alignment.center.inscribe(
      fitted.destination,
      geometry.imageRect,
    );
    canvas
      ..save()
      ..clipRRect(container)
      ..drawImageRect(
        image,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..isAntiAlias = true,
      )
      ..restore();
  }
}
