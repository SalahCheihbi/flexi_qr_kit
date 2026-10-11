import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Placement of the QR symbol on a canvas.
@immutable
class QrRenderLayout {
  const QrRenderLayout._(this.bounds, this.matrixRect, this.moduleExtent);

  /// Fits a [matrixSize] symbol plus [quietZone] modules on each side into
  /// the largest square centered in [size].
  factory QrRenderLayout.compute(Size size, int matrixSize, int quietZone) {
    final dimension = size.shortestSide;
    final extent = dimension / (matrixSize + 2 * quietZone);
    final bounds = Rect.fromLTWH(
      (size.width - dimension) / 2,
      (size.height - dimension) / 2,
      dimension,
      dimension,
    );
    return QrRenderLayout._(bounds, bounds.deflate(quietZone * extent), extent);
  }

  /// Square covering the symbol and its quiet zone.
  final Rect bounds;

  /// Square covering the modules only.
  final Rect matrixRect;

  /// Side length of one module.
  final double moduleExtent;

  /// Grid cell of the module at [row], [col].
  Rect cellRect(int row, int col) => Rect.fromLTWH(
    matrixRect.left + col * moduleExtent,
    matrixRect.top + row * moduleExtent,
    moduleExtent,
    moduleExtent,
  );
}
