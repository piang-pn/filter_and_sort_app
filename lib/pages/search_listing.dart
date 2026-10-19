import 'package:flutter/material.dart';

import '../data/dummy_products.dart';
import '../data/product_filter.dart';
import '../models/product.dart';
import 'filter_sort.dart';

/// Listing / search results screen.
///
/// No Figma frame exists for this screen yet, so it reuses the palette and
/// chrome of `filter_sort.dart` and `order_history_tracking.dart`. The search
/// field and the filter button both open the Filter & Sort screen, which is
/// where the keyword + chip filters from the design live.
class SearchListingPage extends StatefulWidget {
  const SearchListingPage({super.key});

  @override
  State<SearchListingPage> createState() => _SearchListingPageState();
}

class _SearchListingPageState extends State<SearchListingPage> {
  FilterSelection _filter = const FilterSelection();

  List<Product> get _results => filterProducts(
        dummyProducts,
        query: _filter.query,
        brands: _filter.brands,
        sizes: _filter.sizes,
        condition: _filter.condition,
        minPrice: _filter.minPrice,
        maxPrice: _filter.maxPrice,
        sortBy: _filter.sortBy,
      );

  Future<void> _openFilterAndSort() async {
    final FilterSelection? applied =
        await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute<FilterSelection>(
        builder: (_) => FilterSortPage(
          initial: _filter,
          countMatches: (FilterSelection selection) => countMatches(
            dummyProducts,
            query: selection.query,
            brands: selection.brands,
            sizes: selection.sizes,
            condition: selection.condition,
            minPrice: selection.minPrice,
            maxPrice: selection.maxPrice,
            sortBy: selection.sortBy,
          ),
        ),
      ),
    );

    if (applied != null && mounted) {
      setState(() => _filter = applied);
    }
  }

  void _resetFilters() => setState(() => _filter = const FilterSelection());

  @override
  Widget build(BuildContext context) {
    final List<Product> results = _results;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const StatusBarRow(),
            _buildHeader(results.length),
            _buildSearchLauncher(),
            if (_filter.activeCount > 0) _buildActiveFilters(),
            Expanded(
              child: results.isEmpty ? _buildEmptyState() : _buildGrid(results),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- header ---

  Widget _buildHeader(int resultCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: <Widget>[
          const Text(
            'Search',
            style: TextStyle(
              fontSize: AppText.headerTitle,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const Spacer(),
          Text(
            '$resultCount items',
            style: const TextStyle(
              fontSize: AppText.cardMeta,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchLauncher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: _openFilterAndSort,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.search,
                        size: 20, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _filter.query.trim().isEmpty
                            ? 'linen, jacket, neutral...'
                            : _filter.query,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppText.searchField,
                          color: _filter.query.trim().isEmpty
                              ? AppColors.textMuted
                              : AppColors.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _FilterButton(
            activeCount: _filter.activeCount,
            onTap: _openFilterAndSort,
          ),
        ],
      ),
    );
  }

  /// Removable summary of the currently applied filters.
  Widget _buildActiveFilters() {
    final List<Widget> chips = <Widget>[];

    if (_filter.query.trim().isNotEmpty) {
      chips.add(_RemovableChip(
        label: _filter.query.trim(),
        onRemove: () => setState(() => _filter = _filter.copyWith(query: '')),
      ));
    }
    for (final String brand in _filter.brands) {
      chips.add(_RemovableChip(
        label: brand,
        onRemove: () => setState(() {
          final Set<String> next = <String>{..._filter.brands}..remove(brand);
          _filter = _filter.copyWith(brands: next);
        }),
      ));
    }
    for (final String size in _filter.sizes) {
      chips.add(_RemovableChip(
        label: 'Size $size',
        onRemove: () => setState(
          () => _filter = _filter.copyWith(sizes: const <String>{}),
        ),
      ));
    }
    if (_filter.condition != null) {
      chips.add(_RemovableChip(
        label: _filter.condition!,
        onRemove: () => setState(
          () => _filter = _filter.copyWith(clearCondition: true),
        ),
      ));
    }
    if (_filter.minPrice != 50000 || _filter.maxPrice != 500000) {
      chips.add(_RemovableChip(
        label:
            '${_formatRupiah(_filter.minPrice)} - ${_formatRupiah(_filter.maxPrice)}',
        onRemove: () => setState(
          () => _filter = _filter.copyWith(minPrice: 50000, maxPrice: 500000),
        ),
      ));
    }
    if (_filter.sortBy != 'newest') {
      chips.add(_RemovableChip(
        label: _sortLabel(_filter.sortBy),
        onRemove: () =>
            setState(() => _filter = _filter.copyWith(sortBy: 'newest')),
      ));
    }

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        children: <Widget>[
          ...chips,
          const SizedBox(width: 8),
          Center(
            child: GestureDetector(
              onTap: _resetFilters,
              behavior: HitTestBehavior.opaque,
              child: const Text(
                'Clear all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGreen,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- body ---

  Widget _buildGrid(List<Product> results) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (BuildContext context, int index) =>
          ProductGridCard(product: results[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.search_off, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No items match your filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try widening the price range or clearing a brand.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.darkGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Reset filters',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------- bottom nav ---

  Widget _buildBottomNav() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.lightBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Only the Search tab exists in this project; the other tabs from the
          // original app are intentionally not wired up here.
          _navItem(Icons.search, 'Search'),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 22, color: AppColors.darkGreen),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGreen,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Presentational pieces owned by this screen
/// ---------------------------------------------------------------------------

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune, color: AppColors.white, size: 22),
          ),
          if (activeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.sageFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkGreen),
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for one catalogue item. Public so the listing stays testable.
class ProductGridCard extends StatelessWidget {
  const ProductGridCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE7E4DC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined,
                    size: 28, color: AppColors.textMuted),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppText.cardTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.brand} · ${product.size}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppText.cardMeta,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _formatRupiah(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sageFill,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.condition,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRupiah(int value) {
  final String digits = value.toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp ${buffer.toString()}';
}

String _sortLabel(String sortBy) {
  switch (sortBy) {
    case 'priceAsc':
      return 'Harga terendah';
    case 'priceDesc':
      return 'Harga tertinggi';
    case 'popular':
      return 'Terpopuler';
    default:
      return 'Terbaru';
  }
}
