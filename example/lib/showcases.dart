import 'dart:math' as math;

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';

/// What validating a showcase is expected to report.
enum ShowcaseOutcome {
  /// Decodes with no issues.
  valid,

  /// Decodes, with warnings.
  warning,

  /// Fails validation: shown to demonstrate what the validator catches.
  invalid,

  /// The payload cannot be encoded: shown to demonstrate `errorBuilder`.
  encodingError,
}

/// One entry of the gallery: a payload and a design demonstrating a feature.
class Showcase {
  const Showcase({
    required this.title,
    required this.description,
    required this.category,
    this.data = 'https://pub.dev/packages/flexi_qr_kit',
    this.design = const QrDesign(),
    this.errorCorrectionLevel,
    this.outcome = ShowcaseOutcome.valid,
  });

  final String title;
  final String description;
  final String category;
  final String data;
  final QrDesign design;
  final QrErrorCorrectionLevel? errorCorrectionLevel;
  final ShowcaseOutcome outcome;

  /// File-name friendly identifier, used for golden files.
  String get slug => title
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

/// Draws each module as a four-pointed star.
class StarRenderer extends QrModuleRenderer {
  const StarRenderer();

  @override
  Path buildPath(QrModuleGeometry geometry) {
    final r = geometry.rect;
    final c = r.center;
    final inner = r.width * 0.18;
    return Path()
      ..moveTo(c.dx, r.top)
      ..lineTo(c.dx + inner, c.dy - inner)
      ..lineTo(r.right, c.dy)
      ..lineTo(c.dx + inner, c.dy + inner)
      ..lineTo(c.dx, r.bottom)
      ..lineTo(c.dx - inner, c.dy + inner)
      ..lineTo(r.left, c.dy)
      ..lineTo(c.dx - inner, c.dy - inner)
      ..close();
  }
}

/// Smart corners that only ever round the top corners.
class RoundTopOnlyEngine extends QrSmartCornerEngine {
  const RoundTopOnlyEngine();

  @override
  Set<QrCorner> exposedCorners(QrNeighbors neighbors) => super
      .exposedCorners(neighbors)
      .intersection({QrCorner.topLeft, QrCorner.topRight});
}

/// Colors each module by its role in the symbol.
QrModuleStyle? colorByType(QrModuleContext module) {
  final color = switch (module.type) {
    QrModuleType.finder => const Color(0xFF1A237E),
    QrModuleType.alignment => const Color(0xFFC62828),
    QrModuleType.timing => const Color(0xFF2E7D32),
    QrModuleType.data => const Color(0xFF212121),
    _ => const Color(0xFF6A1B9A),
  };
  return QrModuleStyle(
    shape: module.isProtected ? QrModuleShape.square : QrModuleShape.dots,
    color: color,
  );
}

const _logo = AssetImage('assets/logo.png');
const _ink = Color(0xFF111827);

/// All gallery entries, grouped by [Showcase.category].
final showcases = <Showcase>[
  // Basics.
  Showcase(
    title: 'Classic',
    description: 'Default design: square modules, 4-module quiet zone.',
    category: 'Basics',
  ),
  Showcase(
    title: 'Mixed corners',
    description:
        'Three rounded corners and one sharp corner on every module, '
        'with BorderRadius.only.',
    category: 'Basics',
    design: QrDesign(
      moduleStyle: QrModuleStyle(
        shape: QrModuleShape.custom,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
    ),
  ),
  Showcase(
    title: 'Unicode payload',
    description: 'Arabic text and emoji, encoded as UTF-8.',
    category: 'Basics',
    data: 'مرحبا بالعالم 👋 flexi_qr_kit',
    errorCorrectionLevel: QrErrorCorrectionLevel.quartile,
  ),

  // Shapes.
  Showcase(
    title: 'Rounded',
    description: 'QrModuleShape.rounded.',
    category: 'Shapes',
    design: QrDesign(moduleStyle: QrModuleStyle(shape: QrModuleShape.rounded)),
  ),
  Showcase(
    title: 'Dots',
    description: 'QrModuleShape.dots.',
    category: 'Shapes',
    design: QrDesign(moduleStyle: QrModuleStyle(shape: QrModuleShape.dots)),
  ),
  Showcase(
    title: 'Circle',
    description: 'QrModuleShape.circle.',
    category: 'Shapes',
    design: QrDesign(moduleStyle: QrModuleStyle(shape: QrModuleShape.circle)),
  ),
  Showcase(
    title: 'Diamond',
    description: 'QrModuleShape.diamond.',
    category: 'Shapes',
    design: QrDesign(moduleStyle: QrModuleStyle(shape: QrModuleShape.diamond)),
  ),
  Showcase(
    title: 'Custom renderer',
    description: 'A QrModuleRenderer drawing each module as a star.',
    category: 'Shapes',
    design: QrDesign(moduleStyle: QrModuleStyle(renderer: StarRenderer())),
  ),

  // Smart corners.
  Showcase(
    title: 'Connected',
    description: 'Neighbors merge; only exposed corners are rounded.',
    category: 'Smart corners',
    design: QrDesign(
      moduleStyle: QrModuleStyle(shape: QrModuleShape.connected),
    ),
  ),
  Showcase(
    title: 'Smooth',
    description: 'Connected, with concave fillets in L-shaped junctions.',
    category: 'Smart corners',
    design: QrDesign(moduleStyle: QrModuleStyle(shape: QrModuleShape.smooth)),
  ),
  Showcase(
    title: 'Smart custom radius',
    description: 'A custom radius applied only to exposed corners.',
    category: 'Smart corners',
    design: QrDesign(
      moduleStyle: QrModuleStyle(
        shape: QrModuleShape.custom,
        cornerMode: QrCornerMode.smart,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    ),
  ),
  Showcase(
    title: 'Custom corner engine',
    description: 'A QrSmartCornerEngine subclass that rounds tops only.',
    category: 'Smart corners',
    design: QrDesign(
      smartCornerEngine: RoundTopOnlyEngine(),
      moduleStyle: QrModuleStyle(shape: QrModuleShape.connected),
    ),
  ),

  // Color and effects.
  Showcase(
    title: 'Gradient',
    description: 'A linear gradient across the whole code.',
    category: 'Color & effects',
    design: QrDesign(
      moduleStyle: QrModuleStyle(
        shape: QrModuleShape.dots,
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF0277BD)],
        ),
      ),
    ),
  ),
  Showcase(
    title: 'Scale and spacing',
    description: 'Modules shrunk to 85% with 1px spacing.',
    category: 'Color & effects',
    design: QrDesign(
      moduleStyle: QrModuleStyle(
        shape: QrModuleShape.rounded,
        color: Color(0xFF004D40),
        scale: 0.85,
        spacing: 1,
      ),
    ),
  ),
  Showcase(
    title: 'Opacity',
    description: 'Modules drawn at 85% opacity.',
    category: 'Color & effects',
    design: QrDesign(
      moduleStyle: QrModuleStyle(color: Color(0xFF0D47A1), opacity: 0.85),
    ),
  ),
  Showcase(
    title: 'Rotated modules',
    description: 'Square modules rotated 45°. The validator warns about it.',
    category: 'Color & effects',
    outcome: ShowcaseOutcome.warning,
    design: QrDesign(
      moduleStyle: QrModuleStyle(scale: 0.9, rotation: math.pi / 4),
    ),
  ),
  Showcase(
    title: 'Style per module',
    description:
        'moduleBuilder colors finders, alignment and timing patterns '
        'differently.',
    category: 'Color & effects',
    design: QrDesign(moduleBuilder: colorByType),
  ),

  // Finders.
  Showcase(
    title: 'Rounded finders',
    description: 'QrFinderStyle.rounded() preset.',
    category: 'Finders',
    design: QrDesign(
      moduleStyle: QrModuleStyle(shape: QrModuleShape.dots),
      finderStyle: QrFinderStyle.rounded(),
    ),
  ),
  Showcase(
    title: 'Circle finders',
    description: 'QrFinderStyle.circle() with a colored eye.',
    category: 'Finders',
    design: QrDesign(
      moduleStyle: QrModuleStyle(shape: QrModuleShape.circle),
      finderStyle: QrFinderStyle.circle(innerColor: Color(0xFFD81B60)),
    ),
  ),
  Showcase(
    title: 'Finder per position',
    description:
        'Top-left, top-right and bottom-left finders styled independently.',
    category: 'Finders',
    design: QrDesign(
      moduleStyle: QrModuleStyle(shape: QrModuleShape.smooth),
      topLeftFinderStyle: QrFinderStyle(
        outer: QrFinderPartStyle(
          color: Color(0xFF1565C0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        inner: QrFinderPartStyle(
          color: Color(0xFF1565C0),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      topRightFinderStyle: QrFinderStyle(
        outer: QrFinderPartStyle(
          color: Color(0xFF2E7D32),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          ),
        ),
        inner: QrFinderPartStyle(color: Color(0xFF2E7D32)),
      ),
      bottomLeftFinderStyle: QrFinderStyle(
        outer: QrFinderPartStyle(
          color: Color(0xFFC62828),
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        inner: QrFinderPartStyle(
          color: Color(0xFFC62828),
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
      ),
    ),
  ),
  Showcase(
    title: 'Finder gradient and separator',
    description: 'Gradient frame, thicker in safe mode, with a separator.',
    category: 'Finders',
    design: QrDesign(
      backgroundColor: Color(0xFFFFF8E1),
      finderStyle: QrFinderStyle(
        outer: QrFinderPartStyle(
          gradient: LinearGradient(
            colors: [Color(0xFFBF360C), Color(0xFF4A148C)],
          ),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        inner: QrFinderPartStyle(
          color: Color(0xFF4A148C),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        separator: QrFinderPartStyle(color: Color(0xFFFFFFFF)),
        outerThickness: 1.2,
      ),
    ),
  ),
  Showcase(
    title: 'Finders as modules',
    description: 'styleFindersAsModules draws finders with the module style.',
    category: 'Finders',
    design: QrDesign(
      styleFindersAsModules: true,
      moduleStyle: QrModuleStyle(shape: QrModuleShape.connected),
    ),
  ),

  // Background and logo.
  Showcase(
    title: 'Gradient background',
    description: 'FilledBackgroundRenderer with a gradient and rounded card.',
    category: 'Background & logo',
    design: QrDesign(
      backgroundRenderer: FilledBackgroundRenderer(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3F2FD), Color(0xFFFCE4EC)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      moduleStyle: QrModuleStyle(shape: QrModuleShape.smooth, color: _ink),
      finderStyle: QrFinderStyle.rounded(color: _ink),
    ),
  ),
  Showcase(
    title: 'Center logo',
    description: 'Module-aligned logo; error correction switches to H.',
    category: 'Background & logo',
    design: QrDesign(
      moduleStyle: QrModuleStyle(shape: QrModuleShape.dots),
      finderStyle: QrFinderStyle.rounded(),
      logo: QrLogo(image: _logo, sizeFactor: 0.2),
    ),
  ),
  Showcase(
    title: 'Logo badge',
    description: 'Logo on a rounded white container with mixed radii.',
    category: 'Background & logo',
    design: QrDesign(
      backgroundColor: Color(0xFFEDE7F6),
      moduleStyle: QrModuleStyle(
        shape: QrModuleShape.connected,
        color: Color(0xFF311B92),
      ),
      finderStyle: QrFinderStyle.rounded(color: Color(0xFF311B92)),
      logo: QrLogo(
        image: _logo,
        sizeFactor: 0.18,
        padding: 6,
        backgroundColor: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
    ),
  ),
  Showcase(
    title: 'Asymmetric finder with logo',
    description:
        'Finder corners rounded on three sides only, with a small logo.',
    category: 'Background & logo',
    data: 'https://maroc.ma',
    design: QrDesign(
      finderStyle: QrFinderStyle(
        inner: QrFinderPartStyle(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(2),
            topLeft: Radius.circular(2),
            topRight: Radius.circular(2),
          ),
        ),
        outer: QrFinderPartStyle(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(8),
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
      ),
      logo: QrLogo(image: _logo, sizeFactor: 0.15, padding: 4),
    ),
  ),

  // Validation.
  Showcase(
    title: 'Low contrast',
    description: 'Light gray on white: the validator rejects it.',
    category: 'Validation',
    outcome: ShowcaseOutcome.invalid,
    design: QrDesign(moduleStyle: QrModuleStyle(color: Color(0xFFDDDDDD))),
  ),
  Showcase(
    title: 'No quiet zone',
    description: 'quietZone: 0. Many scanners need the margin.',
    category: 'Validation',
    outcome: ShowcaseOutcome.warning,
    design: QrDesign(quietZone: 0),
  ),
  Showcase(
    title: 'Payload too long',
    description: 'Too much data for version 40: errorBuilder is shown.',
    category: 'Validation',
    outcome: ShowcaseOutcome.encodingError,
    data: _tooLong,
    errorCorrectionLevel: QrErrorCorrectionLevel.high,
  ),
];

const _tooLong =
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz'
    '0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz';
