import 'dart:io';
import 'dart:ui' as ui;

import 'package:example/showcases.dart';
import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decodes the example logo from disk, as the app would from its assets.
Future<ui.Image> _logo() async {
  final codec = await ui.instantiateImageCodec(
    File('assets/logo.png').readAsBytesSync(),
  );
  return (await codec.getNextFrame()).image;
}

void main() {
  test('showcase titles are unique', () {
    final slugs = showcases.map((s) => s.slug).toSet();
    expect(slugs, hasLength(showcases.length));
  });

  test('every module shape appears in the gallery', () {
    final shapes = showcases.map((s) => s.design.moduleStyle.shape).toSet();
    expect(shapes, containsAll(QrModuleShape.values));
  });

  test('every outcome is demonstrated', () {
    expect(
      showcases.map((s) => s.outcome).toSet(),
      ShowcaseOutcome.values.toSet(),
    );
  });

  for (final showcase in showcases) {
    test('${showcase.title} validates as ${showcase.outcome.name}', () async {
      const validator = QrValidator();
      Future<QrValidationResult> validate() async => validator.validate(
        showcase.data,
        design: showcase.design,
        errorCorrectionLevel: showcase.errorCorrectionLevel,
        size: 300,
        logoImage: showcase.design.logo == null ? null : await _logo(),
      );

      if (showcase.outcome == ShowcaseOutcome.encodingError) {
        await expectLater(validate(), throwsA(isA<QrDataTooLongException>()));
        return;
      }

      final result = await validate();
      final expected = switch (showcase.outcome) {
        ShowcaseOutcome.valid => QrValidationStatus.valid,
        ShowcaseOutcome.warning => QrValidationStatus.warning,
        _ => QrValidationStatus.invalid,
      };
      expect(result.status, expected, reason: '${result.issues}');
      if (result.isUsable) expect(result.decodedText, showcase.data);
    });
  }
}
