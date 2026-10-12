import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../renderers/logo/qr_logo_renderer.dart';

/// Image drawn in the center of the code.
///
/// The logo sits in a square container snapped to whole modules and kept
/// away from the three finder patterns. Data modules under the container are
/// removed ([clearModules]); protected modules such as alignment patterns are
/// always kept.
///
/// A logo hides data, so the code relies on error correction to scan.
/// `FlexiQrGenerator` uses level H by default when a logo is set, but high
/// error correction does not guarantee readability: keep logos small and
/// test on real devices.
@immutable
class QrLogo {
  /// Creates a logo configuration.
  const QrLogo({
    required this.image,
    this.sizeFactor = 0.2,
    this.padding = 4,
    this.backgroundColor,
    this.borderRadius = BorderRadius.zero,
    this.clearModules = true,
    this.fit = BoxFit.contain,
    this.renderer,
  }) : assert(
         sizeFactor > 0 && sizeFactor <= 0.4,
         'sizeFactor must be in (0, 0.4]',
       ),
       assert(padding >= 0, 'padding must be >= 0');

  /// Logo image. Transparent images are supported.
  final ImageProvider image;

  /// Container side as a fraction of the module area (quiet zone excluded),
  /// before snapping to whole modules. Recommended: 0.3 or less.
  final double sizeFactor;

  /// Space between the container edge and the image, in logical pixels.
  final double padding;

  /// Container fill. Defaults to `QrDesign.backgroundColor`. Use a fully
  /// transparent color for no container.
  final Color? backgroundColor;

  /// Container corner radii, each independent. `BorderRadius.circular(999)`
  /// gives a circle.
  final BorderRadius borderRadius;

  /// Whether data modules under the container are removed.
  final bool clearModules;

  /// How the image is fitted inside the padded container.
  final BoxFit fit;

  /// Custom renderer replacing the default container + image drawing.
  final QrLogoRenderer? renderer;

  @override
  bool operator ==(Object other) =>
      other is QrLogo &&
      other.image == image &&
      other.sizeFactor == sizeFactor &&
      other.padding == padding &&
      other.backgroundColor == backgroundColor &&
      other.borderRadius == borderRadius &&
      other.clearModules == clearModules &&
      other.fit == fit &&
      other.renderer == renderer;

  @override
  int get hashCode => Object.hash(
    image,
    sizeFactor,
    padding,
    backgroundColor,
    borderRadius,
    clearModules,
    fit,
    renderer,
  );
}
