import 'package:flutter/foundation.dart';

import 'qr_module_type.dart';
import 'qr_neighbors.dart';

/// Read-only description of a single module, handed to style callbacks and
/// custom renderers.
///
/// It is a snapshot: changing it cannot affect the encoded matrix.
@immutable
class QrModuleContext {
  /// Creates a module snapshot.
  const QrModuleContext({
    required this.row,
    required this.col,
    required this.isDark,
    required this.type,
    required this.neighbors,
  });

  /// Zero-based row inside the matrix (quiet zone excluded).
  final int row;

  /// Zero-based column inside the matrix (quiet zone excluded).
  final int col;

  /// Whether the module is dark.
  final bool isDark;

  /// Functional role of the module.
  final QrModuleType type;

  /// State of the eight surrounding modules.
  final QrNeighbors neighbors;

  /// Whether the module belongs to a structure scanners rely on.
  bool get isProtected => type.isProtected;

  @override
  bool operator ==(Object other) =>
      other is QrModuleContext &&
      other.row == row &&
      other.col == col &&
      other.isDark == isDark &&
      other.type == type &&
      other.neighbors == neighbors;

  @override
  int get hashCode => Object.hash(row, col, isDark, type, neighbors);

  @override
  String toString() =>
      'QrModuleContext(row: $row, col: $col, isDark: $isDark, type: $type)';
}
