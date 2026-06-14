import 'package:shared_preferences/shared_preferences.dart';

import '../models/store.dart';

/// Single source of truth for all [SharedPreferences] access.
///
/// Centralizes key names and the per-store key composition that used to be
/// duplicated (and inconsistent) across pages. Call [init] once before using
/// the synchronous getters/setters; it is safe to call repeatedly.
class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const _kStoreId = 'storeId';
  static const _kDefaultStoreId = 'defaultStoreId';
  static const _kSelectedStore = 'selectedStore';
  static const _kStores = 'stores';
  static const _kStoresLastFetched = 'storesLastFetched';
  static const _kFilteredStores = 'filteredStores';
  static const _kFavoriteOffers = 'favoriteOffers';
  static const _kSortOffersBy = 'sortOffersBy';
  static const _kFavoriteSortBy = 'favoriteSortBy';
  static const _kDynamicStoreEnabled = 'dynamicStoreEnabled';
  static const _kNotificationsEnabled = 'notificationsEnabled';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // --- Store selection ---------------------------------------------------

  String? get storeId => _prefs.getString(_kStoreId);
  Future<void> setStoreId(String value) => _prefs.setString(_kStoreId, value);

  String? get defaultStoreId => _prefs.getString(_kDefaultStoreId);
  Future<void> setDefaultStoreId(String value) =>
      _prefs.setString(_kDefaultStoreId, value);

  /// The store offers/favorites should be keyed against, with a safe fallback.
  String get effectiveStoreId =>
      storeId ?? defaultStoreId ?? Store.fallback.storeId;

  String? get selectedStoreJson => _prefs.getString(_kSelectedStore);
  Future<void> setSelectedStoreJson(String value) =>
      _prefs.setString(_kSelectedStore, value);

  // --- Store catalog -----------------------------------------------------

  String? get storesJson => _prefs.getString(_kStores);
  Future<void> setStoresJson(String value) => _prefs.setString(_kStores, value);

  String? get storesLastFetched => _prefs.getString(_kStoresLastFetched);
  Future<void> setStoresLastFetched(String value) =>
      _prefs.setString(_kStoresLastFetched, value);

  String? get filteredStoresJson => _prefs.getString(_kFilteredStores);
  Future<void> setFilteredStoresJson(String value) =>
      _prefs.setString(_kFilteredStores, value);

  // --- Offers cache (keyed per store) ------------------------------------

  String? offersJson(String storeId) => _prefs.getString('offersFinal$storeId');
  Future<void> setOffersJson(String storeId, String value) =>
      _prefs.setString('offersFinal$storeId', value);

  String? offersDate(String storeId) => _prefs.getString('offersDate$storeId');
  Future<void> setOffersDate(String storeId, String value) =>
      _prefs.setString('offersDate$storeId', value);

  // --- Favorites ---------------------------------------------------------

  String? get favoriteOffersJson => _prefs.getString(_kFavoriteOffers);
  Future<void> setFavoriteOffersJson(String value) =>
      _prefs.setString(_kFavoriteOffers, value);

  // --- Preferences -------------------------------------------------------

  String get sortOffersBy => _prefs.getString(_kSortOffersBy) ?? 'category';
  Future<void> setSortOffersBy(String value) =>
      _prefs.setString(_kSortOffersBy, value);

  String get favoriteSortBy => _prefs.getString(_kFavoriteSortBy) ?? 'category';
  Future<void> setFavoriteSortBy(String value) =>
      _prefs.setString(_kFavoriteSortBy, value);

  bool get dynamicStoreEnabled => _prefs.getBool(_kDynamicStoreEnabled) ?? false;
  Future<void> setDynamicStoreEnabled(bool value) =>
      _prefs.setBool(_kDynamicStoreEnabled, value);

  bool get notificationsEnabled => _prefs.getBool(_kNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_kNotificationsEnabled, value);
}
