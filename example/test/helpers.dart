import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets real asynchronous work (image rendering, decoding, asset loading)
/// finish, then rebuilds.
Future<void> settleAsync(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 350));
  }
}

/// Gives the test window a phone-like size.
void usePhoneSize(
  WidgetTester tester, {
  double width = 420,
  double height = 900,
}) {
  tester.view.physicalSize = Size(width, height) * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);
}
