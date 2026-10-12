import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../styles/qr_logo.dart';
import '../qr_render_layout.dart';

/// Placement of the logo container on the module grid.
@immutable
class QrLogoLayout {
  const QrLogoLayout._(
    this.firstModule,
    this.moduleCount,
    this.containerRect,
    this.imageRect,
  );

  /// Places [logo] in the center of a [matrixSize] symbol drawn with
  /// [layout].
  ///
  /// The container covers a square of whole modules with the same parity as
  /// the symbol, so it is exactly centered. It is capped at
  /// `matrixSize - 16` modules so the finders and their separators stay free.
  static QrLogoLayout? compute(
    QrRenderLayout layout,
    int matrixSize,
    QrLogo logo,
  ) {
    final maxCount = matrixSize - 16;
    if (maxCount < 1) return null;
    var count = (logo.sizeFactor * matrixSize).round();
    if ((matrixSize - count).isOdd) count++;
    count = math.max(1, math.min(count, maxCount));
    final first = (matrixSize - count) ~/ 2;

    final topLeft = layout.cellRect(first, first).topLeft;
    final side = count * layout.moduleExtent;
    final container = topLeft & Size.square(side);
    final pad = math.min(logo.padding, side / 2);
    return QrLogoLayout._(first, count, container, container.deflate(pad));
  }

  /// First row and column covered by the container.
  final int firstModule;

  /// Number of modules per side covered by the container.
  final int moduleCount;

  /// Container square in canvas coordinates.
  final Rect containerRect;

  /// Area available to the image, inside the padding.
  final Rect imageRect;

  /// Whether the module at [row], [col] lies under the container.
  bool coversModule(int row, int col) =>
      row >= firstModule &&
      col >= firstModule &&
      row < firstModule + moduleCount &&
      col < firstModule + moduleCount;
}
