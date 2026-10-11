## 0.1.0 - Unreleased

Initial development version.

### Added

- `FlexiQrGenerator` widget that encodes a payload and draws it as a styled QR code.
- `FlexiQrPainter` for embedding a QR code in a custom `CustomPaint` tree.
- `QrRenderPipeline`, a single drawing pipeline shared by preview and (upcoming) export.
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
