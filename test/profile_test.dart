import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:filter_and_sort_app/pages/profile.dart';
import 'package:filter_and_sort_app/pages/search_listing.dart';

void main() {
  testWidgets('renders all profile screen sections from the design',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Status bar & Header
    expect(find.text('9:41'), findsOneWidget);
    expect(find.text('Your Profile'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsWidgets);

    // 2. Profile Details
    expect(find.text('Ryan S Banjarnahor'), findsOneWidget);
    expect(find.text('@ryanmarbun'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.text('  ·  24 reviews'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);

    // 3. Stats Card
    expect(find.text('32'), findsWidgets); // appears in stats and eco banner
    expect(find.text('Items sold'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Active listings'), findsOneWidget);
    expect(find.text('148'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);

    // 4. ThriftMate Wallet Card
    expect(find.text('ThriftMate Wallet'), findsOneWidget);
    expect(find.text('Rp 650.000'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);

    // 5. Menu List Items
    expect(find.text('My Products'), findsOneWidget);
    expect(find.text('12 listed'), findsOneWidget);
    expect(find.text('My Favorites'), findsOneWidget);
    expect(find.text('4 items'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);

    // 6. Eco Banner
    expect(find.text('32 pieces. A second story.'), findsOneWidget);
    expect(
      find.text('Thanks for keeping great style in circulation.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.eco_outlined), findsOneWidget);

    // 7. Bottom Navigation Bar
    expect(find.byType(ThriftBottomNav), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('tapping wallet card shows snackbar feedback',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rp 650.000'));
    await tester.pump();

    expect(find.text('ThriftMate Wallet: Saldo Rp 650.000'), findsOneWidget);
  });

  testWidgets('tapping bottom nav profile tab from Search opens ProfilePage',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SearchListingPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SearchListingPage), findsOneWidget);
    expect(find.byType(ProfilePage), findsNothing);

    // Tap Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Ryan S Banjarnahor'), findsOneWidget);

    // Tap Search tab to navigate back
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsNothing);
    expect(find.byType(SearchListingPage), findsOneWidget);
  });
}
