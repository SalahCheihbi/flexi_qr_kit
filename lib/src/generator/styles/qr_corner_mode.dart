/// How module corner radii are decided.
enum QrCornerMode {
  /// Every corner uses `QrModuleStyle.borderRadius` exactly as given.
  manual,

  /// Corners touching a dark neighbor are made sharp so adjacent modules
  /// merge into one shape. Exposed corners keep their configured radius.
  /// Decisions come from `QrDesign.smartCornerEngine`.
  smart,
}
