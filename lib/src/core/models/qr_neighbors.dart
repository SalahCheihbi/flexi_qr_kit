import 'package:flutter/foundation.dart';

/// Dark/light state of the eight modules surrounding a module.
///
/// A value is `true` when the neighbor is dark. Neighbors outside the matrix
/// are reported as light.
@immutable
class QrNeighbors {
  /// Creates a neighbor snapshot. Unspecified neighbors are light.
  const QrNeighbors({
    this.top = false,
    this.bottom = false,
    this.left = false,
    this.right = false,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  /// Module directly above.
  final bool top;

  /// Module directly below.
  final bool bottom;

  /// Module directly to the left.
  final bool left;

  /// Module directly to the right.
  final bool right;

  /// Diagonal module above-left.
  final bool topLeft;

  /// Diagonal module above-right.
  final bool topRight;

  /// Diagonal module below-left.
  final bool bottomLeft;

  /// Diagonal module below-right.
  final bool bottomRight;

  /// Number of dark modules among [top], [bottom], [left] and [right].
  int get orthogonalCount =>
      (top ? 1 : 0) + (bottom ? 1 : 0) + (left ? 1 : 0) + (right ? 1 : 0);

  @override
  bool operator ==(Object other) =>
      other is QrNeighbors &&
      other.top == top &&
      other.bottom == bottom &&
      other.left == left &&
      other.right == right &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomLeft == bottomLeft &&
      other.bottomRight == bottomRight;

  @override
  int get hashCode => Object.hash(
    top,
    bottom,
    left,
    right,
    topLeft,
    topRight,
    bottomLeft,
    bottomRight,
  );

  @override
  String toString() =>
      'QrNeighbors(top: $top, bottom: $bottom, left: $left, right: $right, '
      'topLeft: $topLeft, topRight: $topRight, '
      'bottomLeft: $bottomLeft, bottomRight: $bottomRight)';
}
