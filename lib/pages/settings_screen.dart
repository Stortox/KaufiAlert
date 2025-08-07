import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kaufi_allert_v2/pages/select_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  List<Store> stores = [];
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
  Store selectedStore = Store(
    storeId: 'DE3940',
    name: 'Kaufland Dresden-Striesen-West',
    address: 'Borsbergstraße 35, Dresden',
    openingHours: 'Mon: 09:00-20:00, Tue: 09:00-20:00, Wed: 09:00-20:00, Thu: 09:00-20:00, Fri: 09:00-20:00, Sat: 09:00-20:00, Sun: 0:00-0:00',
    position: [13.7812778, 51.044094],
    country: 'DE',
  );
  late SharedPreferences prefs;
  initializeSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    getClosestStores();
    getUserPosition().then((position) {
      if (mounted) {
        setState(() {
          userPosition = position;
        });
      }
    });
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Selected Store", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          ),
          FutureBuilder<Store>(
            future: getSelectedStore(),
            builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white));
            } else {
              if(snapshot.data == null) {
                return const Text('No store found', style: TextStyle(color: Colors.white));
              } else {
                return SizedBox(
                  width: MediaQuery.of(context).size.width - 10,
                  height: 80,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      Store store = snapshot.data!;
                      return buildStoreTile(store, userPosition, context, prefs);
                    },
                  ),
                  );
                }
              }
            },
          ),
          GestureDetector(
            onTap: () {
              _openSelectStore(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: ListTile(
                title: const Text("Choose other store", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF412a2b), // Background color for the icon
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  padding: const EdgeInsets.all(8), // Padding inside the container
                  child: const Icon(Icons.touch_app_outlined, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Sort Offers By", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF412a2b),
                borderRadius: BorderRadius.circular(16),
              ),
              child: FutureBuilder<String>(
                future: getSortingBy(),
                builder: (context, snapshot) {
                  String? initialSelection = snapshot.data ?? 'category';
                  return DropdownMenu<String>(
                    width: MediaQuery.of(context).size.width - 40,
                    initialSelection: initialSelection,
                    dropdownMenuEntries: [
                      DropdownMenuEntry(
                        value: 'category',
                        label: 'Category',
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                        ),
                      ),
                      DropdownMenuEntry(
                        value: 'priceLowToHigh',
                        label: 'Price: Low to High',
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                        ),
                      ),
                      DropdownMenuEntry(
                        value: 'priceHighToLow',
                        label: 'Price: High to Low',
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                        ),
                      ),
                      DropdownMenuEntry(
                        value: 'discountLowToHigh',
                        label: 'Discount: Low to High',
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                        ),
                      ),
                      DropdownMenuEntry(
                        value: 'discountHighToLow',
                        label: 'Discount: High to Low',
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                        ),
                      ),
                      DropdownMenuEntry(
                        value: 'nameAZ',
                        label: 'Name: A-Z',
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                        ),
                      ),
                      DropdownMenuEntry(
                        value: 'nameZA',
                        label: 'Name: Z-A',
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      prefs.setString('sortOffersBy', value ?? 'category');
                    },
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: const Color(0xFF412a2b),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStateProperty.all(const Color(0xFF412a2b)),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                      ),
                      maximumSize: WidgetStateProperty.all(Size(400.0, 500.0)),
                      alignment: Alignment.lerp(Alignment.bottomLeft, Alignment.centerLeft, 0.5),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Position> getUserPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.deniedForever) {
      if (serviceEnabled) {
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        } else if (permission != LocationPermission.denied) {
          try {
            return await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high));
          } catch (e) {
            print("Error getting user position: $e");
          }
        }
      }
    }
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

  Future<List<Store>> getClosestStores() async {
    await initializeSharedPreferences();
    String? cachedData = prefs.getString('stores');
    if (cachedData != null && cachedData.isNotEmpty) {
      List<dynamic> jsonList = json.decode(cachedData);
      stores = jsonList.map((json) => Store.fromJson(json)).toList();
      Position position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high));
      double userLatitude = position.latitude;
      double userLongitude = position.longitude;
      //WidgetsBinding.instance.platformDispatcher.locale.countryCode
      List<Store> localStores = List<Store>.from(stores).where((store) => store.country == WidgetsBinding.instance.platformDispatcher.locale.countryCode && store.storeId != prefs.getString('storeId')).toList();
      localStores.sort((a, b) {
        double distanceA = a.getDistance(userLatitude, userLongitude);
        double distanceB = b.getDistance(userLatitude, userLongitude);
        return distanceA.compareTo(distanceB);
      });

      return localStores.take(3).toList();
    }
    return [];
  }

  Future<Store> getSelectedStore() async {
    await initializeSharedPreferences();
    String? selectedStoreJson = prefs.getString('selectedStore');
    if (selectedStoreJson != null && selectedStoreJson.isNotEmpty) {
      return Store.fromJson(json.decode(selectedStoreJson));
    }
    prefs.setString('selectedStore', json.encode(selectedStore.toJson()));
    prefs.setString('storeId', selectedStore.storeId);
    return selectedStore;
  }

  void _openSelectStore(BuildContext context) async {
    final selectedStore = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectStore()),
    );
    if (selectedStore != null && mounted) {
      setState(() {});
    }
  }

  Future<String> getSortingBy() async {
    await initializeSharedPreferences();
    String? sortBy = prefs.getString('sortOffersBy');
    if (sortBy == null || sortBy.isEmpty) {
      return 'category';
    }
    return sortBy;
  }
}

Widget buildStoreTile(Store store, Position? userPosition, BuildContext context, SharedPreferences prefs) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: ListTile(
      title: Text(store.name, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width - 200,
                child: Text(store.address, style: TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis,),
              ),
              userPosition != null ? Text(
                "${store.getDistance(userPosition.latitude, userPosition.longitude).toStringAsFixed(2)} km",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ) : Text("Distance not available", style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
          Text(store.getOpeningHoursForToday(store), style: TextStyle(color: Colors.white, fontSize: 11)),
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

class Store {
  final String storeId;
  final String name;
  final String address;
  final String openingHours;
  final List<double> position;
  final String country;

  Store({
    required this.storeId,
    required this.name,
    required this.address,
    required this.openingHours,
    required this.position,
    required this.country,
  });

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

  double getDistance(double userLatitude, double userLongitude) {
    return Geolocator.distanceBetween(userLatitude, userLongitude, position[0], position[1])/1000;
  }

  String getOpeningHoursForToday(Store store) {
    DateTime now = DateTime.now();
    String weekday = now.weekday.toString(); // 1 = Monday, 7 = Sunday
    if (store.openingHours.isEmpty) {
      return "no information available";
    }
    List<String> hours = store.openingHours.split(",");
    for(var i = 0; i < hours.length; i++) {
      hours[i] = hours[i].substring(hours[i].indexOf(" ") + 1);
    }
    String openingHours = "Closed";
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
    if(openingHours == "0:00-0:00"){
      openingHours = "Closed";
    }
    return openingHours;
  }
}