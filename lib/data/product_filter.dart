import '../models/product.dart';

/// Pure filtering and sorting logic for the thrift product catalogue.
///
/// Deliberately free of Flutter imports so it can be unit tested headless.
/// Empty [query] means "no keyword filter", empty [brands] / [sizes] sets mean
/// "no restriction" for that dimension.
List<Product> filterProducts(
  List<Product> items, {
  String query = '',
  Set<String> brands = const <String>{},
  Set<String> sizes = const <String>{},
  String? condition,
  int minPrice = 50000,
  int maxPrice = 500000,
  String sortBy = 'newest',
}) {
  final words = query
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  final List<Product> matched = items.where((product) {
    // Keyword: every word must appear in title, brand or tags.
    if (words.isNotEmpty) {
      final String title = product.title.toLowerCase();
      final String brand = product.brand.toLowerCase();
      final List<String> tags =
          product.tags.map((tag) => tag.toLowerCase()).toList();

      for (final word in words) {
        final bool hit = title.contains(word) ||
            brand.contains(word) ||
            tags.any((tag) => tag.contains(word));
        if (!hit) return false;
      }
    }

    // Multi-select dimensions: OR inside the set.
    if (brands.isNotEmpty && !brands.contains(product.brand)) return false;
    if (sizes.isNotEmpty && !sizes.contains(product.size)) return false;

    // Single-select condition.
    if (condition != null && product.condition != condition) return false;

    // Inclusive price range.
    if (product.price < minPrice || product.price > maxPrice) return false;

    return true;
  }).toList();

  matched.sort((a, b) => _compare(a, b, sortBy));
  return matched;
}

/// Same signature as [filterProducts]; returns only the number of matches so
/// the UI can render "Apply Filters (n)" without building the whole list.
int countMatches(
  List<Product> items, {
  String query = '',
  Set<String> brands = const <String>{},
  Set<String> sizes = const <String>{},
  String? condition,
  int minPrice = 50000,
  int maxPrice = 500000,
  String sortBy = 'newest',
}) {
  return filterProducts(
    items,
    query: query,
    brands: brands,
    sizes: sizes,
    condition: condition,
    minPrice: minPrice,
    maxPrice: maxPrice,
    sortBy: sortBy,
  ).length;
}

/// Sort comparator. Ties always fall back to comparing [Product.id] so the
/// output order is deterministic.
int _compare(Product a, Product b, String sortBy) {
  int result;
  switch (sortBy) {
    case 'priceAsc':
      result = a.price.compareTo(b.price);
    case 'priceDesc':
      result = b.price.compareTo(a.price);
    case 'popular':
      result = b.popularity.compareTo(a.popularity);
    default:
      // 'newest' and any unknown value.
      result = b.createdAt.compareTo(a.createdAt);
  }
  return result != 0 ? result : a.id.compareTo(b.id);
}
