import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:filter_and_sort_app/main.dart';
import 'package:filter_and_sort_app/models/product.dart';
import 'package:filter_and_sort_app/pages/checkout.dart';

final Product _testProduct = Product(
  id: 'test',
  title: 'Olive Linen Work Jacket',
  brand: 'MUJI',
  size: 'L',
  condition: '90%',
  price: 185000,
  imageUrl: '',
  tags: const <String>[],
  createdAt: DateTime(2026),
  popularity: 1,
);

String _total(WidgetTester tester) {
  final Text text = tester.widget<Text>(
    find.byKey(const ValueKey<String>('checkout-total')),
  );
  return text.data!;
}

CheckoutOptionCard _option(WidgetTester tester, String key) {
  return tester.widget<CheckoutOptionCard>(find.byKey(ValueKey<String>(key)));
}

Future<void> _pumpCheckout(WidgetTester tester, {double width = 1080}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(home: CheckoutPage(product: _testProduct)),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapOption(WidgetTester tester, String key) async {
  final Finder finder = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the checkout layout from the design', (
    WidgetTester tester,
  ) async {
    await _pumpCheckout(tester);

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Shipping Address'), findsOneWidget);
    expect(find.text('Delivery Courier'), findsOneWidget);
    expect(find.text('Payment Methods'), findsOneWidget);

    expect(find.text('MUJI · 90% GOOD'), findsOneWidget);
    expect(find.text('Olive Linen Work Jacket'), findsOneWidget);
    expect(find.text('Rp 185.000'), findsOneWidget);

    expect(find.text('Maya Putri · +62 812 3456 7890'), findsOneWidget);
    expect(
      find.text('Jl. Kemang Raya 18, South Jakarta, 12730'),
      findsOneWidget,
    );

    expect(find.text('J&T Regular'), findsOneWidget);
    expect(find.text('2-3 days • Rp 18.000'), findsOneWidget);
    expect(find.text('GoSend Instant'), findsOneWidget);
    expect(find.text('Today • Rp 42.000'), findsOneWidget);

    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('E-Wallet'), findsOneWidget);
    expect(find.text('Total Price'), findsOneWidget);
    expect(find.text('Pay Now'), findsOneWidget);
  });

  testWidgets('defaults to J&T Regular and QRIS with the correct total', (
    WidgetTester tester,
  ) async {
    await _pumpCheckout(tester);

    expect(_total(tester), 'Rp 203.000');
    expect(_option(tester, 'courier:J&T Regular').selected, isTrue);
    expect(_option(tester, 'courier:GoSend Instant').selected, isFalse);
    expect(_option(tester, 'payment:QRIS').selected, isTrue);
    expect(_option(tester, 'payment:E-Wallet').selected, isFalse);
  });

  testWidgets('switching courier recalculates the total', (
    WidgetTester tester,
  ) async {
    await _pumpCheckout(tester);

    await _tapOption(tester, 'courier:GoSend Instant');
    expect(_total(tester), 'Rp 227.000');
    expect(_option(tester, 'courier:GoSend Instant').selected, isTrue);
    expect(_option(tester, 'courier:J&T Regular').selected, isFalse);

    await _tapOption(tester, 'courier:J&T Regular');
    expect(_total(tester), 'Rp 203.000');
  });

  testWidgets('payment selection changes without touching the total', (
    WidgetTester tester,
  ) async {
    await _pumpCheckout(tester);

    await _tapOption(tester, 'payment:E-Wallet');
    expect(_option(tester, 'payment:E-Wallet').selected, isTrue);
    expect(_option(tester, 'payment:QRIS').selected, isFalse);
    expect(_total(tester), 'Rp 203.000');
  });

  testWidgets('pay now confirms and pops the checkout route', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => CheckoutPage(product: _testProduct),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('pay-now')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Payment'), findsOneWidget);
    expect(
      find.text('Pay Rp 203.000 for Olive Linen Work Jacket?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutPage), findsNothing);
    expect(find.text('Payment successful'), findsOneWidget);
  });

  testWidgets('fits a 360px-wide screen without overflowing', (
    WidgetTester tester,
  ) async {
    await _pumpCheckout(tester, width: 1080); // 1080 / 3 = 360 logical px
    expect(tester.takeException(), isNull);
    expect(_total(tester), 'Rp 203.000');
  });

  testWidgets('tapping a listing card opens checkout for that product', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Linen Jacket Neutral'));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutPage), findsOneWidget);
    expect(find.text('UNIQLO · 70% GOOD'), findsOneWidget);
    expect(_total(tester), 'Rp 68.000'); // 50.000 + 18.000
  });
}
