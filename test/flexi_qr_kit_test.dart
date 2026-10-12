import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

class RoundTopOnly extends QrSmartCornerEngine {
  const RoundTopOnly();

  @override
  Set<QrCorner> exposedCorners(QrNeighbors neighbors) => super
      .exposedCorners(neighbors)
      .intersection({QrCorner.topLeft, QrCorner.topRight});
}

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

/// Compiles the README / spec examples against the public API.
void main() {
  test('README finder and background snippets', () {
    final presets = QrDesign(
      finderStyle: QrFinderStyle.rounded(
        outerRadius: const Radius.circular(12),
        innerRadius: const Radius.circular(6),
      ),
      topRightFinderStyle: QrFinderStyle.circle(
        innerColor: const Color(0xFFE91E63),
      ),
      bottomLeftFinderStyle: QrFinderStyle.square(),
    );
    expect(presets.finderStyleFor(QrFinderPosition.bottomLeft), isNotNull);
    expect(
      const QrFinderStyle(outerThickness: 1.6).effectiveOuterThickness,
      1.2,
    );
    expect(
      const QrFinderStyle(
        outerThickness: 1.6,
        safeMode: false,
      ).effectiveOuterThickness,
      1.6,
    );

    final design = QrDesign(
      finderStyle: QrFinderStyle(
        outer: QrFinderPartStyle(borderRadius: BorderRadius.circular(12)),
        inner: QrFinderPartStyle(
          color: const Color(0xFF3F51B5),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      topLeftFinderStyle: const QrFinderStyle(
        outer: QrFinderPartStyle(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      backgroundRenderer: FilledBackgroundRenderer(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
    );
    expect(
      design.finderStyleFor(QrFinderPosition.topLeft),
      design.topLeftFinderStyle,
    );
    expect(
      design.finderStyleFor(QrFinderPosition.bottomLeft),
      design.finderStyle,
    );
    const custom = QrDesign(
      finderStyle: QrFinderStyle(renderer: DiamondEyeRenderer()),
    );
    expect(custom.finderStyle!.renderer, isA<DiamondEyeRenderer>());
  });

  test('README logo snippets', () {
    final generator = FlexiQrGenerator(
      data: 'https://example.com',
      design: QrDesign(
        logo: QrLogo(
          image: const AssetImage('assets/logo.png'),
          sizeFactor: 0.25,
          padding: 6,
          borderRadius: BorderRadius.circular(999),
          renderer: const BadgeLogoRenderer(),
        ),
      ),
    );
    expect(generator.design.logo!.sizeFactor, 0.25);
  });

  test('README smart corner snippets', () {
    const smart = QrDesign(
      moduleStyle: QrModuleStyle(
        shape: QrModuleShape.custom,
        cornerMode: QrCornerMode.smart,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
    );
    expect(smart.moduleStyle.usesSmartCorners, isTrue);

    const custom = QrDesign(
      moduleStyle: QrModuleStyle(shape: QrModuleShape.connected),
      smartCornerEngine: RoundTopOnly(),
    );
    expect(custom.smartCornerEngine.exposedCorners(const QrNeighbors()), {
      QrCorner.topLeft,
      QrCorner.topRight,
    });
  });

  test('README validation and export snippets', () async {
    const design = QrDesign();
    final result = await const QrValidator().validate(
      'https://example.com',
      design: design,
      size: 300,
    );
    expect(result.status, QrValidationStatus.valid);
    expect(result.decodedText, 'https://example.com');

    final export = await const QrExporter().exportPng(
      'https://example.com',
      design: design,
      size: 300,
      pixelRatio: 4,
    );
    expect(export.width, 1200);
    expect(export.validation.isUsable, isTrue);

    await expectLater(
      const QrExporter().exportPng(
        'https://example.com',
        design: const QrDesign(
          moduleStyle: QrModuleStyle(color: Color(0xFFEEEEEE)),
        ),
      ),
      throwsA(isA<QrValidationException>()),
    );
  });

  test('README scanner snippets', () {
    final scanner = FlexiQrScanner(
      onDetect: (result) => result.value,
      overlayStyle: const QrScannerOverlayStyle(
        windowSize: Size(260, 260),
        frame: QrScannerFrameStyle(
          color: Color(0xFF69F0AE),
          strokeWidth: 6,
          cornerLength: 40,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
      ),
    );
    expect(scanner.restrictToScanWindow, isTrue);
    expect(scanner.duplicateCooldown, const Duration(seconds: 2));

    const brackets = QrScannerFrameStyle(
      corners: {QrCorner.topLeft, QrCorner.bottomRight},
      borderRadius: BorderRadius.zero,
    );
    expect(brackets.corners, hasLength(2));
    expect(const QrScannerFrameStyle(fullBorder: true).fullBorder, isTrue);

    final controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      autoStart: false,
    );
    addTearDown(controller.dispose);
    expect(
      FlexiQrScanner(controller: controller, onDetect: (_) {}).controller,
      controller,
    );
  });

  test('README snippets compile and behave as documented', () {
    const gradient = QrDesign(
      moduleStyle: QrModuleStyle(
        shape: QrModuleShape.dots,
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF0277BD)],
        ),
      ),
    );
    expect(gradient.moduleStyle.gradient, isNotNull);

    const custom = QrDesign(
      moduleStyle: QrModuleStyle(renderer: StarRenderer()),
    );
    expect(custom.moduleStyle.renderer, isA<StarRenderer>());

    final generator = FlexiQrGenerator(
      data: 'مرحبا بالعالم',
      errorCorrectionLevel: QrErrorCorrectionLevel.high,
      version: 5,
      errorBuilder: (context, error) => const Text('Data too long'),
    );
    expect(generator.version, 5);

    final matrix = const QrPackageEncoder().encode('hello');
    expect(matrix.size, 21);
    expect(matrix.typeAt(0, 0), QrModuleType.finder);
    expect(matrix.moduleAt(10, 12).row, 10);
  });

  test('public API exposes the documented entry points', () {
    const design = QrDesign(
      moduleStyle: QrModuleStyle(
        shape: QrModuleShape.custom,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
          bottomLeft: Radius.zero,
        ),
      ),
    );
    const widget = FlexiQrGenerator(
      data: 'https://example.com',
      design: design,
    );
    expect(widget.design.moduleStyle.borderRadius!.bottomLeft, Radius.zero);

    final perModule = QrDesign(
      moduleBuilder: (module) => module.isProtected
          ? null
          : const QrModuleStyle(
              shape: QrModuleShape.custom,
              color: Color(0xFF000000),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
                bottomLeft: Radius.zero,
                bottomRight: Radius.circular(6),
              ),
            ),
    );
    expect(perModule.moduleBuilder, isNotNull);
  });
}
