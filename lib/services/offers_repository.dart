import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/favourite_product.dart';
import '../models/filter_type.dart';
import '../models/product.dart';
import 'location_service.dart';
import 'preferences_service.dart';
import 'store_repository.dart';

/// Owns offer fetching/caching and the favorites list.
class OffersRepository {
  OffersRepository._();
  static final OffersRepository instance = OffersRepository._();

  final PreferencesService _prefs = PreferencesService.instance;

  static const Map<String, String> _authHeader = {
    'Authorization': 'Basic S0lTLUtMQVBQOkRyZWNrc3pldWdfMzUyOS1BY2h0c3BubmVy',
  };

  /// Kaufland category keys we surface, in the same order as [FilterType]
  /// (index `i` here maps to `FilterType.values[i + 1]`).
  static const List<String> _categoryKeys = [
    '02_Obst__Gemuese__Pflanzen',
    '01_Fleisch__Gefluegel__Wurst',
    '01a_Frischer_Fisch',
    '03_Molkereiprodukte__Fette',
    '04_Tiefkuehlkost',
    '05_Feinkost__Konserven',
    '06_Grundnahrungsmittel',
    '07_Kaffee__Tee__Suesswaren__Knabberartikel',
    '08_Getraenke__Spirituosen',
    '708_Backshop',
    '562_Bio',
  ];

  /// Loads offers for the active store: applies the dynamic store if enabled,
  /// refreshes the store catalog weekly, then returns fresh cached offers or
  /// fetches from the API.
  Future<List<Product>> loadOffers() async {
    await _prefs.init();

    if (_prefs.dynamicStoreEnabled) {
      final position = await LocationService.currentPosition();
      if (position != null) {
        await StoreRepository.instance.resolveNearestStore(position);
      }
    }

    await StoreRepository.instance.refreshStoresIfStale();

    final storeId = _prefs.effectiveStoreId;
    final cached = cachedOffers();
    final offersDate = _prefs.offersDate(storeId);
    final fresh = offersDate != null &&
        DateTime.now().difference(DateTime.parse(offersDate)).inDays < 7;
    if (cached.isNotEmpty && fresh) return cached;

    return fetchOffers();
  }

  /// Offers cached for the active store.
  List<Product> cachedOffers() {
    final raw = _prefs.offersJson(_prefs.effectiveStoreId);
    if (raw == null) return [];
    return (json.decode(raw) as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches offers from the API, persists them, and returns the result.
  Future<List<Product>> fetchOffers() async {
    final storeId = _prefs.effectiveStoreId;
    final response = await http.get(
      Uri.https('app.kaufland.net', '/data/api/v5/offers/$storeId'),
      headers: _authHeader,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load offers');
    }

    final root = jsonDecode(response.body) as List;
    final categories = root[0]['categories'] as List;

    await _prefs.setOffersDate(
      storeId,
      DateTime.parse(categories[0]['dateFrom']).toIso8601String(),
    );

    // Index category keys for O(1) lookup instead of a nested scan.
    final categoryIndex = {
      for (var i = 0; i < _categoryKeys.length; i++) _categoryKeys[i]: i,
    };

    final offers = <Product>{}; // Set de-dupes via Product ==/hashCode.
    for (final category in categories) {
      final key = category['name'];
      final keyIndex = categoryIndex[key];
      if (keyIndex == null) continue;

      final categoryName = FilterType.values[keyIndex + 1].name;
      final isProduce = key == _categoryKeys.first;

      for (final offer in category['offers']) {
        final discount = offer['discount'];
        if (discount == null || (discount <= 0 && !isProduce)) continue;

        final title =
            '${offer['title'] ?? ''} ${offer['subtitle'] ?? ''}'
                .replaceAll('/', ' ')
                .trim();
        offers.add(
          Product(
            title: title,
            price: "${offer['formattedPrice'] ?? '0.00'}€",
            discount: '$discount%',
            basePrice: offer['basePrice'] ?? '',
            oldPrice: "${offer['oldPrice'] ?? '0.00'}€",
            imageUrl: offer['listImage'] ?? 'https://picsum.photos/250?image=9',
            description: offer['detailDescription'] ?? '',
            category: categoryName,
            unit: offer['unit'] ?? '',
            gtin: offer['GTIN'] ?? '',
          ),
        );
      }
    }

    final result = offers.toList();
    await _prefs.setOffersJson(
      storeId,
      json.encode(result.map((p) => p.toJson()).toList()),
    );
    return result;
  }

  // --- Favorites ---------------------------------------------------------

  /// The user's saved favorites (without availability info).
  List<Product> favorites() {
    final raw = _prefs.favoriteOffersJson;
    if (raw == null || raw.isEmpty) return [];
    return (json.decode(raw) as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFavorites(List<Product> favorites) =>
      _prefs.setFavoriteOffersJson(
        json.encode(favorites.map((p) => p.toJson()).toList()),
      );

  /// Favorites annotated with whether they are still in the current store's
  /// cached offers.
  List<FavouriteProduct> favoritesWithAvailability() {
    final cached = cachedOffers().toSet();
    return favorites()
        .map((p) =>
            FavouriteProduct.fromProduct(p, available: cached.contains(p)))
        .toList();
  }
}
