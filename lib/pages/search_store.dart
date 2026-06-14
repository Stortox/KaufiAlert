/// Search Store Screen
///
/// Search interface for finding and selecting a Kaufland store by name.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/store.dart';
import '../services/preferences_service.dart';
import '../services/store_repository.dart';

class SearchStore extends StatefulWidget {
  const SearchStore({super.key});

  @override
  State<SearchStore> createState() => _SearchStoreState();
}

class _SearchStoreState extends State<SearchStore> {
  final _prefs = PreferencesService.instance;

  /// Loaded once instead of decoding the JSON on every keystroke.
  List<Store> _stores = [];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    await _prefs.init();
    final raw = _prefs.filteredStoresJson;
    if (raw == null || raw.isEmpty) return;
    final stores =
        (json.decode(raw) as List).map((e) => Store.fromJson(e)).toList();
    if (!mounted) return;
    setState(() => _stores = stores);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Search Store",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1f1415),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SearchAnchor(
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
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: SearchBar(
              controller: controller,
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0),
              ),
              hintText: 'Search',
              backgroundColor: WidgetStateProperty.all(const Color(0xFF412a2b)),
              textStyle: WidgetStateProperty.all(
                const TextStyle(color: Colors.white),
              ),
              onTap: controller.openView,
              onChanged: (_) => controller.openView(),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              leading: const Icon(Icons.search, color: Colors.white),
            ),
          );
        },
        suggestionsBuilder: (context, controller) {
          final query = controller.text.toLowerCase();
          if (query.isEmpty) return const <ListTile>[];
          return _stores
              .where((store) => store.name.toLowerCase().contains(query))
              .map(
                (store) => ListTile(
                  title: Text(
                    store.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await StoreRepository.instance.selectStore(store);
                    if (!mounted) return;
                    controller.closeView(null);
                    navigator.pop();
                    navigator.pop(store);
                  },
                ),
              )
              .toList();
        },
      ),
    );
  }
}
