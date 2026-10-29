import 'package:flutter/material.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:kicks_collection/main.dart';

void main() {
  testWidgets('shows the shoe shop and adds an item to the cart',
      (tester) async {
    tester.view.physicalSize = const Size(440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KicksCollectionApp());
    await tester.pumpAndSettle();

    expect(find.text('Kicks'), findsOneWidget);
    expect(find.text('Air Runner Classic'), findsOneWidget);

    await tester.tap(find.byTooltip('Add sa cart').first);
    await tester.pumpAndSettle();

    expect(find.text('Cart 1'), findsOneWidget);
    expect(find.text('Air Runner Classic naidagdag sa cart'), findsOneWidget);
  });
}
