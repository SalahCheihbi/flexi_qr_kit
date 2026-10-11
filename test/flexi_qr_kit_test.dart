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

/// Compiles the README / spec examples against the public API.
void main() {
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
