import 'package:example/pages/gallery_page.dart';
import 'package:example/showcases.dart';
import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Widget _app(Widget home) => MaterialApp(home: home);

Showcase _byTitle(String title) =>
    showcases.firstWhere((s) => s.title == title);

void main() {
  testWidgets('shows a card for every showcase', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));

    for (final showcase in showcases) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('card-${showcase.slug}')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(showcase.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('shows every category header', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));

    for (final category in showcases.map((s) => s.category).toSet()) {
      await tester.scrollUntilVisible(
        find.text(category),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(category), findsOneWidget);
    }
  });

  testWidgets('tapping a card opens its detail page', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));

    await tester.tap(find.byKey(const ValueKey('card-mixed_corners')));
    // The validation spinner never settles; wait out the route transition.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ShowcasePage), findsOneWidget);
    expect(find.text(_byTitle('Mixed corners').description), findsOneWidget);
  });

  testWidgets('detail page validates a valid showcase', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(_app(ShowcasePage(showcase: _byTitle('Smooth'))));
    expect(find.text('Validating…'), findsOneWidget);

    await settleAsync(tester);

    expect(find.text('Valid: decodes as expected'), findsOneWidget);
    expect(find.text('Decoded: ${_byTitle('Smooth').data}'), findsOneWidget);
  });

  testWidgets('detail page reports an invalid showcase', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      _app(ShowcasePage(showcase: _byTitle('Low contrast'))),
    );
    await settleAsync(tester);

    expect(find.text('Invalid'), findsOneWidget);
    expect(find.text(QrIssueCode.lowContrast.name), findsOneWidget);
  });

  testWidgets('detail page lists warnings', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      _app(ShowcasePage(showcase: _byTitle('No quiet zone'))),
    );
    await settleAsync(tester);

    expect(find.text('Usable, with warnings'), findsOneWidget);
    expect(find.text(QrIssueCode.quietZoneTooSmall.name), findsOneWidget);
  });

  testWidgets('a payload too long shows the error builder', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      _app(ShowcasePage(showcase: _byTitle('Payload too long'))),
    );
    await settleAsync(tester);

    expect(find.text('Cannot encode'), findsOneWidget);
    // No export for a code that does not exist.
    expect(find.byTooltip('Export PNG'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a logo showcase loads and validates its logo', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      _app(ShowcasePage(showcase: _byTitle('Center logo'))),
    );
    await settleAsync(tester, rounds: 8);

    expect(find.text('Valid: decodes as expected'), findsOneWidget);
  });

  testWidgets('export shows a 1200 px PNG', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(_app(ShowcasePage(showcase: _byTitle('Classic'))));
    await tester.tap(find.byTooltip('Export PNG'));
    await tester.pump();
    await settleAsync(tester);

    expect(find.byKey(const Key('export')), findsOneWidget);
    expect(find.textContaining('1200 × 1200 px'), findsOneWidget);
    expect(find.text('Validation: valid'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
