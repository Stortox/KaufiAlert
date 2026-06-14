import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/store.dart';
import 'preferences_service.dart';

/// Owns everything about Kaufland stores: the cached catalog, fetching it from
/// the API, distance-based selection and the user's chosen store.
class StoreRepository {
  StoreRepository._();
  static final StoreRepository instance = StoreRepository._();

  final PreferencesService _prefs = PreferencesService.instance;

  static const Map<String, String> _authHeader = {
    'Authorization': 'Basic S0lTLUtMQVBQOkRyZWNrc3pldWdfMzUyOS1BY2h0c3BubmVy',
  };

  /// All stores currently held in the local cache.
  List<Store> cachedStores() {
    final raw = _prefs.storesJson;
    if (raw == null || raw.isEmpty) return [];
    final list = json.decode(raw) as List;
    return list
        .map((e) => Store.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Re-downloads the catalog if it is missing or older than 7 days.
  Future<void> refreshStoresIfStale() async {
    await _prefs.init();
    final last = _prefs.storesLastFetched;
    final stale = last == null ||
        DateTime.now().difference(DateTime.parse(last)).inDays > 7;
    if (stale) await refreshStores();
  }

  /// Downloads the store catalog and persists it.
  Future<void> refreshStores() async {
    await _prefs.init();
    await _fetchStoresFromApi();
    if ((_prefs.storeId ?? '').isEmpty) {
      await _prefs.setStoreId(
        _prefs.defaultStoreId ?? Store.fallback.storeId,
      );
    }
    await _prefs.setStoresLastFetched(DateTime.now().toIso8601String());
  }

  Future<void> _fetchStoresFromApi() async {
    final response = await http.get(
      Uri.https('app.kaufland.net', '/data/api/v2/stores'),
      headers: _authHeader,
    );
    final storeList = json.decode(response.body) as List;
    final stores = <Store>[];

    for (final data in storeList) {
      final hasName = (data['name'] ?? '').toString().isNotEmpty;
      final lat = data['latitude'];
      final lon = data['longitude'];
      final hasCoordinates =
          lat != null && lat != 0 && lon != null && lon != 0;
      if (!hasName || !hasCoordinates) continue;

      stores.add(
        Store(
          storeId: data['storeId'] ?? '',
          name: data['name'],
          address: "${data['street']}, ${data['city']}",
          openingHours: _formatOpeningHours(data['openingHours']),
          position: [(lat as num).toDouble(), (lon as num).toDouble()],
          country: data['country'] ?? '',
        ),
      );

      // Seed the default store from the reference Dresden location.
      if (lat == 51.044094 &&
          lon == 13.7812778 &&
          (_prefs.defaultStoreId ?? '').isEmpty) {
        await _prefs.setDefaultStoreId(data['storeId']);
      }
    }

    await _prefs.setStoresJson(
      json.encode(stores.map((s) => s.toJson()).toList()),
    );
  }

  static String _formatOpeningHours(dynamic openingHours) {
    if (openingHours is! List) return '';
    final parts = <String>[];
    for (final hour in openingHours) {
      final int open = hour['open'];
      final int close = hour['close'];
      String fmt(int t) => "${t ~/ 100}:${t % 100 == 0 ? '00' : t % 100}";
      parts.add("${hour['weekday']}: ${fmt(open)}-${fmt(close)}");
    }
    return parts.join(', ');
  }

  /// The stores nearest [position], in the user's country.
  ///
  /// When [excludeCurrent] is true the currently selected store is omitted
  /// (used for the "nearby stores" list); when false it is kept (used when
  /// auto-resolving the nearest store).
  List<Store> closestStores(
    Position position, {
    int limit = 3,
    bool excludeCurrent = true,
  }) {
    final country =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    final stores = cachedStores()
        .where((s) =>
            s.country == country &&
            (!excludeCurrent || s.storeId != _prefs.storeId))
        .toList();
    stores.sort((a, b) => a
        .getDistance(position.latitude, position.longitude)
        .compareTo(b.getDistance(position.latitude, position.longitude)));
    return stores.take(limit).toList();
  }

  /// The user's currently selected store, falling back to the default.
  Future<Store> selectedStore() async {
    await _prefs.init();
    final raw = _prefs.selectedStoreJson;
    if (raw != null && raw.isNotEmpty) {
      return Store.fromJson(json.decode(raw));
    }
    await selectStore(Store.fallback);
    return Store.fallback;
  }

  /// Persists [store] as the active store.
  Future<void> selectStore(Store store) async {
    await _prefs.init();
    await _prefs.setSelectedStoreJson(json.encode(store.toJson()));
    await _prefs.setStoreId(store.storeId);
  }

  /// Resolves and persists the nearest store to [position]. Returns null when
  /// no store can be determined.
  Future<Store?> resolveNearestStore(Position position) async {
    final nearest =
        closestStores(position, limit: 1, excludeCurrent: false);
    if (nearest.isEmpty) return null;
    await selectStore(nearest.first);
    return nearest.first;
  }
}
