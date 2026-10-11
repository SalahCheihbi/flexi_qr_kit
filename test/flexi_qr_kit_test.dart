import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compiles the README / spec examples against the public API.
void main() {
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
