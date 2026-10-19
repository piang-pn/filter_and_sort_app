import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:filter_and_sort_app/main.dart';
import 'package:filter_and_sort_app/pages/search_listing.dart';

void main() {
  testWidgets('app boots into the search listing screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(SearchListingPage), findsOneWidget);
    expect(find.text('Search'), findsWidgets);
    expect(find.text('24 items'), findsOneWidget);
    expect(find.text('linen, jacket, neutral...'), findsOneWidget);
    expect(find.text('Linen Jacket Neutral'), findsOneWidget);
  });
}
