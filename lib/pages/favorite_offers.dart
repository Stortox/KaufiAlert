/// Favorite Offers screen.
///
/// Displays the user's saved favorites in a grid, annotated with whether each
/// is still available in the currently selected store.
library;

import 'package:flutter/material.dart';

import '../models/favourite_product.dart';
import '../models/filter_type.dart';
import '../services/offers_repository.dart';
import '../services/preferences_service.dart';
import '../widgets/offer_card.dart';

class FavoriteOffers extends StatefulWidget {
  const FavoriteOffers({super.key});

  @override
  State<FavoriteOffers> createState() => FavoriteOffersState();
}

class FavoriteOffersState extends State<FavoriteOffers> {
  final _prefs = PreferencesService.instance;

  final List<Map<String, String>> sortOptions = const [
    {'label': 'Category', 'value': 'category'},
    {'label': 'Price (low to high)', 'value': 'priceLow'},
    {'label': 'Price (high to low)', 'value': 'priceHigh'},
    {'label': 'Highest discount', 'value': 'discount'},
    {'label': 'Available first', 'value': 'available'},
  ];

  List<FavouriteProduct> _favorites = [];
  List<FavouriteProduct> _visible = [];
  final Map<FilterType, List<FavouriteProduct>> _byCategory = {};

  FilterType _filter = FilterType.all;
  String _sortKey = 'category';
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// (Re)loads favorites. Public so the host can refresh on tab focus, since
  /// favorites change on the detail screen and availability depends on the
  /// active store.
  Future<void> reload() async {
    await _prefs.init();
    final favorites = OffersRepository.instance.favoritesWithAvailability();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _sortKey = _prefs.favoriteSortBy;
      _byCategory.clear();
      _recompute();
    });
  }

  void _recompute() {
    List<FavouriteProduct> list;
    if (_filter == FilterType.all) {
      list = List.of(_favorites);
    } else {
      final cached = _byCategory[_filter] ??=
          _favorites.where((p) => p.category == _filter.name).toList();
      list = List.of(cached);
    }
    _sortInPlace(list);
    _visible = list;
  }

  void _sortInPlace(List<FavouriteProduct> list) {
    switch (_sortKey) {
      case 'category':
        list.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'priceLow':
        list.sort((a, b) => a.priceValue.compareTo(b.priceValue));
        break;
      case 'priceHigh':
        list.sort((a, b) => b.priceValue.compareTo(a.priceValue));
        break;
      case 'discount':
        list.sort((a, b) => b.discountValue.compareTo(a.discountValue));
        break;
      case 'available':
        list.sort((a, b) => (b.stillAvailable ? 1 : 0)
            .compareTo(a.stillAvailable ? 1 : 0));
        break;
    }
  }

  void _onFilterSelected(FilterType filter) {
    setState(() {
      _filter = filter;
      _recompute();
    });
  }

  Future<void> _onSortSelected(String value) async {
    await _prefs.setFavoriteSortBy(value);
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
          "Favorite Offers",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1f1415),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            if (_favorites.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80.0),
                child: Text(
                  "No favorite offers found",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () =>
                    setState(() => _filtersExpanded = !_filtersExpanded),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "Filters",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Icon(
                      _filtersExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              if (_filtersExpanded) ...[
                const SizedBox(height: 8.0),
                _buildSectionLabel("Categories"),
                _buildCategoryChips(),
                _buildSectionLabel("Sort Offers By"),
                _buildSortChips(),
              ],
            ],
            const SizedBox(height: 8.0),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: _visible.length,
                itemBuilder: (context, index) {
                  final product = _visible[index];
                  return OfferCard(
                    product: product,
                    available: product.stillAvailable,
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
