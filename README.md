# flexi_qr_kit

A fully customizable QR code generator for Flutter, with precise control over
every corner of every module.

Most QR styling libraries apply one radius to every corner. `flexi_qr_kit` lets
you set each of the four corners of a module independently: for example, three
rounded corners and one sharp corner. It never changes the encoded data to get
a visual effect.

> **Status:** early development (`0.1.0`, unreleased). The generator, module
> rendering (smart corners, finder styling, backgrounds, center logo),
> readability validation, PNG export and the scanner are ready. See the
> [example app](example/) for every feature in action.

## Features

- Independent corner radii per module (`BorderRadius.only`).
- Built-in shapes: square, rounded, dots, circle, diamond, connected, smooth
  and custom.
- Smart corner engine: rounds only exposed corners so neighboring modules
  merge without gaps, with optional concave fillets.
- Color, opacity, gradients, scale, spacing and rotation.
- Independent styling of each finder pattern: frame, eye and separator, each
  with its own color, gradient and corner radii.
- Custom backgrounds: rounded, gradient or fully custom.
- Center logo with a configurable container that is kept clear of the finders.
- Readability validation: renders the code, decodes it with an independent
  decoder (ZXing) and checks quiet zone, contrast, logo coverage and module size.
- PNG export through the same pipeline as the preview, validated before export.
- Camera scanner with a customizable overlay: scan window size and position,
  dim color, and a frame with independent corner radii and per-corner brackets.
- Per-module styling through a callback, with full module metadata: position,
  type, dark/light state, the eight neighbors and protection status.
- Pluggable `QrModuleRenderer` for your own path-based shapes.
- Standards-compliant encoding with error correction levels L, M, Q and H, and
  UTF-8 support for any Unicode text, including Arabic and emoji.
- Encoding and rendering are separate: the matrix is immutable and read-only.

## Screenshots

Rendered by the package from the [example app](example/) gallery. Codes marked
⚠️ or ❌ fail validation on purpose, to show what `QrValidator` catches.

### Basics

<table>
  <tr>
    <td align="center"><img src="doc/screenshots/classic.png" width="160" alt="Classic"><br><sub>Classic</sub></td>
    <td align="center"><img src="doc/screenshots/mixed_corners.png" width="160" alt="Mixed corners"><br><sub>Mixed corners</sub></td>
    <td align="center"><img src="doc/screenshots/unicode_payload.png" width="160" alt="Unicode payload"><br><sub>Unicode payload</sub></td>
  </tr>
</table>

### Shapes

<table>
  <tr>
    <td align="center"><img src="doc/screenshots/rounded.png" width="160" alt="Rounded"><br><sub>Rounded</sub></td>
    <td align="center"><img src="doc/screenshots/dots.png" width="160" alt="Dots"><br><sub>Dots</sub></td>
    <td align="center"><img src="doc/screenshots/circle.png" width="160" alt="Circle"><br><sub>Circle</sub></td>
    <td align="center"><img src="doc/screenshots/diamond.png" width="160" alt="Diamond"><br><sub>Diamond</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="doc/screenshots/custom_renderer.png" width="160" alt="Custom renderer"><br><sub>Custom renderer</sub></td>
  </tr>
</table>

### Smart corners

<table>
  <tr>
    <td align="center"><img src="doc/screenshots/connected.png" width="160" alt="Connected"><br><sub>Connected</sub></td>
    <td align="center"><img src="doc/screenshots/smooth.png" width="160" alt="Smooth"><br><sub>Smooth</sub></td>
    <td align="center"><img src="doc/screenshots/smart_custom_radius.png" width="160" alt="Smart custom radius"><br><sub>Smart custom radius</sub></td>
    <td align="center"><img src="doc/screenshots/custom_corner_engine.png" width="160" alt="Custom corner engine"><br><sub>Custom corner engine</sub></td>
  </tr>
</table>

### Color & effects

<table>
  <tr>
    <td align="center"><img src="doc/screenshots/gradient.png" width="160" alt="Gradient"><br><sub>Gradient</sub></td>
    <td align="center"><img src="doc/screenshots/scale_and_spacing.png" width="160" alt="Scale and spacing"><br><sub>Scale and spacing</sub></td>
    <td align="center"><img src="doc/screenshots/opacity.png" width="160" alt="Opacity"><br><sub>Opacity</sub></td>
    <td align="center"><img src="doc/screenshots/rotated_modules.png" width="160" alt="Rotated modules ⚠️"><br><sub>Rotated modules ⚠️</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="doc/screenshots/style_per_module.png" width="160" alt="Style per module"><br><sub>Style per module</sub></td>
  </tr>
</table>

### Finders

<table>
  <tr>
    <td align="center"><img src="doc/screenshots/rounded_finders.png" width="160" alt="Rounded finders"><br><sub>Rounded finders</sub></td>
    <td align="center"><img src="doc/screenshots/circle_finders.png" width="160" alt="Circle finders"><br><sub>Circle finders</sub></td>
    <td align="center"><img src="doc/screenshots/finder_per_position.png" width="160" alt="Finder per position"><br><sub>Finder per position</sub></td>
    <td align="center"><img src="doc/screenshots/finder_gradient_and_separator.png" width="160" alt="Finder gradient and separator"><br><sub>Finder gradient and separator</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="doc/screenshots/finders_as_modules.png" width="160" alt="Finders as modules"><br><sub>Finders as modules</sub></td>
  </tr>
</table>

### Background & logo

<table>
  <tr>
    <td align="center"><img src="doc/screenshots/gradient_background.png" width="160" alt="Gradient background"><br><sub>Gradient background</sub></td>
    <td align="center"><img src="doc/screenshots/center_logo.png" width="160" alt="Center logo"><br><sub>Center logo</sub></td>
    <td align="center"><img src="doc/screenshots/logo_badge.png" width="160" alt="Logo badge"><br><sub>Logo badge</sub></td>
    <td align="center"><img src="doc/screenshots/asymmetric_finder_with_logo.png" width="160" alt="Asymmetric finder with logo"><br><sub>Asymmetric finder with logo</sub></td>
  </tr>
</table>

### Validation

<table>
  <tr>
    <td align="center"><img src="doc/screenshots/low_contrast.png" width="160" alt="Low contrast ❌"><br><sub>Low contrast ❌</sub></td>
    <td align="center"><img src="doc/screenshots/no_quiet_zone.png" width="160" alt="No quiet zone ⚠️"><br><sub>No quiet zone ⚠️</sub></td>
  </tr>
</table>

### Scanner overlays

<table>
  <tr>
    <td align="center"><img src="doc/screenshots/overlay_brackets.png" width="160" alt="Brackets"><br><sub>Brackets</sub></td>
    <td align="center"><img src="doc/screenshots/overlay_asymmetric.png" width="160" alt="Asymmetric radii"><br><sub>Asymmetric radii</sub></td>
    <td align="center"><img src="doc/screenshots/overlay_twoCorners.png" width="160" alt="Two corners"><br><sub>Two corners</sub></td>
    <td align="center"><img src="doc/screenshots/overlay_fullBorder.png" width="160" alt="Full border"><br><sub>Full border</sub></td>
  </tr>
</table>

## Installation

```yaml
dependencies:
  flexi_qr_kit: ^0.1.0
```

Requires Flutter 3.35 or later and Dart 3.9 or later.

## Usage

### Basic QR code

```dart
import 'package:flexi_qr_kit/flexi_qr_kit.dart';

FlexiQrGenerator(
  data: 'https://example.com',
  size: 240,
)
```

### Mixed rounded and sharp corners

Each corner is independent. Corners left out stay sharp.

```dart
FlexiQrGenerator(
  data: 'https://example.com',
  design: QrDesign(
    moduleStyle: QrModuleStyle(
      shape: QrModuleShape.custom,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
        bottomRight: Radius.circular(8),
        bottomLeft: Radius.zero,
      ),
    ),
  ),
)
```

Radii are in logical pixels. A radius larger than half the drawn module is
capped there, so `Radius.circular(999)` always gives the roundest corner.

### Built-in shapes and effects

```dart
QrDesign(
  moduleStyle: QrModuleStyle(
    shape: QrModuleShape.dots,
    gradient: LinearGradient(
      colors: [Color(0xFF6A1B9A), Color(0xFF0277BD)],
    ),
  ),
)
```

| Property       | Description                                              |
| -------------- | -------------------------------------------------------- |
| `shape`        | `square`, `rounded`, `dots`, `circle`, `diamond`, `connected`, `smooth`, `custom` |
| `borderRadius` | Independent corner radii for `custom` and `rounded`      |
| `color`        | Fill color                                               |
| `gradient`     | Gradient spread across the whole code                    |
| `opacity`      | Opacity multiplier, 0 to 1                               |
| `scale`        | Fraction of the cell the module fills, centered (0 to 1] |
| `spacing`      | Gap in logical pixels removed from each module           |
| `rotation`     | Rotation of each module around its center, in radians    |
| `renderer`     | Custom `QrModuleRenderer` that replaces `shape`          |
| `cornerMode`   | `manual` (radii as given) or `smart` (neighbor-aware)    |

### Smart corners

In smart mode, a corner is rounded only when both neighbors sharing it are
light. Corners where modules touch stay sharp, so connected modules merge into
one shape with no gaps.

```dart
// Continuous shapes: isolated modules become circles, runs get round ends.
QrDesign(moduleStyle: QrModuleStyle(shape: QrModuleShape.connected))

// Same, plus concave fillets inside L-shaped junctions for a fluid look.
QrDesign(moduleStyle: QrModuleStyle(shape: QrModuleShape.smooth))

// Your own per-corner radii, applied only where the corner is exposed.
QrDesign(
  moduleStyle: QrModuleStyle(
    shape: QrModuleShape.custom,
    cornerMode: QrCornerMode.smart,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(6),
      bottomRight: Radius.circular(6),
    ),
  ),
)
```

Modules touching only diagonally are both rounded at that point rather than
pinched together. Fillets are added only where both orthogonal neighbors and
the diagonal between them are dark.

To override smart decisions for specific modules, return a `manual` style
from `moduleBuilder`. To change the rules for the whole code, subclass the
engine:

```dart
class RoundTopOnly extends QrSmartCornerEngine {
  const RoundTopOnly();

  @override
  Set<QrCorner> exposedCorners(QrNeighbors neighbors) => super
      .exposedCorners(neighbors)
      .intersection({QrCorner.topLeft, QrCorner.topRight});
}

QrDesign(
  moduleStyle: QrModuleStyle(shape: QrModuleShape.connected),
  smartCornerEngine: RoundTopOnly(),
)
```

Custom renderers receive the resolved radii in `QrModuleGeometry.borderRadius`.

### Styling individual modules

`moduleBuilder` is called for every dark module. Return a style, or `null` to
keep the default. Leaving protected modules (finders, timing, alignment and
format information) unchanged helps scanners read the code.

```dart
FlexiQrGenerator(
  data: 'https://example.com',
  design: QrDesign(
    moduleBuilder: (module) {
      if (module.isProtected) return null;
      return QrModuleStyle(
        shape: QrModuleShape.custom,
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
          bottomLeft: Radius.zero,
          bottomRight: Radius.circular(6),
        ),
      );
    },
  ),
)
```

`QrModuleContext` provides `row`, `col`, `type`, `isDark`, `isProtected` and
`neighbors` (`top`, `bottom`, `left`, `right` and the four diagonals).

### Custom renderers

```dart
class StarRenderer extends QrModuleRenderer {
  const StarRenderer();

  @override
  Path buildPath(QrModuleGeometry geometry) {
    final r = geometry.rect;
    return Path()
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.right, r.center.dy)
      ..lineTo(r.center.dx, r.bottom)
      ..lineTo(r.left, r.center.dy)
      ..close();
  }
}

QrDesign(moduleStyle: QrModuleStyle(renderer: StarRenderer()))
```

A renderer only describes shape. The pipeline applies color, opacity, gradient
and rotation, and merges modules that share a style into a single fill so
touching modules have no visible seams.

### Finder patterns

Finders are drawn as whole shapes instead of 49 separate modules. Each one has
three parts: the 7x7 `outer` frame, the 3x3 `inner` eye and an optional light
`separator` band around it. Every part has its own color, gradient and four
independent corner radii.

```dart
QrDesign(
  // Applies to all three finders...
  finderStyle: QrFinderStyle(
    outer: QrFinderPartStyle(borderRadius: BorderRadius.circular(12)),
    inner: QrFinderPartStyle(
      color: Color(0xFF3F51B5),
      borderRadius: BorderRadius.circular(999),
    ),
  ),
  // ...unless a position has its own style.
  topLeftFinderStyle: QrFinderStyle(
    outer: QrFinderPartStyle(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
  ),
)
```

Without a finder style, finders keep the module style. The frame's inner hole
follows the outer corners, so rounded frames keep an even thickness. Keep the
separator light: scanners need contrast around each finder.

Presets cover the common looks:

```dart
QrDesign(
  finderStyle: QrFinderStyle.rounded(
    outerRadius: Radius.circular(12),
    innerRadius: Radius.circular(6),
  ),
  topRightFinderStyle: QrFinderStyle.circle(innerColor: Color(0xFFE91E63)),
  bottomLeftFinderStyle: QrFinderStyle.square(),
)
```

`outerThickness` sets the frame thickness in modules (the standard is 1). The
3x3 eye never moves, so a thicker frame narrows the gap around it. Scanners
locate finders by their 1:1:3:1:1 proportions, so `safeMode` (on by default)
keeps the thickness between 0.8 and 1.2 modules. Set `safeMode: false` to go
beyond that range, and check the result on real devices:

```dart
QrFinderStyle(outerThickness: 1.2) // applied as-is
QrFinderStyle(outerThickness: 1.6) // safe mode: drawn at 1.2
QrFinderStyle(outerThickness: 1.6, safeMode: false) // drawn at 1.6
```

To change the geometry, extend `DefaultQrFinderRenderer` and override
`buildOuter`, `buildInner` or `buildSeparator`:

```dart
class DiamondEyeRenderer extends DefaultQrFinderRenderer {
  const DiamondEyeRenderer();

  @override
  Path buildInner(QrFinderGeometry geometry) {
    final r = geometry.innerRect;
    return Path()
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.right, r.center.dy)
      ..lineTo(r.center.dx, r.bottom)
      ..lineTo(r.left, r.center.dy)
      ..close();
  }
}

QrDesign(finderStyle: QrFinderStyle(renderer: DiamondEyeRenderer()))
```

### Background

```dart
QrDesign(
  backgroundRenderer: FilledBackgroundRenderer(
    gradient: LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFFFFF)]),
    borderRadius: BorderRadius.circular(24),
  ),
)
```

A `backgroundRenderer` replaces `backgroundColor`. Set `coverQuietZone: false`
to fill only behind the modules. Implement `QrBackgroundRenderer` to paint
anything else; it receives the `QrRenderLayout` and is drawn first.

### Center logo

```dart
FlexiQrGenerator(
  data: 'https://example.com',
  design: QrDesign(
    logo: QrLogo(
      image: AssetImage('assets/logo.png'),
      sizeFactor: 0.25, // fraction of the code width, max 0.4
      padding: 6,
      borderRadius: BorderRadius.circular(999), // circular container
    ),
  ),
)
```

The logo container snaps to whole modules, stays centered and never reaches
the three finder patterns. Data modules underneath are removed, but
alignment, timing and other protected modules are always kept. The container
uses `QrDesign.backgroundColor` unless you set `backgroundColor`, and its four
corner radii are independent. With a logo, the generator defaults to error
correction level H.

High error correction does not guarantee that a code with a logo will scan.
Keep logos at about 30% of the width or less, and test on real devices.

Implement `QrLogoRenderer` to draw the logo yourself:

```dart
class BadgeLogoRenderer extends QrLogoRenderer {
  const BadgeLogoRenderer();

  @override
  void paint(Canvas canvas, QrLogoGeometry geometry) {
    canvas.drawOval(
      geometry.containerRect,
      Paint()..color = const Color(0xFF3F51B5),
    );
  }
}
```

### Encoding options

```dart
FlexiQrGenerator(
  data: 'مرحبا بالعالم',
  errorCorrectionLevel: QrErrorCorrectionLevel.high,
  version: 5, // optional fixed version, 1 to 40
  errorBuilder: (context, error) => const Text('Data too long'),
)
```

To work with the matrix directly:

```dart
final matrix = const QrPackageEncoder().encode('hello');
matrix.size;              // modules per side
matrix.typeAt(0, 0);      // QrModuleType.finder
matrix.moduleAt(10, 12);  // QrModuleContext snapshot
```

## Validation

Heavy styling can make a code hard to scan. `QrValidator` renders the code,
decodes the pixels with an independent decoder (a Dart port of ZXing) and
compares the result with the input. It also checks the design itself: quiet
zone, contrast, inverted colors, logo coverage versus error correction,
module pixel size, finder geometry, small scale and rotation.

```dart
final result = await const QrValidator().validate(
  'https://example.com',
  design: design,
  size: 300,
);

switch (result.status) {
  case QrValidationStatus.valid:   // decoded, no risk found
  case QrValidationStatus.warning: // decoded, but see result.warnings
  case QrValidationStatus.invalid: // see result.errors
}
for (final issue in result.issues) {
  print('${issue.code}: ${issue.message}');
}
```

Pass `decode: false` for a fast configuration-only check, for example while a
slider is being dragged. Implement `QrDecoder` to validate with another
decoder.

A valid result is strong evidence, not a guarantee: one decoder reading a
perfect digital image is easier than a phone camera reading a print. Always
test important codes on real Android and iOS devices.

## Export

```dart
final export = await const QrExporter().exportPng(
  'https://example.com',
  design: design,
  size: 300,      // logical pixels, like the widget
  pixelRatio: 4,  // 1200 x 1200 PNG for print
);
await File('qr.png').writeAsBytes(export.bytes);
export.validation; // validation of the exported pixels
```

Export uses the same `QrRenderPipeline` as `FlexiQrGenerator`, so the PNG
matches the preview. `pixelRatio` scales radii and spacing like a high-DPI
screen. Set `transparentBackground: true` to drop `backgroundColor`. A logo is
loaded from `QrLogo.image`, or pass an already decoded `logoImage`.

Every export decodes its own pixels. In `QrValidationMode.strict` (the
default), an invalid code throws `QrValidationException` instead of being
exported; its `result` lists the issues. `QrValidationMode.advanced` always
exports and reports the issues in `export.validation`.

Use `QrExporter.renderImage` to get a `ui.Image` instead of PNG bytes.

## Scanner

```dart
FlexiQrScanner(
  onDetect: (result) => print(result.value),
  overlayStyle: const QrScannerOverlayStyle(
    windowSize: Size(260, 260),
    frame: QrScannerFrameStyle(
      color: Colors.greenAccent,
      strokeWidth: 6,
      cornerLength: 40,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
    ),
  ),
)
```

The scanner reads QR codes only, and by default only inside the scan window.
Each value is reported once, then ignored until it has been out of view for
`duplicateCooldown` (2 seconds; `Duration.zero` reports every frame).
`result.rawBytes` holds the payload bytes when the platform reports them.

The overlay dims the preview outside the window and frames it. Each window
corner has its own radius, and `QrScannerFrameStyle.corners` picks which
corner brackets are drawn:

```dart
const QrScannerFrameStyle(
  corners: {QrCorner.topLeft, QrCorner.bottomRight},
  borderRadius: BorderRadius.zero,
);
const QrScannerFrameStyle(fullBorder: true); // outline the whole window
```

Set `overlayStyle: null` for no overlay, or put `QrScannerOverlay` over your
own camera preview. Pass a `MobileScannerController` to control the torch,
switch cameras or pause scanning; the scanner disposes only controllers it
created.

```dart
final controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);

FlexiQrScanner(controller: controller, onDetect: handleResult);
controller.toggleTorch();
```

The scanner is built on
[`mobile_scanner`](https://pub.dev/packages/mobile_scanner). Add the camera
permission your platforms require, as its documentation describes: for
example `NSCameraUsageDescription` in `ios/Runner/Info.plist`. When the camera
cannot start, for example without permission, `errorBuilder` is shown.

## Example

The [example app](example/) has a gallery of every feature, a live designer
with validation and PNG export, and a scanner with overlay presets.

## Roadmap

- Continuous integration and the first pub.dev release.

## License

MIT. See [LICENSE](LICENSE).
