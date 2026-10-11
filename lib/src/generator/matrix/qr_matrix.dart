import 'package:flutter/foundation.dart';

import '../../core/models/qr_error_correction_level.dart';
import '../../core/models/qr_module_context.dart';
import '../../core/models/qr_module_type.dart';
import '../../core/models/qr_neighbors.dart';
import 'qr_matrix_classifier.dart';

/// Immutable grid of QR modules with their functional classification.
///
/// The matrix is the encoder's output. Rendering only reads it, so styling
/// can never change what a scanner decodes.
@immutable
class QrMatrix {
  QrMatrix._(this.version, this.errorCorrectionLevel, this._dark)
    : size = 17 + 4 * version,
      _types = classifyModules(version);

  /// Creates a matrix from rows of dark (`true`) and light (`false`) modules.
  ///
  /// The input is copied. Its size must be a valid QR size
  /// (`17 + 4 * version`, version 1 to 40).
  factory QrMatrix.fromModules(
    List<List<bool>> rows, {
    QrErrorCorrectionLevel errorCorrectionLevel = QrErrorCorrectionLevel.medium,
  }) {
    final n = rows.length;
    if (n < 21 || n > 177 || (n - 17) % 4 != 0) {
      throw ArgumentError.value(n, 'rows', 'Not a valid QR symbol size');
    }
    final dark = Uint8List(n * n);
    for (var r = 0; r < n; r++) {
      final row = rows[r];
      if (row.length != n) {
        throw ArgumentError.value(row.length, 'rows[$r]', 'Matrix not square');
      }
      for (var c = 0; c < n; c++) {
        if (row[c]) dark[r * n + c] = 1;
      }
    }
    return QrMatrix._((n - 17) ~/ 4, errorCorrectionLevel, dark);
  }

  /// Number of modules per side, quiet zone excluded.
  final int size;

  /// QR version, 1 to 40.
  final int version;

  /// Error correction level the symbol was encoded with.
  final QrErrorCorrectionLevel errorCorrectionLevel;

  final Uint8List _dark;
  final Uint8List _types;

  /// Whether the module is dark. Coordinates outside the matrix are light.
  bool isDark(int row, int col) {
    if (row < 0 || col < 0 || row >= size || col >= size) return false;
    return _dark[row * size + col] == 1;
  }

  /// Functional role of the module at [row], [col].
  QrModuleType typeAt(int row, int col) {
    RangeError.checkValidIndex(row, null, 'row', size);
    RangeError.checkValidIndex(col, null, 'col', size);
    return QrModuleType.values[_types[row * size + col]];
  }

  /// State of the eight modules around [row], [col].
  QrNeighbors neighborsOf(int row, int col) => QrNeighbors(
    top: isDark(row - 1, col),
    bottom: isDark(row + 1, col),
    left: isDark(row, col - 1),
    right: isDark(row, col + 1),
    topLeft: isDark(row - 1, col - 1),
    topRight: isDark(row - 1, col + 1),
    bottomLeft: isDark(row + 1, col - 1),
    bottomRight: isDark(row + 1, col + 1),
  );

  /// Snapshot of the module at [row], [col].
  QrModuleContext moduleAt(int row, int col) => QrModuleContext(
    row: row,
    col: col,
    isDark: isDark(row, col),
    type: typeAt(row, col),
    neighbors: neighborsOf(row, col),
  );

  /// Every module, row by row.
  Iterable<QrModuleContext> get modules sync* {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        yield moduleAt(r, c);
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is QrMatrix &&
      other.version == version &&
      other.errorCorrectionLevel == errorCorrectionLevel &&
      listEquals(other._dark, _dark);

  @override
  int get hashCode =>
      Object.hash(version, errorCorrectionLevel, Object.hashAll(_dark));

  @override
  String toString() =>
      'QrMatrix(version: $version, size: $size, '
      'errorCorrectionLevel: ${errorCorrectionLevel.name})';
}
