/// Built-in outline used to draw a dark module.
enum QrModuleShape {
  /// Square filling the module rectangle. Sharp, unless
  /// `QrModuleStyle.borderRadius` is set, in which case those corner radii
  /// are applied (same as [custom]).
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

  /// Neighbor-aware rounded squares that merge into continuous shapes:
  /// always uses smart corners. Defaults to a 50% radius, so isolated
  /// modules become circles and runs end in half circles.
  connected,

  /// Like [connected], and also fills the inner corner of L-shaped
  /// junctions with a concave fillet for a fluid look. Fillets are only
  /// drawn when modules fill their whole cell (scale 1, no spacing, no
  /// rotation).
  smooth,

  /// Rectangle whose four corners come from `QrModuleStyle.borderRadius`,
  /// each set independently. Missing corners stay sharp.
  custom,
}
