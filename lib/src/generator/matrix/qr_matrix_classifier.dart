import 'dart:typed_data';

import '../../core/models/qr_module_type.dart';

/// Alignment pattern center coordinates per version (ISO/IEC 18004 Annex E).
const List<List<int>> _alignmentPositions = [
  [],
  [6, 18],
  [6, 22],
  [6, 26],
  [6, 30],
  [6, 34],
  [6, 22, 38],
  [6, 24, 42],
  [6, 26, 46],
  [6, 28, 50],
  [6, 30, 54],
  [6, 32, 58],
  [6, 34, 62],
  [6, 26, 46, 66],
  [6, 26, 48, 70],
  [6, 26, 50, 74],
  [6, 30, 54, 78],
  [6, 30, 56, 82],
  [6, 30, 58, 86],
  [6, 34, 62, 90],
  [6, 28, 50, 72, 94],
  [6, 26, 50, 74, 98],
  [6, 30, 54, 78, 102],
  [6, 28, 54, 80, 106],
  [6, 32, 58, 84, 110],
  [6, 30, 58, 86, 114],
  [6, 34, 62, 90, 118],
  [6, 26, 50, 74, 98, 122],
  [6, 30, 54, 78, 102, 126],
  [6, 26, 52, 78, 104, 130],
  [6, 30, 56, 82, 108, 134],
  [6, 34, 60, 86, 112, 138],
  [6, 30, 58, 86, 114, 142],
  [6, 34, 62, 90, 118, 146],
  [6, 30, 54, 78, 102, 126, 150],
  [6, 24, 50, 76, 102, 128, 154],
  [6, 28, 54, 80, 106, 132, 158],
  [6, 32, 58, 84, 110, 136, 162],
  [6, 26, 54, 82, 110, 138, 166],
  [6, 30, 58, 86, 114, 142, 170],
];

/// Builds the module-type map of a QR symbol of [version], row-major.
///
/// Depends only on the version: function patterns sit at fixed positions.
Uint8List classifyModules(int version) {
  final n = 17 + 4 * version;
  final types = Uint8List(n * n)..fillRange(0, n * n, QrModuleType.data.index);

  void mark(int r, int c, QrModuleType t) => types[r * n + c] = t.index;

  // Timing first: alignment patterns overwrite it where they overlap.
  for (var i = 8; i < n - 8; i++) {
    mark(6, i, QrModuleType.timing);
    mark(i, 6, QrModuleType.timing);
  }

  final positions = _alignmentPositions[version - 1];
  for (final r in positions) {
    for (final c in positions) {
      final overlapsFinder =
          (r < 9 && c < 9) || (r < 9 && c > n - 10) || (r > n - 10 && c < 9);
      if (overlapsFinder) continue;
      for (var dr = -2; dr <= 2; dr++) {
        for (var dc = -2; dc <= 2; dc++) {
          mark(r + dr, c + dc, QrModuleType.alignment);
        }
      }
    }
  }

  // Finders with their separators (8x8 corners, clipped to the symbol).
  for (final (r0, c0) in [(0, 0), (0, n - 7), (n - 7, 0)]) {
    for (var dr = -1; dr <= 7; dr++) {
      for (var dc = -1; dc <= 7; dc++) {
        final r = r0 + dr;
        final c = c0 + dc;
        if (r < 0 || c < 0 || r >= n || c >= n) continue;
        final inFinder = dr >= 0 && dr < 7 && dc >= 0 && dc < 7;
        mark(r, c, inFinder ? QrModuleType.finder : QrModuleType.separator);
      }
    }
  }

  // Format information around the finders, skipping the timing lines.
  for (var i = 0; i <= 8; i++) {
    if (i == 6) continue;
    mark(8, i, QrModuleType.formatInfo);
    mark(i, 8, QrModuleType.formatInfo);
  }
  for (var i = 0; i < 8; i++) {
    mark(8, n - 1 - i, QrModuleType.formatInfo);
  }
  for (var i = 0; i < 7; i++) {
    mark(n - 1 - i, 8, QrModuleType.formatInfo);
  }
  mark(n - 8, 8, QrModuleType.darkModule);

  if (version >= 7) {
    for (var i = 0; i < 6; i++) {
      for (var j = 0; j < 3; j++) {
        mark(i, n - 11 + j, QrModuleType.versionInfo);
        mark(n - 11 + j, i, QrModuleType.versionInfo);
      }
    }
  }

  return types;
}
