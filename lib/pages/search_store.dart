import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kaufi_allert_v2/pages/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchStore extends StatefulWidget {
  const SearchStore({super.key});

  @override
  State<SearchStore> createState() => _SearchStoreState();
}

class _SearchStoreState extends State<SearchStore> {

  late SharedPreferences prefs;
  Future<void> initializeSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    fetchStores();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Store", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1f1415),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SearchAnchor(
        viewBackgroundColor: const Color(0xFF412a2b),
        headerTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        viewLeading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () {
          Navigator.pop(context);
          FocusScope.of(context).unfocus();
        }),
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
              textStyle: WidgetStateProperty.all(const TextStyle(color: Colors.white)),
              onTap: () {
                controller.openView();
              },
              onChanged: (_) {
                controller.openView();
              },
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              leading: Icon(Icons.search, color: Colors.white),
            ),
          );
          },
        suggestionsBuilder: (context, controller) async {
          List<ListTile> listTiles = [];
          List<Store> stores = prefs.getString('filteredStores') != null
            ? (json.decode(prefs.getString('filteredStores')!) as List)
                .map((store) => Store.fromJson(store))
                .toList()
            : [];

          final suggestedStores = stores.where((store) {
            if (controller.text.isEmpty) {
              return false;
            }
            return store.name.toLowerCase().contains(controller.text.toLowerCase());
          }).toList();
          for(var store in suggestedStores) {
            listTiles.add(ListTile(
              title: Text(
                store.name,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                
                await prefs.setString('selectedStore', json.encode(store));
                await prefs.setString('storeId', store.storeId);
                
                if (mounted) {
                  controller.closeView(null); // Close the search view first
                  navigator.pop(); // Close the search screen
                  navigator.pop(store); // Return to previous screen with store data
                }
              },
            ));
          }
          return listTiles;
        },
      ),
    );
  }

  void fetchStores() async {
    await initializeSharedPreferences();
  }
}