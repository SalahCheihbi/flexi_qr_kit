import 'package:example/designer_config.dart';
import 'package:example/pages/designer_page.dart';
import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

QrDesign _previewDesign(WidgetTester tester) => tester
    .widget<FlexiQrGenerator>(find.byKey(const Key('designer-preview')))
    .design;

FlexiQrGenerator _preview(WidgetTester tester) =>
    tester.widget<FlexiQrGenerator>(find.byKey(const Key('designer-preview')));

Future<void> _pumpDesigner(WidgetTester tester) async {
  usePhoneSize(tester, width: 1000, height: 1600);
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: DesignerPage())),
  );
}

Future<void> _tapControl(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  group('DesignerConfig', () {
    test('maps independent corner radii to the module style', () {
      const config = DesignerConfig(
        topLeft: 1,
        topRight: 2,
        bottomRight: 3,
        bottomLeft: 4,
      );
      expect(
        config.toDesign().moduleStyle.borderRadius,
        const BorderRadius.only(
          topLeft: Radius.circular(1),
          topRight: Radius.circular(2),
          bottomRight: Radius.circular(3),
          bottomLeft: Radius.circular(4),
        ),
      );
    });

    test('maps every finder preset', () {
      for (final preset in FinderPreset.values) {
        final finder = DesignerConfig(finder: preset).toDesign().finderStyle;
        expect(finder == null, preset == FinderPreset.standard);
      }
    });

    test('gradient, logo and quiet zone reach the design', () {
      final design = const DesignerConfig(
        gradient: true,
        logo: true,
        quietZone: 2,
      ).toDesign();
      expect(design.moduleStyle.gradient, isNotNull);
      expect(design.logo?.image, DesignerConfig.logoImage);
      expect(design.quietZone, 2);
      expect(design.defaultErrorCorrectionLevel, QrErrorCorrectionLevel.high);
    });

    test('copyWith can reset error correction to auto', () {
      final fixed = const DesignerConfig().copyWith(
        errorCorrectionLevel: QrErrorCorrectionLevel.low,
      );
      expect(fixed.errorCorrectionLevel, QrErrorCorrectionLevel.low);
      expect(
        fixed.copyWith(shape: QrModuleShape.dots).errorCorrectionLevel,
        QrErrorCorrectionLevel.low,
      );
      expect(
        fixed.copyWith(autoErrorCorrection: true).errorCorrectionLevel,
        isNull,
      );
    });

    test('the default configuration validates', () async {
      const config = DesignerConfig();
      final result = await const QrValidator().validate(
        config.data,
        design: config.toDesign(),
        size: 280,
      );
      expect(
        result.status,
        QrValidationStatus.valid,
        reason: '${result.issues}',
      );
    });
  });

  group('DesignerPage', () {
    testWidgets('every shape chip updates the preview', (tester) async {
      await _pumpDesigner(tester);
      for (final shape in QrModuleShape.values) {
        await _tapControl(tester, find.byKey(Key('shape-${shape.name}')));
        expect(_previewDesign(tester).moduleStyle.shape, shape);
      }
    });

    testWidgets('corner mode toggles smart corners', (tester) async {
      await _pumpDesigner(tester);
      await _tapControl(tester, find.text('Smart'));
      expect(_previewDesign(tester).moduleStyle.cornerMode, QrCornerMode.smart);
      await _tapControl(tester, find.text('Manual'));
      expect(
        _previewDesign(tester).moduleStyle.cornerMode,
        QrCornerMode.manual,
      );
    });

    testWidgets('each corner slider sets only its own radius', (tester) async {
      await _pumpDesigner(tester);
      final corners = {
        'topLeft': (BorderRadius r) => r.topLeft,
        'topRight': (BorderRadius r) => r.topRight,
        'bottomRight': (BorderRadius r) => r.bottomRight,
        'bottomLeft': (BorderRadius r) => r.bottomLeft,
      };
      for (final MapEntry(key: name, value: read) in corners.entries) {
        final before = _previewDesign(tester).moduleStyle.borderRadius!;
        final slider = find.byKey(Key('radius-$name'));
        await tester.ensureVisible(slider);
        await tester.pump();
        // Drag to the far right: the maximum, 12 px.
        await tester.drag(slider, const Offset(1000, 0));
        await tester.pump();

        final after = _previewDesign(tester).moduleStyle.borderRadius!;
        expect(read(after), const Radius.circular(12), reason: name);
        for (final other in corners.keys.where((k) => k != name)) {
          expect(
            corners[other]!(after),
            corners[other]!(before),
            reason: '$name changed $other',
          );
        }
      }
    });

    testWidgets('scale, spacing and quiet zone sliders', (tester) async {
      await _pumpDesigner(tester);
      for (final (id, value) in [
        ('scale', 0.7),
        ('spacing', 2.0),
        ('quiet-zone', 2.0),
      ]) {
        tester.widget<Slider>(find.byKey(Key(id))).onChanged!(value);
        await tester.pump();
      }
      final design = _previewDesign(tester);
      expect(design.moduleStyle.scale, 0.7);
      expect(design.moduleStyle.spacing, 2);
      expect(design.quietZone, 2);
    });

    testWidgets('palette and gradient', (tester) async {
      await _pumpDesigner(tester);
      await _tapControl(tester, find.byKey(const Key('color-2')));
      expect(
        _previewDesign(tester).moduleStyle.color,
        DesignerConfig.palette[2],
      );

      await _tapControl(tester, find.byKey(const Key('gradient')));
      expect(_previewDesign(tester).moduleStyle.gradient, isNotNull);
    });

    testWidgets('finder presets', (tester) async {
      await _pumpDesigner(tester);
      Finder segment(String label) => find.descendant(
        of: find.byKey(const Key('finder')),
        matching: find.text(label),
      );
      await _tapControl(tester, segment('circle'));
      expect(
        _previewDesign(tester).finderStyle,
        QrFinderStyle.circle(color: const DesignerConfig().color),
      );
      await _tapControl(tester, segment('standard'));
      expect(_previewDesign(tester).finderStyle, isNull);
    });

    testWidgets('logo switch and error correction', (tester) async {
      await _pumpDesigner(tester);
      await _tapControl(tester, find.byKey(const Key('logo')));
      expect(_previewDesign(tester).logo, isNotNull);

      await _tapControl(tester, find.text('Q'));
      expect(
        _preview(tester).errorCorrectionLevel,
        QrErrorCorrectionLevel.quartile,
      );
      await _tapControl(tester, find.text('Auto'));
      expect(_preview(tester).errorCorrectionLevel, isNull);
    });

    testWidgets('editing the payload re-encodes and revalidates', (
      tester,
    ) async {
      await _pumpDesigner(tester);
      await settleAsync(tester);
      expect(find.text('Valid: decodes as expected'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('designer-data')),
        'hello designer',
      );
      await tester.pump();
      expect(_preview(tester).data, 'hello designer');

      await settleAsync(tester);
      expect(find.text('Decoded: hello designer'), findsOneWidget);
    });

    testWidgets('a low-contrast color is reported invalid', (tester) async {
      await _pumpDesigner(tester);
      // The last palette entry is light gray.
      await _tapControl(tester, find.byKey(const Key('color-5')));
      await settleAsync(tester);
      expect(find.text('Invalid'), findsOneWidget);
    });

    testWidgets('exports the current design', (tester) async {
      await _pumpDesigner(tester);
      await _tapControl(tester, find.byKey(const Key('designer-export')));
      await settleAsync(tester);
      expect(find.byKey(const Key('export')), findsOneWidget);
    });
  });
}
