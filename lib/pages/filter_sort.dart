import 'package:flutter/material.dart';

/// Palette taken from the Figma reference (`lib/desing/searchandfilter.png`).
class AppColors {
  static const Color cream = Color(0xFFF5F3EA);
  static const Color darkGreen = Color(0xFF2F3E33);
  static const Color sageFill = Color(0xFFDDE6DA);
  static const Color lightBorder = Color(0xFFDDDCD5);
  static const Color darkText = Color(0xFF1C1C1E);
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color white = Colors.white;
}

/// Font sizes shared by the search / filter screens.
class AppText {
  static const double statusBar = 14;
  static const double headerTitle = 20;
  static const double sectionLabel = 16;
  static const double searchField = 15;
  static const double chipLabel = 14;
  static const double bannerText = 13;
  static const double priceLabel = 13;
  static const double cardTitle = 13;
  static const double cardMeta = 11;
}

/// Everything the filter screen can produce. Immutable so the listing page can
/// keep it in state and hand it back in as the initial value next time.
class FilterSelection {
  const FilterSelection({
    this.query = '',
    this.brands = const <String>{},
    this.sizes = const <String>{},
    this.condition,
    this.minPrice = 50000,
    this.maxPrice = 500000,
    this.sortBy = 'newest',
  });

  final String query;
  final Set<String> brands;
  final Set<String> sizes;
  final String? condition;
  final int minPrice;
  final int maxPrice;
  final String sortBy;

  bool get isEmpty =>
      query.trim().isEmpty &&
      brands.isEmpty &&
      sizes.isEmpty &&
      condition == null &&
      minPrice == 50000 &&
      maxPrice == 500000 &&
      sortBy == 'newest';

  int get activeCount =>
      brands.length +
      (query.trim().isEmpty ? 0 : 1) +
      (sizes.isEmpty ? 0 : 1) +
      (condition == null ? 0 : 1) +
      (minPrice == 50000 && maxPrice == 500000 ? 0 : 1) +
      (sortBy == 'newest' ? 0 : 1);

  FilterSelection copyWith({
    String? query,
    Set<String>? brands,
    Set<String>? sizes,
    String? condition,
    bool clearCondition = false,
    int? minPrice,
    int? maxPrice,
    String? sortBy,
  }) {
    return FilterSelection(
      query: query ?? this.query,
      brands: brands ?? this.brands,
      sizes: sizes ?? this.sizes,
      condition: clearCondition ? null : (condition ?? this.condition),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Filter & Sort screen — mirrors the Figma design, plus a Sort section that was
/// added on request (the design only had the title, no sort control).
/// ---------------------------------------------------------------------------
class FilterSortPage extends StatefulWidget {
  const FilterSortPage({
    super.key,
    this.initial = const FilterSelection(),
    this.countMatches,
    this.onApply,
  });

  /// Selection to restore when the screen is reopened.
  final FilterSelection initial;

  /// Counts how many products match the *live* selection, so the action button
  /// can read "Apply Filters (n)" while the user is still toggling chips.
  final int Function(FilterSelection selection)? countMatches;

  /// Called right before the screen closes with the applied selection.
  final void Function(FilterSelection selection)? onApply;

  @override
  State<FilterSortPage> createState() => _FilterSortPageState();
}

class _FilterSortPageState extends State<FilterSortPage> {
  late final TextEditingController _searchController;
  late Set<String> _brands;
  late RangeValues _price;
  String? _size;
  String? _condition;
  late String _sortBy;

  static const RangeValues _priceBounds = RangeValues(50000, 500000);

  /// Langkah slider harga: kelipatan Rp 50.000 (50k, 100k, 150k, ... 500k).
  static const double _priceStep = 50000;
  static const int _priceDivisions = 9; // (500000 - 50000) / 50000

  static const List<String> _brandOptions = <String>[
    'UNIQLO',
    'MUJI',
    'ZARA',
    'Local Brand',
  ];
  static const List<String> _sizeOptions = <String>['S', 'M', 'L', 'XL'];
  static const List<String> _conditionOptions = <String>[
    '70%',
    '80%',
    '90%',
    'Like New',
  ];
  static const List<(String, String)> _sortOptions = <(String, String)>[
    ('Terbaru', 'newest'),
    ('Harga terendah', 'priceAsc'),
    ('Harga tertinggi', 'priceDesc'),
    ('Terpopuler', 'popular'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initial.query);
    _brands = <String>{...widget.initial.brands};
    // Nilai masuk dibulatkan dulu ke kelipatan 50k supaya posisi thumb selalu
    // pas di grid slider (RangeSlider dengan `divisions` butuh nilai diskret).
    final double start = _snapPrice(widget.initial.minPrice.toDouble());
    final double end = _snapPrice(widget.initial.maxPrice.toDouble());
    _price = RangeValues(start, end < start ? start : end);
    _size = widget.initial.sizes.length == 1 ? widget.initial.sizes.first : null;
    _condition = widget.initial.condition;
    _sortBy = widget.initial.sortBy;
  }

  /// Membulatkan harga ke kelipatan [_priceStep] terdekat, tetap di dalam
  /// batas slider.
  static double _snapPrice(double value) {
    final double steps =
        ((value - _priceBounds.start) / _priceStep).roundToDouble();
    return (_priceBounds.start + steps * _priceStep)
        .clamp(_priceBounds.start, _priceBounds.end)
        .toDouble();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  FilterSelection get _selection => FilterSelection(
        query: _searchController.text,
        brands: _brands,
        sizes: _size == null ? const <String>{} : <String>{_size!},
        condition: _condition,
        minPrice: _price.start.round(),
        maxPrice: _price.end.round(),
        sortBy: _sortBy,
      );

  int get _matchCount => widget.countMatches?.call(_selection) ?? 0;

  void _resetAll() {
    setState(() {
      _searchController.clear();
      _brands = <String>{};
      _size = null;
      _condition = null;
      _price = _priceBounds;
      _sortBy = 'newest';
    });
  }

  void _apply() {
    final FilterSelection selection = _selection;
    widget.onApply?.call(selection);
    Navigator.of(context).pop(selection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const StatusBarRow(),
                  _buildHeader(),
                  _buildSearchField(),
                  _buildBrandsSection(),
                  _buildSizeSection(),
                  _buildPriceSection(),
                  _buildConditionSection(),
                  _buildSortSection(),
                  _buildInfoBanner(),
                ],
              ),
            ),
          ),
          _buildActionBar(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- header ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        children: <Widget>[
          _CircleIconButton(
            icon: Icons.chevron_left,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Filter & Sort',
                style: const TextStyle(
                  fontSize: AppText.headerTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
          _CircleIconButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontSize: AppText.searchField,
            color: AppColors.darkText,
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textMuted,
              size: 20,
            ),
            hintText: 'linen, jacket, neutral...',
            hintStyle: TextStyle(
              color: AppColors.textMuted,
              fontSize: AppText.searchField,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- chips ---

  Widget _buildBrandsSection() {
    return _Section(
      label: 'Brands',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          for (final String brand in _brandOptions)
            _PillChip(
              label: brand,
              isSelected: _brands.contains(brand),
              onSelected: () => setState(() {
                if (!_brands.add(brand)) _brands.remove(brand);
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildSizeSection() {
    return _Section(
      label: 'Size',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          for (final String size in _sizeOptions)
            _PillChip(
              label: size,
              isSelected: _size == size,
              isCircle: true,
              onSelected: () => setState(() => _size = _size == size ? null : size),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return _Section(
      label: 'Price Range',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                _formatShortPrice(_price.start.round()),
                style: const TextStyle(
                  fontSize: AppText.priceLabel,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                _formatShortPrice(_price.end.round()),
                style: const TextStyle(
                  fontSize: AppText.priceLabel,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: AppColors.darkGreen,
              inactiveTrackColor: AppColors.lightBorder,
              thumbColor: AppColors.white,
              overlayColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 11,
                elevation: 1,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: RangeSlider(
              min: _priceBounds.start,
              max: _priceBounds.end,
              divisions: _priceDivisions,
              values: _price,
              labels: RangeLabels(
                _formatShortPrice(_price.start.round()),
                _formatShortPrice(_price.end.round()),
              ),
              onChanged: (RangeValues values) => setState(() => _price = values),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionSection() {
    return _Section(
      label: 'Item Condition',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          for (final String option in _conditionOptions)
            _PillChip(
              label: option,
              isSelected: _condition == option,
              onSelected: () => setState(
                () => _condition = _condition == option ? null : option,
              ),
            ),
        ],
      ),
    );
  }

  /// Sort control — not in the Figma frame, added because the screen is titled
  /// "Filter & Sort". Styled exactly like the other chip groups.
  Widget _buildSortSection() {
    return _Section(
      label: 'Sort',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          for (final (String label, String value) in _sortOptions)
            _PillChip(
              label: label,
              isSelected: _sortBy == value,
              onSelected: () => setState(() => _sortBy = value),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.sageFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.eco_outlined, color: AppColors.darkGreen, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Wider condition filters help good clothes find a second life.',
              style: TextStyle(
                fontSize: AppText.bannerText,
                height: 1.45,
                color: AppColors.darkGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- action bar ---

  Widget _buildActionBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.lightBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: _resetAll,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                side: const BorderSide(color: AppColors.darkGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.darkGreen,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Filters ($_matchCount)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatShortPrice(int value) => 'Rp ${(value / 1000).round()}k';

/// ---------------------------------------------------------------------------
/// Shared pieces (reused by the listing page)
/// ---------------------------------------------------------------------------

/// Mock status bar matching the Figma frame and the other screens in the app.
class StatusBarRow extends StatelessWidget {
  const StatusBarRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const <Widget>[
            Text(
              '9:41',
              style: TextStyle(
                fontSize: AppText.statusBar,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            Row(
              children: <Widget>[
                Icon(Icons.signal_cellular_alt, size: 16, color: AppColors.darkText),
                SizedBox(width: 5),
                Icon(Icons.wifi, size: 16, color: AppColors.darkText),
                SizedBox(width: 5),
                Icon(Icons.battery_full, size: 16, color: AppColors.darkText),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 48x48 circular outlined icon button from the design header.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Icon(icon, size: 22, color: AppColors.darkText),
      ),
    );
  }
}

/// Pill (or circle, for sizes) filter chip.
class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.isCircle = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final Color fill = isSelected ? AppColors.darkGreen : AppColors.white;
    final Color labelColor = isSelected ? AppColors.white : AppColors.darkText;
    final Color borderColor =
        isSelected ? AppColors.darkGreen : AppColors.lightBorder;

    final Text labelText = Text(
      label,
      style: TextStyle(
        fontSize: AppText.chipLabel,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ),
    );

    // Circular size chips are fixed 44x44; pill chips hug their text.
    // NOTE: do not put `alignment` on the pill variant — a Container with
    // alignment expands to the incoming max width, which stretches chips
    // inside a Wrap to full width.
    if (isCircle) {
      return GestureDetector(
        key: ValueKey<String>('chip:$label'),
        onTap: onSelected,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: labelText,
        ),
      );
    }

    return GestureDetector(
      key: ValueKey<String>('chip:$label'),
      onTap: onSelected,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: borderColor),
        ),
        child: labelText,
      ),
    );
  }
}

/// Section label + content with the design's vertical rhythm.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: AppText.sectionLabel,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
