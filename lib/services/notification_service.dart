import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// NotificationService
/// 
/// A singleton class for managing local notifications in the app.
/// Provides functions to initialize, request permissions, and display
/// notifications without using cloud services like Firebase.
class NotificationService {
  // Implement singleton pattern
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  /// The Flutter Local Notifications Plugin for cross-platform notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the notification service
  /// 
  /// Configures platform-specific settings for Android and iOS
  /// and sets up handlers for notification interactions.
  Future<void> init() async {
    // Android settings with app icon as notification symbol
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings - we don't automatically request permissions
    // but do so explicitly with requestPermissions()
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Combined settings for all platforms
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize plugin and set callback for notification interactions
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // When user taps on notification, app opens automatically
        // Additional navigation could be implemented here if necessary
      },
    );
  }

  /// Requests notification permissions from the user
  /// 
  /// Implements platform-specific methods for iOS and Android
  /// to request permissions for notifications.
  /// 
  /// Returns: 
  ///   [bool] True if permissions were granted, otherwise False
  Future<bool> requestPermissions() async {
    // iOS-specific permission request
    if (Platform.isIOS) {
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } 
    // Android-specific permission request (especially important for Android 13+)
    else if (Platform.isAndroid) {
      // Use permission_handler to request notification permission on Android
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    
    return false;
  }

  /// Checks if notification permissions have been granted
  /// 
  /// Uses platform-specific methods to determine the current permission status
  /// for notifications.
  /// 
  /// Returns:
  ///   [bool] True if notifications are allowed, otherwise False
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isIOS) {
      // iOS doesn't provide a direct API for status checking,
      // so we use the stored setting
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notificationsEnabled') ?? false;
    } else if (Platform.isAndroid) {
      // Check Android permission status via permission_handler
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return false;
  }

  /// Shows a notification with the specified title and body
  /// 
  /// First checks permissions and requests them if needed.
  /// Then configures the notification and displays it.
  /// 
  /// Parameters:
  ///   [title] - The title of the notification
  ///   [body] - The main text of the notification
  Future<void> scheduleNotification(String title, String body) async {
    // Check if permissions exist before displaying
    bool hasPermission = await areNotificationsEnabled();
    if (!hasPermission) {
      hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('Notification permissions denied');
        return;
      }
    }

    // Android-specific notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'kaufland_offers',  // Channel ID
      'Kaufland Offers',  // Channel name
      channelDescription: 'Notifications for new Kaufland offers',  // Channel description
      importance: Importance.high,  // High priority - appears as pop-up
      priority: Priority.high,      // High priority for the notification list
    );

    // iOS-specific notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,  // Show notification as alert
      presentBadge: true,  // Update app badge
      presentSound: true,  // Play sound
    );

    // Combined details for all platforms
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Display notification
    await flutterLocalNotificationsPlugin.show(
      0,  // Notification ID (0 replaces previous notifications)
      title,
      body,
      platformDetails,
      payload: 'offers',  // Payload passed when tapping on the notification
    );
  }

  /// Checks if new offers are available
  /// 
  /// Compares the date of the last stored offers
  /// with the current date to determine if new offers
  /// could be available (based on the weekly cycle).
  /// 
  /// Returns:
  ///   [bool] True if new offers are likely available, otherwise False
  Future<bool> checkForNewOffers() async {
    // Load current store ID from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String storeId = prefs.getString('storeId') ?? prefs.getString('defaultStoreId') ?? 'DE3940';
    
    // Get date of last stored offers
    String? offersDateStr = prefs.getString('offersDate$storeId');

    // If no offers have been stored yet, new offers are available
    if (offersDateStr == null || offersDateStr.isEmpty) {
      return true;
    }
    
    // Parse date of stored offers
    DateTime offersDate = DateTime.parse(offersDateStr);
    
    // If the stored offers are older than 7 days,
    // new offers are likely available
    if (DateTime.now().difference(offersDate).inDays >= 7) {
      return true;
    }
    
    return false;
  }
}

/// Callback dispatcher for Workmanager
/// 
/// This function is called by Workmanager in the background
/// to periodically check for new offers and display notifications.
/// The @pragma annotation is important so the function can be called by the isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Check if new offers are available
    bool newOffers = await notificationService.checkForNewOffers();

    // Only show a notification if new offers are actually available
    if (newOffers) {
      await notificationService.scheduleNotification(
        'New Kaufland Offers Available!',
        'Check out the latest deals and discounts at your Kaufland store.',
      );
    }
    
    // Report task as successful
    return Future.value(true);
  });
}