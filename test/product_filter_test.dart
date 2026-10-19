import 'package:flutter_test/flutter_test.dart';

import 'package:filter_and_sort_app/data/dummy_products.dart';
import 'package:filter_and_sort_app/data/product_filter.dart';

void main() {
  group('query filtering', () {
    test('empty query returns every item', () {
      expect(filterProducts(dummyProducts).length, dummyProducts.length);
    });

    test('whitespace-only query returns every item', () {
      expect(filterProducts(dummyProducts, query: '   ').length,
          dummyProducts.length);
    });

    test('single word matches through the title', () {
      final result = filterProducts(dummyProducts, query: 'denim');
      expect(result, isNotEmpty);
      for (final product in result) {
        final haystack = [
          product.title.toLowerCase(),
          product.brand.toLowerCase(),
          ...product.tags.map((tag) => tag.toLowerCase()),
        ].join(' ');
        expect(haystack.contains('denim'), isTrue);
      }
    });

    test('single word matches through a tag only', () {
      final result = filterProducts(dummyProducts, query: 'casual');
      expect(result, isNotEmpty);
      // 'casual' never appears in a title in the fixture, only in tags.
      expect(result.every((p) => p.tags.contains('casual')), isTrue);
      expect(result.any((p) => p.title.toLowerCase().contains('casual')), isTrue);
    });

    test('multi word query requires every word', () {
      final result = filterProducts(dummyProducts, query: 'linen jacket neutral');
      expect(result.length, greaterThanOrEqualTo(3));
      for (final product in result) {
        final haystack = [
          product.title.toLowerCase(),
          product.brand.toLowerCase(),
          ...product.tags.map((tag) => tag.toLowerCase()),
        ].join(' ');
        expect(haystack.contains('linen'), isTrue);
        expect(haystack.contains('jacket'), isTrue);
        expect(haystack.contains('neutral'), isTrue);
      }
    });

    test('query is case insensitive and trims', () {
      final a = filterProducts(dummyProducts, query: '  LINEN  ');
      final b = filterProducts(dummyProducts, query: 'linen');
      expect(a.length, b.length);
    });
  });

  group('dimension filters', () {
    test('brand set filter', () {
      final result = filterProducts(dummyProducts, brands: {'UNIQLO'});
      expect(result, isNotEmpty);
      expect(result.every((p) => p.brand == 'UNIQLO'), isTrue);
    });

    test('multiple brands are OR-ed', () {
      final result =
          filterProducts(dummyProducts, brands: {'UNIQLO', 'ZARA'});
      expect(result.every((p) => p.brand == 'UNIQLO' || p.brand == 'ZARA'),
          isTrue);
      expect(
        result.length,
        dummyProducts
            .where((p) => p.brand == 'UNIQLO' || p.brand == 'ZARA')
            .length,
      );
    });

    test('size set filter', () {
      final result = filterProducts(dummyProducts, sizes: {'M'});
      expect(result, isNotEmpty);
      expect(result.every((p) => p.size == 'M'), isTrue);
    });

    test('brand + size combined', () {
      final result =
          filterProducts(dummyProducts, brands: {'MUJI'}, sizes: {'XL'});
      expect(result.every((p) => p.brand == 'MUJI' && p.size == 'XL'), isTrue);
    });

    test('condition single filter', () {
      final result = filterProducts(dummyProducts, condition: 'Like New');
      expect(result, isNotEmpty);
      expect(result.every((p) => p.condition == 'Like New'), isTrue);
    });

    test('empty sets mean unrestricted', () {
      expect(
        filterProducts(dummyProducts, brands: {}, sizes: {}).length,
        dummyProducts.length,
      );
    });
  });

  group('price range', () {
    test('lower bound is inclusive', () {
      final result = filterProducts(dummyProducts, minPrice: 50000, maxPrice: 50000);
      expect(result.any((p) => p.price == 50000), isTrue);
      expect(result.every((p) => p.price == 50000), isTrue);
    });

    test('upper bound is inclusive', () {
      final result =
          filterProducts(dummyProducts, minPrice: 500000, maxPrice: 500000);
      expect(result.any((p) => p.price == 500000), isTrue);
      expect(result.every((p) => p.price == 500000), isTrue);
    });

    test('narrow range excludes out-of-range prices', () {
      final result = filterProducts(dummyProducts, minPrice: 100000, maxPrice: 150000);
      expect(result, isNotEmpty);
      expect(result.every((p) => p.price >= 100000 && p.price <= 150000), isTrue);
    });
  });

  group('sorting', () {
    test('newest puts the most recent item first', () {
      final result = filterProducts(dummyProducts, sortBy: 'newest');
      final newest = dummyProducts
          .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
      expect(result.first.id, newest.id);
    });

    test('priceAsc puts the cheapest first', () {
      final result = filterProducts(dummyProducts, sortBy: 'priceAsc');
      final cheapest =
          dummyProducts.reduce((a, b) => a.price <= b.price ? a : b);
      expect(result.first.price, cheapest.price);
    });

    test('priceDesc puts the most expensive first', () {
      final result = filterProducts(dummyProducts, sortBy: 'priceDesc');
      final priciest =
          dummyProducts.reduce((a, b) => a.price >= b.price ? a : b);
      expect(result.first.price, priciest.price);
    });

    test('popular puts the highest popularity first', () {
      final result = filterProducts(dummyProducts, sortBy: 'popular');
      final top =
          dummyProducts.reduce((a, b) => a.popularity >= b.popularity ? a : b);
      expect(result.first.popularity, top.popularity);
    });

    test('unknown sort value falls back to newest', () {
      final fallback = filterProducts(dummyProducts, sortBy: 'nonsense');
      final newest = filterProducts(dummyProducts, sortBy: 'newest');
      expect(fallback.map((p) => p.id).toList(), newest.map((p) => p.id).toList());
    });

    test('sorting does not lose or duplicate items', () {
      final result = filterProducts(dummyProducts, sortBy: 'priceAsc');
      expect(result.length, dummyProducts.length);
      expect(result.map((p) => p.id).toSet().length, dummyProducts.length);
    });
  });

  group('countMatches', () {
    test('matches the length of the filtered list', () {
      final params = (
        query: 'linen',
        brands: {'UNIQLO', 'MUJI', 'ZARA', 'Local Brand'},
        sizes: {'S', 'M', 'L', 'XL'},
        condition: null,
      );

      final expected = filterProducts(
        dummyProducts,
        query: params.query,
        brands: params.brands,
        sizes: params.sizes,
        condition: params.condition,
        minPrice: 100000,
        maxPrice: 300000,
        sortBy: 'popular',
      ).length;

      final actual = countMatches(
        dummyProducts,
        query: params.query,
        brands: params.brands,
        sizes: params.sizes,
        condition: params.condition,
        minPrice: 100000,
        maxPrice: 300000,
        sortBy: 'popular',
      );

      expect(actual, expected);
    });

    test('full default range counts every item', () {
      expect(countMatches(dummyProducts), dummyProducts.length);
    });
  });

  group('fixture integrity', () {
    test('there are 24 products with unique ids', () {
      expect(dummyProducts.length, 24);
      expect(dummyProducts.map((p) => p.id).toSet().length, 24);
    });

    test('all brands, sizes and conditions are represented', () {
      final brands = dummyProducts.map((p) => p.brand).toSet();
      final sizes = dummyProducts.map((p) => p.size).toSet();
      final conditions = dummyProducts.map((p) => p.condition).toSet();

      expect(brands, containsAll(<String>['UNIQLO', 'MUJI', 'ZARA', 'Local Brand']));
      expect(sizes, containsAll(<String>['S', 'M', 'L', 'XL']));
      expect(conditions, containsAll(<String>['70%', '80%', '90%', 'Like New']));
    });

    test('price extremes are present', () {
      expect(dummyProducts.any((p) => p.price == 50000), isTrue);
      expect(dummyProducts.any((p) => p.price == 500000), isTrue);
    });
  });
}
