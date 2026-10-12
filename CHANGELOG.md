## 0.1.0 - Unreleased

Initial development version.

### Added

- `FlexiQrGenerator` widget that encodes a payload and draws it as a styled QR code.
- `FlexiQrPainter` for embedding a QR code in a custom `CustomPaint` tree.
- `QrRenderPipeline`, a single drawing pipeline shared by preview and export.
- `QrDesign` with background color, quiet zone and per-module styling via `moduleBuilder`.
- `QrModuleStyle` with independent per-corner radii (`BorderRadius.only`), color, opacity,
  gradient, scale, spacing and rotation.
- Built-in module shapes: `square`, `rounded`, `dots`, `circle`, `diamond`, `connected`, `smooth`
  and `custom`.
- `QrSmartCornerEngine`: neighbor-aware corner rounding (exposed corners rounded, joints sharp,
  concave fillets for L-shaped junctions), replaceable via `QrDesign.smartCornerEngine`.
- `QrCornerMode.manual` / `QrCornerMode.smart` on `QrModuleStyle`.
- `QrModuleRenderer` contract for custom, path-based module shapes, plus reusable built-in
  renderers.
- `QrMatrix`: immutable matrix that classifies every module (finder, separator, timing,
  alignment, format info, version info, dark module, data) for versions 1 to 40.
- `QrModuleContext` and `QrNeighbors`: read-only module metadata including all eight neighbors.
- `QrEncoder` interface and `QrPackageEncoder` (UTF-8 text, raw bytes, error correction
  levels L/M/Q/H, optional fixed version).
- `QrDataTooLongException` and `QrEncodingException`.
- Independent finder styling: `QrDesign.finderStyle` plus `topLeftFinderStyle`,
  `topRightFinderStyle` and `bottomLeftFinderStyle` overrides. `QrFinderStyle` has `outer`,
  `inner` and optional `separator` parts (`QrFinderPartStyle`: color, gradient, independent
  corner radii), drawn by a path-based `QrFinderRenderer` (`DefaultQrFinderRenderer`).
- `QrFinderStyle.square()`, `.rounded()` and `.circle()` presets.
- `QrFinderStyle.outerThickness`, with `safeMode` (default) keeping the frame between 0.8 and
  1.2 modules so scanners still recognize the finder.
- `QrFinderPosition` with `origin()` and `at()` helpers.
- `QrBackgroundRenderer` contract via `QrDesign.backgroundRenderer`, and the built-in
  `FilledBackgroundRenderer` (color or gradient, corner radii, optional quiet zone).
- Center logo via `QrDesign.logo` / `QrLogo`: module-aligned container kept clear of the finders,
  configurable size, padding, background and independent corner radii; data modules under the
  logo are cleared while protected modules are kept. `QrLogoRenderer` contract for custom drawing.
- `FlexiQrGenerator` defaults to error correction level H when a logo is set.
- `QrValidator`: renders the code, decodes it with an independent decoder and compares it with
  the input, plus configuration checks (quiet zone, contrast, inverted colors, transparent
  background, logo coverage versus error correction, module pixel size, finder geometry, module
  scale and rotation). `decode: false` runs the configuration checks only.
- `QrValidationResult` with `QrValidationStatus` (`valid`, `warning`, `invalid`) and
  `QrValidationIssue`s (`QrIssueCode`, `QrIssueSeverity`, message).
- `QrDecoder` contract and `ZxingQrDecoder` (via `zxing2`, with UTF-8 recovery for non-ASCII
  text).
- `QrExporter.exportPng`: PNG export through the shared `QrRenderPipeline`, with `pixelRatio`,
  transparent background, logo loading and validation of the exported pixels.
  `QrValidationMode.strict` (default) throws `QrValidationException` for invalid codes,
  `QrValidationMode.advanced` always exports.
- `QrExporter.renderImage`, `renderQrImage`, `imageToRgba` and `resolveQrLogoImage` helpers.

### Fixed

- `QrModuleShape.square` (the default shape) now applies `borderRadius` when one is set, instead
  of ignoring it.
