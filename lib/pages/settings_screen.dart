/// Settings Screen
///
/// Lets users view/change their selected store and toggle offer notifications.
library;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kaufi_alert/pages/select_store.dart';
import 'package:workmanager/workmanager.dart';

import '../models/store.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/store_repository.dart';
import '../widgets/store_tile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _prefs = PreferencesService.instance;
  final _stores = StoreRepository.instance;

  Position? _userPosition;
  bool _notificationsEnabled = true;

  /// Created once and only replaced when the store actually changes, so the
  /// FutureBuilder doesn't re-run on every rebuild.
  late Future<Store> _selectedStoreFuture;

  @override
  void initState() {
    super.initState();
    _selectedStoreFuture = _stores.selectedStore();
    _init();
  }

  Future<void> _init() async {
    await _prefs.init();
    final position = await LocationService.currentPosition();
    if (!mounted) return;
    setState(() {
      _userPosition = position;
      _notificationsEnabled = _prefs.notificationsEnabled;
    });
  }

  Future<void> _openSelectStore() async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectStore()),
    );
    if (selected != null && mounted) {
      setState(() => _selectedStoreFuture = _stores.selectedStore());
    }
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _prefs.setNotificationsEnabled(value);
    if (value) {
      await Workmanager().registerPeriodicTask(
        'checkOffers',
        'checkNewOffers',
        frequency: const Duration(hours: 24),
        constraints: Constraints(networkType: NetworkType.connected),
        // `keep` so we don't restart the interval if it's already scheduled.
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
      // Immediate confirmation: prompts for the OS permission if needed and
      // gives the user visible proof the pipeline works.
      await NotificationService().scheduleNotification(
        'Notifications enabled',
        "You'll be notified when new Kaufland offers are available.",
      );
    } else {
      await Workmanager().cancelByUniqueName('checkOffers');
    }
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
          _buildSectionLabel("Selected Store"),
          FutureBuilder<Store>(
            future: _selectedStoreFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                );
              }
              if (snapshot.data == null) {
                return const Text(
                  'No store found',
                  style: TextStyle(color: Colors.white),
                );
              }
              return SizedBox(
                width: MediaQuery.of(context).size.width - 10,
                height: 80,
                child: StoreTile(
                  store: snapshot.data!,
                  userPosition: _userPosition,
                ),
              );
            },
          ),
          GestureDetector(
            onTap: _openSelectStore,
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
                    color: const Color(0xFF412a2b),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.touch_app_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel("Notifications"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ListTile(
              title: const Text(
                "Enable Notifications",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: _setNotifications,
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

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
