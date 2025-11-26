/// Main entry point for the Kaufi Alert application
/// Initializes essential services and defines the app's navigation structure
library;

import 'package:flutter/material.dart';
import 'package:kaufi_alert_v2/pages/main_screen.dart';
import 'package:kaufi_alert_v2/pages/offer_detail.dart';
import 'package:kaufi_alert_v2/pages/offers_page.dart';
import 'package:kaufi_alert_v2/pages/select_store.dart';
import 'package:kaufi_alert_v2/pages/settings_screen.dart';
import 'package:kaufi_alert_v2/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  // Ensure Flutter binding is initialized before accessing native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification service for local notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Request notification permissions (but no welcome notification)
  await notificationService.requestPermissions();

  // Initialize Workmanager for background tasks
  await Workmanager().initialize(callbackDispatcher);

  // Schedule a daily background task to check for new offers
  // This will run even when the app is closed
  await Workmanager().registerPeriodicTask(
    'checkOffers',
    'checkNewOffers',
    frequency: const Duration(hours: 24), // Daily check
    constraints: Constraints(
      networkType: NetworkType.connected, // Only run when internet is available
    ),
    existingWorkPolicy:
        ExistingPeriodicWorkPolicy.replace, // Replace existing tasks
  );

  runApp(const MainApp());
}

/// Main application widget that sets up theme and routing
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kaufi Alert',
      // Set app-wide theme properties
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(
          0xFF1f1415,
        ), // Dark background color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1f1415),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      home: const MainScreen(), // Initial screen
      // Define named routes for navigation
      routes: {
        '/offerDetail': (context) => OfferDetail(
          product: ModalRoute.of(context)!.settings.arguments as Product,
        ),
        '/selectStore': (context) => const SelectStore(),
        '/settings': (context) => const SettingsPage(),
      },
      // Handle routes with parameters
      onGenerateRoute: (settings) {
        if (settings.name == '/offerDetail') {
          // Extract product from arguments
          final args = settings.arguments as Product;
          return MaterialPageRoute(
            builder: (context) => OfferDetail(product: args),
          );
        }
        return null;
      },
    );
  }
}
