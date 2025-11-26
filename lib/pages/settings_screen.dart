/// Settings Screen
///
/// This file implements the settings page where users can:
/// - View and change their selected Kaufland store
/// - Toggle notification preferences for new offers
/// - See current location-based information and store details
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kaufi_alert_v2/pages/select_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

/// SettingsPage displays user preferences and store selection options
///
/// This widget allows users to configure app-wide settings that persist
/// between sessions using SharedPreferences
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// List of all available stores
  List<Store> stores = [];

  /// Current user's geographical position
  /// Used for calculating distance to stores
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

  /// Flag to control whether notifications are enabled
  bool notificationsEnabled = false;

  /// SharedPreferences instance for data persistence
  late SharedPreferences prefs;

  /// Initialize SharedPreferences and load saved settings
  ///
  /// Retrieves user preferences from local storage, including
  /// notification preferences
  Future<void> initializeSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
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
    // Load nearby stores based on location
    getClosestStores();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1f1415),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1f1415),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Section header for selected store
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Selected Store",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Display the currently selected store
          FutureBuilder<Store>(
            future: getSelectedStore(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.white),
                );
              } else {
                if (snapshot.data == null) {
                  return const Text(
                    'No store found',
                    style: TextStyle(color: Colors.white),
                  );
                } else {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width - 10,
                    height: 80,
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 1,
                      itemBuilder: (context, index) {
                        Store store = snapshot.data!;
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
          // Button to navigate to store selection screen
          GestureDetector(
            onTap: () {
              _openSelectStore(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: ListTile(
                title: const Text(
                  "Choose other store",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF412a2b,
                    ), // Background color for the icon
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  padding: const EdgeInsets.all(
                    8,
                  ), // Padding inside the container
                  child: const Icon(
                    Icons.touch_app_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Section header for notification settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Notifications",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Toggle switch for enabling/disabling notifications
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ListTile(
              title: const Text(
                "Enable Notifications",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              trailing: Switch(
                value: notificationsEnabled,
                onChanged: (bool value) async {
                  setState(() {
                    notificationsEnabled = value;
                  });
                  await prefs.setBool('notificationsEnabled', value);

                  // Enable or disable background tasks based on user preference
                  if (value) {
                    // Schedule periodic background task for checking new offers
                    await Workmanager().registerPeriodicTask(
                      'checkOffers',
                      'checkNewOffers',
                      frequency: Duration(hours: 24),
                      constraints: Constraints(
                        networkType: NetworkType.connected,
                      ),
                      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
                    );
                  } else {
                    // Cancel background task if notifications are disabled
                    await Workmanager().cancelByUniqueName('checkOffers');
                  }
                },
                activeThumbColor: const Color.fromARGB(255, 97, 70, 71),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey[800],
              ),
              subtitle: const Text(
                "Get notified when new offers are available.",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
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

  /// Retrieves the currently selected store from preferences
  ///
  /// If no store has been selected yet, sets and returns the default store
  Future<Store> getSelectedStore() async {
    await initializeSharedPreferences();
    String? selectedStoreJson = prefs.getString('selectedStore');
    if (selectedStoreJson != null && selectedStoreJson.isNotEmpty) {
      return Store.fromJson(json.decode(selectedStoreJson));
    }
    // Set default store if none is selected
    prefs.setString('selectedStore', json.encode(selectedStore.toJson()));
    prefs.setString('storeId', selectedStore.storeId);
    return selectedStore;
  }

  /// Opens the store selection screen and handles the result
  ///
  /// When a store is selected, triggers a UI update to reflect the change
  void _openSelectStore(BuildContext context) async {
    final selectedStore = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectStore()),
    );
    if (selectedStore != null && mounted) {
      setState(() {});
    }
  }
}

/// Builds a ListTile widget to display store information
///
/// Shows store name, address, distance from user, and today's opening hours
Widget buildStoreTile(
  Store store,
  Position? userPosition,
  BuildContext context,
  SharedPreferences prefs,
) {
  return Padding(
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
  );
}

/// Store model class representing a Kaufland store location
///
/// Contains store details, location data, and methods for
/// calculating distance and retrieving opening hours
class Store {
  /// Unique identifier for the store
  final String storeId;

  /// Display name of the store
  final String name;

  /// Full address of the store
  final String address;

  /// Weekly opening hours in format: "Mon: HH:MM-HH:MM, Tue: HH:MM-HH:MM, ..."
  final String openingHours;

  /// Geographic coordinates [longitude, latitude]
  final List<double> position;

  /// ISO country code (e.g., "DE" for Germany)
  final String country;

  Store({
    required this.storeId,
    required this.name,
    required this.address,
    required this.openingHours,
    required this.position,
    required this.country,
  });

  /// Creates a Store instance from JSON data
  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      storeId: json['storeId'],
      name: json['name'],
      address: json['address'],
      openingHours: json['openingHours'],
      position: [json['latitude'], json['longitude']],
      country: json['country'],
    );
  }

  /// Converts this Store instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'name': name,
      'address': address,
      'openingHours': openingHours,
      'latitude': position[0],
      'longitude': position[1],
      'country': country,
    };
  }

  /// Calculates the distance in kilometers between the store and given coordinates
  double getDistance(double userLatitude, double userLongitude) {
    return Geolocator.distanceBetween(
          userLatitude,
          userLongitude,
          position[0],
          position[1],
        ) /
        1000;
  }

  /// Gets the opening hours for today based on the current day of the week
  ///
  /// Returns a formatted string showing today's opening hours
  /// or "Closed" if the store is not open today
  String getOpeningHoursForToday(Store store) {
    DateTime now = DateTime.now();
    String weekday = now.weekday.toString(); // 1 = Monday, 7 = Sunday
    if (store.openingHours.isEmpty) {
      return "no information available";
    }

    // Parse the opening hours string into individual day segments
    List<String> hours = store.openingHours.split(",");
    for (var i = 0; i < hours.length; i++) {
      hours[i] = hours[i].substring(hours[i].indexOf(" ") + 1);
    }

    String openingHours = "Closed";
    // Get the appropriate opening hours based on the current day
    if (weekday == "1") {
      openingHours = hours[0].trim();
    } else if (weekday == "2") {
      openingHours = hours[1].trim();
    } else if (weekday == "3") {
      openingHours = hours[2].trim();
    } else if (weekday == "4") {
      openingHours = hours[3].trim();
    } else if (weekday == "5") {
      openingHours = hours[4].trim();
    } else if (weekday == "6") {
      openingHours = hours[5].trim();
    } else if (weekday == "7") {
      openingHours = hours[6].trim();
    }

    // Special case for closed days (0:00-0:00)
    if (openingHours == "0:00-0:00") {
      openingHours = "Closed";
    }
    return openingHours;
  }
}
