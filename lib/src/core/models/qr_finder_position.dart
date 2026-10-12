/// One of the three 7x7 finder patterns.
enum QrFinderPosition {
  /// Finder in the top-left corner.
  topLeft,

  /// Finder in the top-right corner.
  topRight,

  /// Finder in the bottom-left corner.
  bottomLeft;

  /// Row and column of the finder's top-left module in a symbol of [size].
  (int, int) origin(int size) => switch (this) {
    QrFinderPosition.topLeft => (0, 0),
    QrFinderPosition.topRight => (0, size - 7),
    QrFinderPosition.bottomLeft => (size - 7, 0),
  };

  /// Finder containing the module at [row], [col] in a symbol of [size], or
  /// `null` when the module is not part of a finder.
  static QrFinderPosition? at(int row, int col, int size) {
    final top = row < 7;
    final left = col < 7;
    if (top && left) return QrFinderPosition.topLeft;
    if (top && col >= size - 7) return QrFinderPosition.topRight;
    if (left && row >= size - 7) return QrFinderPosition.bottomLeft;
    return null;
  }
}
