/// Store Selection Screen
///
/// Lets users find nearby Kaufland stores, search by name, and toggle
/// automatic location-based store selection.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kaufi_alert_v2/pages/search_store.dart';

import '../models/store.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';
import '../services/store_repository.dart';
import '../widgets/store_tile.dart';

class SelectStore extends StatefulWidget {
  const SelectStore({super.key});

  @override
  State<SelectStore> createState() => _SelectStoreState();
}

class _SelectStoreState extends State<SelectStore> {
  final _prefs = PreferencesService.instance;
  final _stores = StoreRepository.instance;

  Position? _userPosition;
  List<Store> _closestStores = [];
  bool _loading = true;

  bool _isExplanationVisible = false;
  bool _dynamicStoreEnabled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Acquires the location once and derives the nearby stores from it, instead
  /// of repeatedly re-acquiring GPS as the previous FutureBuilder did.
  Future<void> _init() async {
    await _prefs.init();
    final position = await LocationService.currentPosition();
    final closest =
        position == null ? <Store>[] : _stores.closestStores(position);
    if (!mounted) return;
    setState(() {
      _userPosition = position;
      _closestStores = closest;
      _dynamicStoreEnabled = _prefs.dynamicStoreEnabled;
      _loading = false;
    });
  }

  Future<void> _openSearch() async {
    // Persist the candidate stores for the search screen.
    await _prefs.setFilteredStoresJson(
      json.encode(_stores.cachedStores().map((s) => s.toJson()).toList()),
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchStore()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasStores = _stores.cachedStores().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Store',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1f1415),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Choose your preferred store",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: const Text(
                          "Use current location",
                          style: TextStyle(color: Colors.white),
                        ),
                        leading: _iconBox(Icons.location_on_outlined),
                        trailing: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                        ),
                        onTap: () => setState(
                          () => _isExplanationVisible = !_isExplanationVisible,
                        ),
                      ),
                    ),
                    if (_isExplanationVisible)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                "Use your current location to automatically find the nearest store. Only available in supported areas.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Switch(
                              value: _dynamicStoreEnabled,
                              onChanged: (value) {
                                setState(() => _dynamicStoreEnabled = value);
                                _prefs.setDynamicStoreEnabled(value);
                              },
                              activeThumbColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(
                      "Search for a store",
                      style: TextStyle(
                        color: hasStores ? Colors.white : Colors.grey,
                      ),
                    ),
                    leading: _iconBox(Icons.search),
                    onTap: hasStores ? _openSearch : null,
                    enabled: hasStores,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nearby stores",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildNearbyStores(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyStores(BuildContext context) {
    if (_loading) return const CircularProgressIndicator();
    if (_closestStores.isEmpty) {
      return const Text(
        'No stores found',
        style: TextStyle(color: Colors.white),
      );
    }
    return SizedBox(
      width: MediaQuery.of(context).size.width - 10,
      height: MediaQuery.of(context).size.height - 400,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _closestStores.length,
        itemBuilder: (context, index) {
          final store = _closestStores[index];
          return StoreTile(
            store: store,
            userPosition: _userPosition,
            onTap: () async {
              await _stores.selectStore(store);
              if (context.mounted) Navigator.pop(context, store);
            },
          );
        },
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF412a2b),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Colors.white),
    );
  }
}
