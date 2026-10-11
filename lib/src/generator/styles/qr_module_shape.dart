/// Built-in outline used to draw a dark module.
enum QrModuleShape {
  /// Plain square filling the module rectangle.
  square,

  /// Square with rounded corners. Uses `QrModuleStyle.borderRadius` when
  /// given, otherwise 35% of the module size on every corner.
  rounded,

  /// Small circle: 80% of the module rectangle, leaving visible gaps.
  dots,

  /// Circle inscribed in the module rectangle.
  circle,

  /// Square rotated 45 degrees, touching the middle of each edge.
  diamond,

  /// Rectangle whose four corners come from `QrModuleStyle.borderRadius`,
  /// each set independently. Missing corners stay sharp.
  custom,
}
