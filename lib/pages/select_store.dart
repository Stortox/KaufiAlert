import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kaufi_allert_v2/pages/search_store.dart';
import 'package:kaufi_allert_v2/pages/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectStore extends StatefulWidget {
  const SelectStore({super.key});

  @override
  State<SelectStore> createState() => _SelectStoreState();
}

class _SelectStoreState extends State<SelectStore> {
  List<Store> stores = [];
  List<Store> filteredStores = [];
  bool isExplanationVisible = false;
  bool useCurrentLocation = false;

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
    getClosestStores().then((_){
      if (mounted) {
        setState(() {
          filteredStores = stores;
        });
      }
    });
    getUserPosition().then((position) {
      if(mounted) {
        setState(() {
          userPosition = position;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Store', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1f1415),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Choose your preferred store", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
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
                    title: const Text("Use current location", style: TextStyle(color: Colors.white)),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                      color: const Color(0xFF412a2b),
                      borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.location_on_outlined, color: Colors.white),
                    ),
                    trailing: const Icon(Icons.info_outline, color: Colors.white),
                    onTap: () {
                      setState(() {
                        isExplanationVisible = !isExplanationVisible;
                      });
                    },
                    ),
                  ),
                  if (isExplanationVisible)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Use your current location to automatically find the nearest store.",
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          Switch(
                            value: prefs.getBool('dynamicStoreEnabled') ?? false,
                            onChanged: (value) {
                              setState(() {
                                useCurrentLocation = value;
                              });
                              prefs.setBool('dynamicStoreEnabled', value);
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text("Search for a store", style: TextStyle(color: filteredStores.isNotEmpty ? Colors.white : Colors.grey)),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF412a2b), // Background color for the icon
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),
                      padding: const EdgeInsets.all(8), // Padding inside the container
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                    onTap: () => {
                      prefs.setString('filteredStores', json.encode(filteredStores)),
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SearchStore())),
                    },
                    enabled: filteredStores.isNotEmpty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Nearby stores", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            userPosition.latitude == 0.0 && userPosition.longitude == 0.0
              ? const CircularProgressIndicator()
              : FutureBuilder<List<Store>>(
              future: getClosestStores(),
              builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white));
              } else {
                if(snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Text('No stores found', style: TextStyle(color: Colors.white));
                  } else {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width - 10,
                      height: MediaQuery.of(context).size.height - 550,
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          Store store = snapshot.data![index];
                          return buildStoreTile(store, userPosition, context, prefs);
                        },
                      ),
                    );
                  }
                }
              },
            )
          ],
        ),
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
}

Widget buildStoreTile(Store store, Position? userPosition, BuildContext context, SharedPreferences prefs) {
  return GestureDetector(
    onTap: () async {
      await prefs.setString('selectedStore', json.encode(store));
      await prefs.setString('storeId', store.storeId);
      Navigator.pop(context, store);
    },
    child: Padding(
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
    ),
  );
}