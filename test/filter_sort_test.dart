import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:filter_and_sort_app/pages/filter_sort.dart';

/// Holds the value the pushed route pops with.
class _Popped {
  FilterSelection? value;
}

/// Pumps a host screen and opens [FilterSortPage] on top of it, so that the
/// Apply button's `Navigator.pop(selection)` has somewhere to return to.
Future<_Popped> _openFilterPage(
  WidgetTester tester, {
  int Function(FilterSelection selection)? countMatches,
  FilterSelection initial = const FilterSelection(),
}) async {
  final _Popped popped = _Popped();

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
              onPressed: () async {
                popped.value =
                    await Navigator.of(context).push<FilterSelection>(
                  MaterialPageRoute<FilterSelection>(
                    builder: (_) => FilterSortPage(
                      initial: initial,
                      countMatches: countMatches,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return popped;
}

Finder _chip(String label) => find.byKey(ValueKey<String>('chip:$label'));

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.ensureVisible(_chip(label));
  await tester.pumpAndSettle();
  await tester.tap(_chip(label));
  await tester.pumpAndSettle();
}

Future<void> _tapApply(WidgetTester tester) async {
  await tester.tap(find.textContaining('Apply Filters'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders every section from the design', (WidgetTester tester) async {
    await _openFilterPage(tester);

    expect(find.text('Filter & Sort'), findsOneWidget);
    expect(find.text('Brands'), findsOneWidget);
    expect(find.text('Size'), findsOneWidget);
    expect(find.text('Price Range'), findsOneWidget);
    expect(find.text('Item Condition'), findsOneWidget);
    expect(find.text('Sort'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.textContaining('Apply Filters'), findsOneWidget);
    expect(
      find.text('Wider condition filters help good clothes find a second life.'),
      findsOneWidget,
    );
    expect(find.text('linen, jacket, neutral...'), findsOneWidget);
  });

  testWidgets('pill chips hug their label instead of filling the width',
      (WidgetTester tester) async {
    await _openFilterPage(tester);

    // Regression guard: a Container with `alignment` inside a Wrap expands to
    // the full available width and stretches every chip.
    final Size uniqlo = tester.getSize(_chip('UNIQLO'));
    final Size muji = tester.getSize(_chip('MUJI'));
    final Size localBrand = tester.getSize(_chip('Local Brand'));

    expect(uniqlo.width, lessThan(140));
    expect(muji.width, lessThan(uniqlo.width + 20));
    expect(localBrand.width, greaterThan(uniqlo.width));
    expect(muji.height, 42);
  });

  testWidgets('size chips are 44x44 circles', (WidgetTester tester) async {
    await _openFilterPage(tester);

    for (final String size in <String>['S', 'M', 'L', 'XL']) {
      final Size box = tester.getSize(_chip(size));
      expect(box.width, 44, reason: 'size $size should be a 44px circle');
      expect(box.height, 44, reason: 'size $size should be a 44px circle');
    }
  });

  testWidgets('apply button renders the live match count',
      (WidgetTester tester) async {
    await _openFilterPage(tester, countMatches: (_) => 7);

    expect(find.text('Apply Filters (7)'), findsOneWidget);
  });

  testWidgets('apply returns the chosen filters', (WidgetTester tester) async {
    final _Popped popped = await _openFilterPage(tester);

    await _tapChip(tester, 'UNIQLO');
    await _tapChip(tester, 'M');
    await _tapChip(tester, '90%');
    await _tapApply(tester);

    expect(popped.value, isNotNull);
    expect(popped.value!.brands, <String>{'UNIQLO'});
    expect(popped.value!.sizes, <String>{'M'});
    expect(popped.value!.condition, '90%');
    expect(popped.value!.sortBy, 'newest');
  });

  testWidgets('brand chips toggle off when tapped twice',
      (WidgetTester tester) async {
    final _Popped popped = await _openFilterPage(tester);

    await _tapChip(tester, 'ZARA');
    await _tapChip(tester, 'ZARA');
    await _tapApply(tester);

    expect(popped.value!.brands, isEmpty);
  });

  testWidgets('the added Sort section maps chips to sort keys',
      (WidgetTester tester) async {
    final _Popped popped = await _openFilterPage(tester);

    await _tapChip(tester, 'Harga terendah');
    await _tapApply(tester);
    expect(popped.value!.sortBy, 'priceAsc');
  });

  testWidgets('clear resets every dimension before applying',
      (WidgetTester tester) async {
    final _Popped popped = await _openFilterPage(tester);

    await _tapChip(tester, 'UNIQLO');
    await _tapChip(tester, '90%');
    await _tapChip(tester, 'Terpopuler');

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await _tapApply(tester);

    final FilterSelection applied = popped.value!;
    expect(applied.brands, isEmpty);
    expect(applied.sizes, isEmpty);
    expect(applied.condition, isNull);
    expect(applied.sortBy, 'newest');
    expect(applied.minPrice, 50000);
    expect(applied.maxPrice, 500000);
  });

  group('price range snaps to 50k steps', () {
    testWidgets('slider is divided into nine 50k steps over 50k..500k',
        (WidgetTester tester) async {
      await _openFilterPage(tester);

      final RangeSlider slider =
          tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.min, 50000);
      expect(slider.max, 500000);
      expect(slider.divisions, 9);
      expect((slider.max - slider.min) / slider.divisions!, 50000);
    });

    testWidgets('prices restored from the previous selection are snapped',
        (WidgetTester tester) async {
      final _Popped popped = await _openFilterPage(
        tester,
        initial: const FilterSelection(minPrice: 130000, maxPrice: 470000),
      );

      await _tapApply(tester);

      expect(popped.value!.minPrice, 150000); // 130k -> nearest 50k step
      expect(popped.value!.maxPrice, 450000); // 470k -> nearest 50k step
    });

    testWidgets('every value the slider produces is a multiple of 50k',
        (WidgetTester tester) async {
      final _Popped popped = await _openFilterPage(tester);

      await tester.ensureVisible(find.byType(RangeSlider));
      await tester.pumpAndSettle();

      final Rect track = tester.getRect(find.byType(RangeSlider));
      await tester.tapAt(Offset(track.left + track.width * 0.35, track.center.dy));
      await tester.pumpAndSettle();
      await _tapApply(tester);

      final FilterSelection applied = popped.value!;
      expect(applied.minPrice % 50000, 0);
      expect(applied.maxPrice % 50000, 0);
      expect(applied.minPrice, greaterThanOrEqualTo(50000));
      expect(applied.maxPrice, lessThanOrEqualTo(500000));
    });

    testWidgets('clearing restores the full 50k..500k range',
        (WidgetTester tester) async {
      final _Popped popped = await _openFilterPage(
        tester,
        initial: const FilterSelection(minPrice: 100000, maxPrice: 200000),
      );

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      await _tapApply(tester);

      expect(popped.value!.minPrice, 50000);
      expect(popped.value!.maxPrice, 500000);
    });
  });
}
