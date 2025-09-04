/// Search Store Screen
/// 
/// This file implements a search interface for Kaufland stores, allowing users
/// to quickly find and select a store by name. The selected store becomes
/// the active store for viewing offers and is persisted between sessions.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kaufi_alert_v2/pages/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SearchStore widget provides a search interface for finding stores
/// 
/// Uses Flutter's SearchAnchor widget to create a modern search experience
/// with suggestions that appear as the user types
class SearchStore extends StatefulWidget {
  const SearchStore({super.key});

  @override
  State<SearchStore> createState() => _SearchStoreState();
}

class _SearchStoreState extends State<SearchStore> {
  /// SharedPreferences instance for data persistence
  late SharedPreferences prefs;
  
  /// Initialize SharedPreferences instance
  /// 
  /// This provides access to locally stored data, including the list of stores
  Future<void> initializeSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    // Load store data when the widget initializes
    fetchStores();
  }

  @override
  void dispose() {
    // Clean up resources when the widget is removed
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
        // Style the search results view
        viewBackgroundColor: const Color(0xFF412a2b),
        headerTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        // Add back button to search results view
        viewLeading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () {
          Navigator.pop(context);
          FocusScope.of(context).unfocus();
        }),
          // Build the search bar UI
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
                // Open search results view when tapped
                controller.openView();
              },
              onChanged: (_) {
                // Show suggestions as user types
                controller.openView();
              },
              onTapOutside: (_) {
                // Hide keyboard when tapping outside
                FocusScope.of(context).unfocus();
              },
              leading: Icon(Icons.search, color: Colors.white),
            ),
          );
          },
        // Build search suggestions based on user input
        suggestionsBuilder: (context, controller) async {
          List<ListTile> listTiles = [];
          
          // Load filtered stores from local storage
          List<Store> stores = prefs.getString('filteredStores') != null
            ? (json.decode(prefs.getString('filteredStores')!) as List)
                .map((store) => Store.fromJson(store))
                .toList()
            : [];

          // Filter stores based on search text
          final suggestedStores = stores.where((store) {
            if (controller.text.isEmpty) {
              return false; // Don't show suggestions for empty search
            }
            return store.name.toLowerCase().contains(controller.text.toLowerCase());
          }).toList();
          
          // Create a list tile for each matching store
          for(var store in suggestedStores) {
            listTiles.add(ListTile(
              title: Text(
                store.name,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                // Get the navigator before async operations to avoid context issues
                final navigator = Navigator.of(context);
                
                // Save the selected store to preferences
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

  /// Initializes the component by loading store data
  /// 
  /// This ensures SharedPreferences is initialized before attempting
  /// to access store data. Further store data loading logic could be added here.
  void fetchStores() async {
    await initializeSharedPreferences();
  }
}