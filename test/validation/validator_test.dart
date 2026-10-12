import 'dart:typed_data';

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _validator = QrValidator();
final _matrix = const QrPackageEncoder().encode('https://example.com');

List<QrIssueCode> _codes(QrDesign design, {double size = 300, double r = 1}) =>
    _validator
        .checkConfiguration(
          matrix: _matrix,
          design: design,
          size: size,
          pixelRatio: r,
        )
        .map((i) => i.code)
        .toList();

QrLogo _logo(double sizeFactor) =>
    QrLogo(image: MemoryImage(Uint8List(0)), sizeFactor: sizeFactor);

void main() {
  group('contrastRatio', () {
    test('black on white is 21:1', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
    });

    test('is symmetric and 1:1 for equal colors', () {
      const a = Color(0xFF336699), b = Color(0xFFEEEEEE);
      expect(contrastRatio(a, b), contrastRatio(b, a));
      expect(contrastRatio(a, a), 1);
    });
  });

  group('QrValidationResult', () {
    const warn = QrValidationIssue(
      QrIssueCode.quietZoneTooSmall,
      QrIssueSeverity.warning,
      'w',
    );
    const err = QrValidationIssue(
      QrIssueCode.decodeFailed,
      QrIssueSeverity.error,
      'e',
    );

    test('status follows the most severe issue', () {
      expect(QrValidationResult(issues: []).status, QrValidationStatus.valid);
      expect(
        QrValidationResult(issues: [warn]).status,
        QrValidationStatus.warning,
      );
      expect(
        QrValidationResult(issues: [warn, err]).status,
        QrValidationStatus.invalid,
      );
    });

    test('exposes errors, warnings and lookups', () {
      final r = QrValidationResult(issues: [warn, err]);
      expect(r.errors, [err]);
      expect(r.warnings, [warn]);
      expect(r.has(QrIssueCode.decodeFailed), isTrue);
      expect(r.has(QrIssueCode.logoTooLarge), isFalse);
      expect(r.isUsable, isFalse);
    });

    test('issues are read-only', () {
      final r = QrValidationResult(issues: [warn]);
      expect(() => r.issues.add(err), throwsUnsupportedError);
    });
  });

  group('checkConfiguration', () {
    test('the default design has no issues', () {
      expect(_codes(const QrDesign()), isEmpty);
    });

    test('quiet zone below 4 modules is a warning', () {
      expect(_codes(const QrDesign(quietZone: 2)), [
        QrIssueCode.quietZoneTooSmall,
      ]);
    });

    test('contrast: very low is an error, moderate is a warning', () {
      final low = _validator.checkConfiguration(
        matrix: _matrix,
        design: const QrDesign(
          moduleStyle: QrModuleStyle(color: Color(0xFFDDDDDD)),
        ),
        size: 300,
      );
      expect(low.single.code, QrIssueCode.lowContrast);
      expect(low.single.severity, QrIssueSeverity.error);

      final moderate = _validator.checkConfiguration(
        matrix: _matrix,
        design: const QrDesign(
          moduleStyle: QrModuleStyle(color: Color(0xFF888888)),
        ),
        size: 300,
      );
      expect(moderate.single.code, QrIssueCode.lowContrast);
      expect(moderate.single.severity, QrIssueSeverity.warning);
    });

    test('contrast uses the weakest gradient stop', () {
      expect(
        _codes(
          const QrDesign(
            moduleStyle: QrModuleStyle(
              gradient: LinearGradient(
                colors: [Color(0xFF000000), Color(0xFFEEEEEE)],
              ),
            ),
          ),
        ),
        contains(QrIssueCode.lowContrast),
      );
    });

    test('contrast includes finder colors', () {
      expect(
        _codes(
          QrDesign(
            finderStyle: QrFinderStyle.square(color: const Color(0xFFEEEEEE)),
          ),
        ),
        contains(QrIssueCode.lowContrast),
      );
    });

    test('light modules on a dark background are flagged as inverted', () {
      expect(
        _codes(
          const QrDesign(
            moduleStyle: QrModuleStyle(color: Color(0xFFFFFFFF)),
            backgroundColor: Color(0xFF000000),
          ),
        ),
        [QrIssueCode.invertedColors],
      );
    });

    test('transparent background is a warning', () {
      expect(_codes(const QrDesign(backgroundColor: Color(0x00000000))), [
        QrIssueCode.transparentBackground,
      ]);
    });

    test('module pixel size: tiny is an error, small is a warning', () {
      // Version 2 (25 modules) + 8 quiet = 33 modules.
      final tiny = _validator.checkConfiguration(
        matrix: _matrix,
        design: const QrDesign(),
        size: 50,
      );
      expect(tiny.single.code, QrIssueCode.moduleTooSmall);
      expect(tiny.single.severity, QrIssueSeverity.error);
      expect(_codes(const QrDesign(), size: 100), [QrIssueCode.moduleTooSmall]);
      expect(_codes(const QrDesign(), size: 50, r: 4), isEmpty);
    });

    test('logo coverage is compared with error correction capacity', () {
      final high = const QrPackageEncoder().encode(
        'https://example.com',
        errorCorrectionLevel: QrErrorCorrectionLevel.high,
      );
      final low = const QrPackageEncoder().encode(
        'https://example.com',
        errorCorrectionLevel: QrErrorCorrectionLevel.low,
      );
      List<QrValidationIssue> check(QrMatrix m, double f) =>
          _validator.checkConfiguration(
            matrix: m,
            design: QrDesign(logo: _logo(f)),
            size: 300,
          );

      expect(check(high, 0.1), isEmpty);
      final tooBig = check(low, 0.4);
      expect(tooBig.single.code, QrIssueCode.logoTooLarge);
      expect(tooBig.single.severity, QrIssueSeverity.error);
    });

    test('unsafe finder geometry is a warning', () {
      expect(
        _codes(
          const QrDesign(
            bottomLeftFinderStyle: QrFinderStyle(
              outerThickness: 1.5,
              safeMode: false,
            ),
          ),
        ),
        [QrIssueCode.unsafeFinderGeometry],
      );
      // safeMode off but within the safe range is fine.
      expect(
        _codes(const QrDesign(finderStyle: QrFinderStyle(safeMode: false))),
        isEmpty,
      );
    });

    test('finders drawn as dots are flagged, square modules are not', () {
      expect(
        _codes(
          const QrDesign(
            styleFindersAsModules: true,
            moduleStyle: QrModuleStyle(shape: QrModuleShape.dots),
          ),
        ),
        [QrIssueCode.unsafeFinderGeometry],
      );
      expect(_codes(const QrDesign(styleFindersAsModules: true)), isEmpty);
      // Explicit finder styles on every position make the flag irrelevant.
      expect(
        _codes(
          QrDesign(
            styleFindersAsModules: true,
            moduleStyle: const QrModuleStyle(shape: QrModuleShape.dots),
            finderStyle: QrFinderStyle.rounded(),
          ),
        ),
        isEmpty,
      );
    });

    test('small module scale and rotation are warnings', () {
      expect(_codes(const QrDesign(moduleStyle: QrModuleStyle(scale: 0.5))), [
        QrIssueCode.smallModuleScale,
      ]);
      expect(
        _codes(const QrDesign(moduleStyle: QrModuleStyle(rotation: 0.3))),
        [QrIssueCode.rotatedModules],
      );
      // Rotating a circle changes nothing.
      expect(
        _codes(
          const QrDesign(
            moduleStyle: QrModuleStyle(
              shape: QrModuleShape.circle,
              rotation: 0.3,
            ),
          ),
        ),
        isEmpty,
      );
    });
  });

  group('validate (render + independent decode)', () {
    test('a default code is valid and decodes to the input', () async {
      final r = await _validator.validate('https://example.com');
      expect(r.status, QrValidationStatus.valid);
      expect(r.decodedText, 'https://example.com');
    });

    test('a styled code with warnings still decodes', () async {
      final r = await _validator.validate(
        'hello',
        design: const QrDesign(quietZone: 2),
      );
      expect(r.status, QrValidationStatus.warning);
      expect(r.decodedText, 'hello');
    });

    test('an unreadable design is invalid with a decode failure', () async {
      final r = await _validator.validate(
        'hello',
        design: const QrDesign(
          moduleStyle: QrModuleStyle(color: Color(0xFFFAFAFA)),
        ),
      );
      expect(r.status, QrValidationStatus.invalid);
      expect(r.has(QrIssueCode.decodeFailed), isTrue);
      expect(r.decodedText, isNull);
    });

    test('decode check can be skipped', () async {
      final r = await _validator.validate(
        'hello',
        design: const QrDesign(
          moduleStyle: QrModuleStyle(color: Color(0xFFFAFAFA)),
        ),
        decode: false,
      );
      expect(r.has(QrIssueCode.decodeFailed), isFalse);
      expect(r.has(QrIssueCode.lowContrast), isTrue);
    });

    test('checkDecoding reports mismatched content', () async {
      final m = const QrPackageEncoder().encode('actual');
      final image = await renderQrImage(
        matrix: m,
        design: const QrDesign(),
        size: 300,
      );
      final issue = _validator.checkDecoding(
        expected: 'expected',
        rgba: await imageToRgba(image),
        width: image.width,
        height: image.height,
      );
      expect(issue.issue!.code, QrIssueCode.contentMismatch);
      expect(issue.decodedText, 'actual');
    });

    test('uses a custom decoder when given', () async {
      final r = await QrValidator(
        decoder: const _FixedDecoder('nope'),
      ).validate('hello');
      expect(r.has(QrIssueCode.contentMismatch), isTrue);
    });
  });
}

class _FixedDecoder implements QrDecoder {
  const _FixedDecoder(this.text);
  final String? text;

  @override
  String? decode(Uint8List rgba, int width, int height) => text;
}
