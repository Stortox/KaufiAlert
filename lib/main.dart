import 'package:flutter/material.dart';
import 'package:kaufi_allert_v2/pages/main_screen.dart';
import 'package:kaufi_allert_v2/pages/offer_detail.dart';
import 'package:kaufi_allert_v2/pages/offers_page.dart';
import 'package:kaufi_allert_v2/pages/select_store.dart';
import 'package:kaufi_allert_v2/pages/settings_screen.dart';
import 'package:kaufi_allert_v2/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the notification service
  final notificationService = NotificationService();
  await notificationService.init();
  
  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
  );
  
  // Schedule periodic task to check for new offers
  await Workmanager().registerPeriodicTask(
    'checkOffers',
    'checkNewOffers',
    frequency: Duration(hours: 24), // Daily check
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaufi Allert',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF1f1415),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1f1415),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      home: const MainScreen(),
      routes: {
        '/offerDetail': (context) => OfferDetail(
          product: ModalRoute.of(context)!.settings.arguments as Product,
        ),
        '/selectStore': (context) => const SelectStore(),
        '/settings': (context) => const SettingsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/offerDetail') {
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