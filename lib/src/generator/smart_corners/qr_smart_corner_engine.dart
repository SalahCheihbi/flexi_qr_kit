import 'package:flutter/painting.dart';

import '../../core/models/qr_corner.dart';
import '../../core/models/qr_neighbors.dart';

/// Decides which module corners are rounded based on neighboring modules.
///
/// Rules:
/// * A corner of a dark module is **exposed**, and may be rounded, when both
///   orthogonal neighbors sharing that corner are light. Corners where the
///   module touches another stay sharp, so connected modules leave no gap.
/// * A diagonal neighbor alone does not prevent rounding. Two modules that
///   meet only at a point are both rounded there instead of pinching.
/// * A corner of a light module is **concave** when both orthogonal
///   neighbors and the diagonal between them are dark: the inside of an
///   L-shaped junction, which smooth styles fill with a fillet.
///
/// Subclass and override any method to change the rules, then pass the
/// instance to `QrDesign.smartCornerEngine`.
class QrSmartCornerEngine {
  /// Creates the default engine.
  const QrSmartCornerEngine();

  /// Corners of a dark module that may be rounded.
  Set<QrCorner> exposedCorners(QrNeighbors neighbors) => {
    if (!neighbors.top && !neighbors.left) QrCorner.topLeft,
    if (!neighbors.top && !neighbors.right) QrCorner.topRight,
    if (!neighbors.bottom && !neighbors.right) QrCorner.bottomRight,
    if (!neighbors.bottom && !neighbors.left) QrCorner.bottomLeft,
  };

  /// Corners of a light module that sit inside an L-shaped dark junction.
  Set<QrCorner> concaveCorners(QrNeighbors neighbors) => {
    if (neighbors.top && neighbors.left && neighbors.topLeft) QrCorner.topLeft,
    if (neighbors.top && neighbors.right && neighbors.topRight)
      QrCorner.topRight,
    if (neighbors.bottom && neighbors.right && neighbors.bottomRight)
      QrCorner.bottomRight,
    if (neighbors.bottom && neighbors.left && neighbors.bottomLeft)
      QrCorner.bottomLeft,
  };

  /// Applies [exposedCorners] to [base]: exposed corners keep their base
  /// radius, all others become sharp.
  BorderRadius resolve(QrNeighbors neighbors, BorderRadius base) {
    final exposed = exposedCorners(neighbors);
    Radius pick(QrCorner c, Radius r) => exposed.contains(c) ? r : Radius.zero;
    return BorderRadius.only(
      topLeft: pick(QrCorner.topLeft, base.topLeft),
      topRight: pick(QrCorner.topRight, base.topRight),
      bottomRight: pick(QrCorner.bottomRight, base.bottomRight),
      bottomLeft: pick(QrCorner.bottomLeft, base.bottomLeft),
    );
  }
}
