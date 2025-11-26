/// Store Selection Screen
///
/// This file implements the store selection interface where users can:
/// - Find nearby Kaufland stores based on their current location
/// - Search for stores by name
/// - Toggle automatic store selection based on location
/// - View store details including distance, address and opening hours
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kaufi_alert_v2/pages/search_store.dart';
import 'package:kaufi_alert_v2/pages/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SelectStore widget displays options for selecting a Kaufland store
///
/// Presents users with nearby stores based on their location and
/// provides tools to search for specific stores by name
class SelectStore extends StatefulWidget {
  const SelectStore({super.key});

  @override
  State<SelectStore> createState() => _SelectStoreState();
}

class _SelectStoreState extends State<SelectStore> {
  /// List of all available stores loaded from cache
  List<Store> stores = [];

  /// Filtered list of stores to display in search results
  List<Store> filteredStores = [];

  /// Flag to control visibility of the location explanation panel
  bool isExplanationVisible = false;

  /// Flag to track whether automatic location-based store selection is enabled
  bool useCurrentLocation = false;

  /// Current user's geographical position for distance calculations
  Position userPosition = Position(
    latitude: 0.0,
    longitude: 0.0,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    heading: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );

  /// Default store used when no store has been selected yet
  Store selectedStore = Store(
    storeId: 'DE3283',
    name: 'Kaufland Dresden-Striesen-West',
    address: 'Borsbergstraße 35, Dresden',
    openingHours:
        'Mon: 09:00-20:00, Tue: 09:00-20:00, Wed: 09:00-20:00, Thu: 09:00-20:00, Fri: 09:00-20:00, Sat: 09:00-20:00, Sun: 0:00-0:00',
    position: [13.7812778, 51.044094],
    country: 'DE',
  );

  /// SharedPreferences instance for data persistence
  late SharedPreferences prefs;

  /// Initialize SharedPreferences instance for storing user preferences
  Future<void> initializeSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    // Get user location when screen initializes
    getUserPosition().then((position) {
      if (mounted) {
        setState(() {
          userPosition = position;
        });
      }
    });
    // Load store data and prepare the filtered list
    getClosestStores().then((_) {
      if (mounted) {
        setState(() {
          filteredStores = stores;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            // Section header for store selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                    // Location-based store selection option
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: const Text(
                          "Use current location",
                          style: TextStyle(color: Colors.white),
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF412a2b),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                        ),
                        onTap: () {
                          // Toggle explanation visibility when tapped
                          setState(() {
                            isExplanationVisible = !isExplanationVisible;
                          });
                        },
                      ),
                    ),
                    // Expandable explanation section with toggle switch
                    if (isExplanationVisible)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "Use your current location to automatically find the nearest store. Only available in supported areas.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            // Toggle switch for enabling/disabling automatic store selection
                            Switch(
                              value:
                                  prefs.getBool('dynamicStoreEnabled') ?? false,
                              onChanged: (value) {
                                setState(() {
                                  useCurrentLocation = value;
                                });
                                // Save user preference
                                prefs.setBool('dynamicStoreEnabled', value);
                              },
                              activeThumbColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                // Store search option
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(
                      "Search for a store",
                      style: TextStyle(
                        color: filteredStores.isNotEmpty
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF412a2b,
                        ), // Background color for the icon
                        borderRadius: BorderRadius.circular(
                          8,
                        ), // Rounded corners
                      ),
                      padding: const EdgeInsets.all(
                        8,
                      ), // Padding inside the container
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                    onTap: () => {
                      // Save filtered stores to preferences for search screen
                      prefs.setString(
                        'filteredStores',
                        json.encode(filteredStores),
                      ),
                      // Navigate to search screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SearchStore()),
                      ),
                    },
                    // Disable search if no stores are available
                    enabled: filteredStores.isNotEmpty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Section header for nearby stores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
            // Display loading indicator or nearby stores list
            userPosition.latitude == 0.0 && userPosition.longitude == 0.0
                ? const CircularProgressIndicator()
                : FutureBuilder<List<Store>>(
                    future: getClosestStores(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.white),
                        );
                      } else {
                        if (snapshot.data == null || snapshot.data!.isEmpty) {
                          return const Text(
                            'No stores found',
                            style: TextStyle(color: Colors.white),
                          );
                        } else {
                          // List of nearby stores with distance information
                          return SizedBox(
                            width: MediaQuery.of(context).size.width - 10,
                            height: MediaQuery.of(context).size.height - 400,
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                Store store = snapshot.data![index];
                                return buildStoreTile(
                                  store,
                                  userPosition,
                                  context,
                                  prefs,
                                );
                              },
                            ),
                          );
                        }
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  /// Retrieves the user's current geographic position
  ///
  /// Handles location permission requests and service availability checks.
  /// Returns a default position if location services are unavailable.
  Future<Position> getUserPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.deniedForever) {
      if (serviceEnabled) {
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        } else if (permission != LocationPermission.denied) {
          try {
            return await Geolocator.getCurrentPosition(
              locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );
          } catch (e) {
            print("Error getting user position: $e");
          }
        }
      }
    }
    // Return default position if unable to get location
    return Position(
      latitude: 0.0,
      longitude: 0.0,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  /// Gets the closest stores to the user's current location
  ///
  /// Loads stores from cache, sorts them by distance to user,
  /// and returns the three closest stores in the user's country.
  Future<List<Store>> getClosestStores() async {
    await initializeSharedPreferences();
    String? cachedData = prefs.getString('stores');
    if (cachedData != null && cachedData.isNotEmpty) {
      // Parse store data from cache
      List<dynamic> jsonList = json.decode(cachedData);
      stores = jsonList.map((json) => Store.fromJson(json)).toList();

      // Default position in case location services are unavailable
      Position position = Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        heading: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      // Try to get the user's current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.deniedForever) {
        if (serviceEnabled) {
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          } else if (permission != LocationPermission.denied) {
            try {
              position = await Geolocator.getCurrentPosition(
                locationSettings: LocationSettings(
                  accuracy: LocationAccuracy.high,
                ),
              );
            } catch (e) {
              print("Error getting user position: $e");
            }
          }
        }
      }

      // Use the position to sort stores by distance
      double userLatitude = position.latitude;
      double userLongitude = position.longitude;

      // Filter stores to only include those in user's country and not the currently selected store
      List<Store> localStores = List<Store>.from(stores)
          .where(
            (store) =>
                store.country ==
                    WidgetsBinding
                        .instance
                        .platformDispatcher
                        .locale
                        .countryCode &&
                store.storeId != prefs.getString('storeId'),
          )
          .toList();

      // Sort by distance (closest first)
      localStores.sort((a, b) {
        double distanceA = a.getDistance(userLatitude, userLongitude);
        double distanceB = b.getDistance(userLatitude, userLongitude);
        return distanceA.compareTo(distanceB);
      });

      // Return the 3 closest stores
      return localStores.take(3).toList();
    }
    return [];
  }
}

/// Builds a ListTile widget to display store information
///
/// Creates a tappable store item showing name, address, distance from user,
/// and today's opening hours. Selecting a store saves it as the active store.
Widget buildStoreTile(
  Store store,
  Position? userPosition,
  BuildContext context,
  SharedPreferences prefs,
) {
  return GestureDetector(
    onTap: () async {
      // Save selected store to preferences when tapped
      await prefs.setString('selectedStore', json.encode(store));
      await prefs.setString('storeId', store.storeId);
      // Return to previous screen with selected store
      Navigator.pop(context, store);
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          store.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Store address with overflow handling
                SizedBox(
                  width: MediaQuery.of(context).size.width - 200,
                  child: Text(
                    store.address,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Distance from user's location
                userPosition != null
                    ? Text(
                        "${store.getDistance(userPosition.latitude, userPosition.longitude).toStringAsFixed(2)} km",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      )
                    : Text(
                        "Distance not available",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
              ],
            ),
            // Today's opening hours
            Text(
              store.getOpeningHoursForToday(store),
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF412a2b), // Background color for the icon
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          padding: const EdgeInsets.all(8), // Padding inside the container
          child: const Icon(Icons.storefront, color: Colors.white),
        ),
      ),
    ),
  );
}
