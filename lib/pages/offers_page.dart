import 'package:flutter/material.dart';

import '../models/filter_type.dart';
import '../models/product.dart';
import '../services/offers_repository.dart';
import '../services/preferences_service.dart';
import '../widgets/offer_card.dart';
import 'offer_detail.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => OffersPageState();
}

class OffersPageState extends State<OffersPage> {
  final _prefs = PreferencesService.instance;

  final List<Map<String, String>> sortOptions = const [
    {'value': 'category', 'label': 'Category'},
    {'value': 'priceLowToHigh', 'label': 'Price: Low to High'},
    {'value': 'priceHighToLow', 'label': 'Price: High to Low'},
    {'value': 'discountLowToHigh', 'label': 'Discount: Low to High'},
    {'value': 'discountHighToLow', 'label': 'Discount: High to Low'},
    {'value': 'nameAZ', 'label': 'Name: A-Z'},
    {'value': 'nameZA', 'label': 'Name: Z-A'},
  ];

  /// All products in their default (category) order.
  List<Product> _allProducts = [];

  /// Products currently shown (filtered + sorted).
  List<Product> _visible = [];

  /// Category lists cached pre-sort, so sorting never mutates the cache.
  final Map<FilterType, List<Product>> _byCategory = {};

  FilterType _filter = FilterType.all;
  String _sortKey = 'category';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// (Re)loads offers. Public so the host can refresh on tab focus, e.g. after
  /// the selected store changed in Settings.
  Future<void> reload() async {
    final loaded = await OffersRepository.instance.loadOffers();
    if (!mounted) return;
    setState(() {
      _allProducts = loaded;
      _sortKey = _prefs.sortOffersBy;
      _byCategory.clear();
      _loading = false;
      _recompute();
    });
  }

  void _recompute() {
    List<Product> list;
    if (_filter == FilterType.all) {
      list = List.of(_allProducts);
    } else {
      final cached = _byCategory[_filter] ??=
          _allProducts.where((p) => p.category == _filter.name).toList();
      list = List.of(cached);
    }
    _sortInPlace(list);
    _visible = list;
  }

  void _sortInPlace(List<Product> list) {
    switch (_sortKey) {
      case 'nameAZ':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'nameZA':
        list.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'priceLowToHigh':
        list.sort((a, b) => a.priceValue.compareTo(b.priceValue));
        break;
      case 'priceHighToLow':
        list.sort((a, b) => b.priceValue.compareTo(a.priceValue));
        break;
      case 'discountHighToLow':
        list.sort((a, b) => b.discountValue.compareTo(a.discountValue));
        break;
      case 'discountLowToHigh':
        list.sort((a, b) => a.discountValue.compareTo(b.discountValue));
        break;
      case 'category':
      default:
        break; // keep default category order
    }
  }

  void _onFilterSelected(FilterType filter) {
    setState(() {
      _filter = filter;
      _recompute();
    });
  }

  Future<void> _onSortSelected(String value) async {
    await _prefs.setSortOffersBy(value);
    if (!mounted) return;
    setState(() {
      _sortKey = value;
      _recompute();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1f1415),
      appBar: AppBar(
        title: const Text(
          "Offers",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: const Color(0xFF1f1415),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildSearchRow(context),
            if (_filtersExpanded) ...[
              const SizedBox(height: 8.0),
              _buildSectionLabel("Categories"),
              _buildCategoryChips(),
              _buildSectionLabel("Sort Offers By"),
              _buildSortChips(),
            ],
            const SizedBox(height: 8.0),
            if (_loading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _visible.length,
                  itemBuilder: (context, index) =>
                      OfferCard(product: _visible[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _filtersExpanded = false;

  Widget _buildSearchRow(BuildContext context) {
    return Row(
      children: [
        SearchAnchor(
          viewBackgroundColor: const Color(0xFF412a2b),
          headerTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
          viewLeading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              FocusScope.of(context).unfocus();
            },
          ),
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SearchBar(
                controller: controller,
                padding: const WidgetStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 16.0),
                ),
                hintText: 'Search',
                backgroundColor: WidgetStateProperty.all(
                  const Color(0xFF412a2b),
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(color: Colors.white),
                ),
                onTap: controller.openView,
                onChanged: (_) => controller.openView(),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                leading: const Icon(Icons.search, color: Colors.white),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                  minHeight: 55,
                ),
              ),
            );
          },
          suggestionsBuilder: (context, controller) {
            final query = controller.text.toLowerCase();
            if (query.isEmpty) return const <ListTile>[];
            return _allProducts
                .where((p) => p.title.toLowerCase().contains(query))
                .map(
                  (product) => ListTile(
                    title: Text(
                      product.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OfferDetail(product: product),
                      ),
                    ),
                  ),
                )
                .toList();
          },
        ),
        const SizedBox(width: 4.0),
        GestureDetector(
          onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
          child: Row(
            children: [
              const Text(
                "Filters",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Icon(
                _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          for (final entry in kCategoryFilters) ...[
            _buildChip(
              label: entry.label,
              selected: _filter == entry.type,
              onSelected: () => _onFilterSelected(entry.type),
            ),
            const SizedBox(width: 8.0),
          ],
        ],
      ),
    );
  }

  Widget _buildSortChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          for (final option in sortOptions)
            // Hide the "Category" sort when a specific category is selected.
            if (!(_filter != FilterType.all && option['value'] == 'category'))
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildChip(
                  label: option['label']!,
                  selected: _sortKey == option['value'],
                  onSelected: () => _onSortSelected(option['value']!),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onSelected: (value) {
        if (value) onSelected();
      },
      backgroundColor: const Color(0xFF412a2b),
      selectedColor: const Color.fromARGB(255, 120, 80, 80),
      checkmarkColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Colors.black, width: 0),
      ),
    );
  }
}
