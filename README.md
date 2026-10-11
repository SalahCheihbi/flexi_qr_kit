# flexi_qr_kit

A fully customizable QR code generator for Flutter, with precise control over
every corner of every module.

Most QR styling libraries apply one radius to every corner. `flexi_qr_kit` lets
you set each of the four corners of a module independently: for example, three
rounded corners and one sharp corner. It never changes the encoded data to get
a visual effect.

> **Status:** early development (`0.1.0`, unreleased). The generator and module
> rendering, including smart corners, are ready. Finder styling, logos,
> validation, export and the scanner are on the [roadmap](#roadmap).

## Features

- Independent corner radii per module (`BorderRadius.only`).
- Built-in shapes: square, rounded, dots, circle, diamond, connected, smooth
  and custom.
- Smart corner engine: rounds only exposed corners so neighboring modules
  merge without gaps, with optional concave fillets.
- Color, opacity, gradients, scale, spacing and rotation.
- Per-module styling through a callback, with full module metadata: position,
  type, dark/light state, the eight neighbors and protection status.
- Pluggable `QrModuleRenderer` for your own path-based shapes.
- Standards-compliant encoding with error correction levels L, M, Q and H, and
  UTF-8 support for any Unicode text, including Arabic and emoji.
- Encoding and rendering are separate: the matrix is immutable and read-only.

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

## Readability

Heavy styling can make a code hard to scan. Until the validation engine ships:

- Keep the default 4-module quiet zone.
- Keep strong contrast between modules and background.
- Avoid very small `scale` values together with low error correction.
- Test your designs on real Android and iOS devices.

## Roadmap

- Independent styling of the three finder patterns.
- Logo support.
- Readability validation: render, decode and compare.
- PNG export.
- Customizable scanner based on `mobile_scanner`.
- Example application.

## License

MIT. See [LICENSE](LICENSE).
