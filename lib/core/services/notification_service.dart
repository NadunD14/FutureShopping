import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle local notifications for product changes
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request notification permission
      final permissionStatus = await Permission.notification.request();
      if (permissionStatus != PermissionStatus.granted) {
        print('Notification permission not granted');
        return false;
      }

      // Android initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      final result = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = result ?? false;
      print('Notification service initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      print('Error initializing notification service: $e');
      return false;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate to product details if needed
  }

  /// Show notification when product changes
  Future<void> showProductChangeNotification({
    required String productName,
    required String productId,
    String? price,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    try {
      const notificationId = 1; // Use same ID to replace previous notifications

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'product_changes',
        'Product Changes',
        channelDescription: 'Notifications when nearby products change',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: false,
        icon: '@mipmap/ic_launcher',
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Format the notification content
      final title = 'New Product Nearby!';
      final body = price != null ? '$productName - $price' : productName;

      // Show the notification
      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: productId,
      );

      print('Product change notification sent: $productName');
    } catch (e) {
      print('Error showing product change notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) return false;

    try {
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }
}
