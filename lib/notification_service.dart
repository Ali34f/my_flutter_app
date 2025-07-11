import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static StreamSubscription<DocumentSnapshot>? _orderSubscription;
  static String? _currentOrderId;
  static String? _lastKnownStatus;

  // Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request iOS permissions explicitly
      final bool? isGranted = await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      print('📱 iOS notification permissions granted: $isGranted');

      // Create Android notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'order_updates',
        'Order Updates',
        description: 'Notifications for order status updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      _initialized = true;
      print('✅ Notification service initialized (No Cloud Functions)');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  // Start listening for order status changes
  static void startListeningForOrderUpdates(String orderId) {
    // Stop any existing subscription
    stopListening();

    _currentOrderId = orderId;
    _lastKnownStatus = null;

    print('🔔 Started listening for order updates: $orderId');

    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              Map<String, dynamic> data =
                  snapshot.data() as Map<String, dynamic>;
              String currentStatus = data['status'] ?? '';
              String orderNumber = data['orderId'] ?? orderId;

              // Only show notification if status actually changed
              if (_lastKnownStatus != null &&
                  _lastKnownStatus != currentStatus) {
                print('📱 Status changed: $_lastKnownStatus -> $currentStatus');
                _showLocalNotification(currentStatus, orderNumber);
              }

              _lastKnownStatus = currentStatus;
            }
          },
          onError: (error) {
            print('❌ Error listening for order updates: $error');
          },
        );
  }

  // Stop listening for updates
  static void stopListening() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
    _currentOrderId = null;
    _lastKnownStatus = null;
    print('🔕 Stopped listening for order updates');
  }

  // Show local notification
  static Future<void> _showLocalNotification(
    String status,
    String orderNumber,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'order_updates',
            'Order Updates',
            channelDescription: 'Notifications for order status updates',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFDC143C),
            enableVibration: true,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('notification'),
            visibility: NotificationVisibility.public,
          );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.active,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      String title = _getNotificationTitle(status);
      String body = _getNotificationBody(status, orderNumber);

      // Generate unique notification ID
      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: _currentOrderId,
      );

      print('✅ Local notification shown: $title');

      // Store notification in Firestore for history (optional - won't break if fails)
      _storeNotificationRecord(status, title, body, orderNumber);
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // Store notification record (optional - won't break app if fails)
  static Future<void> _storeNotificationRecord(
    String status,
    String title,
    String body,
    String orderNumber,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'orderId': _currentOrderId,
        'status': status,
        'title': title,
        'body': body,
        'orderNumber': orderNumber,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'order_update_local',
        'read': false,
      });
      print('✅ Notification record stored');
    } catch (e) {
      print('⚠️ Could not store notification record (non-critical): $e');
      // Don't throw error - this is optional functionality
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    String? orderId = notificationResponse.payload;
    if (orderId != null) {
      print('📱 Notification tapped for order: $orderId');
      // You can navigate to order tracking screen here if needed
    }
  }

  // Manual notification (for testing)
  static Future<void> showTestNotification() async {
    try {
      await _showLocalNotification('confirmed', 'TEST123');
      print('✅ Test notification sent');
    } catch (e) {
      print('❌ Test notification failed: $e');
    }
  }

  // Get notification title based on status
  static String _getNotificationTitle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '🍽️ Order Received!';
      case 'confirmed':
        return '✅ Order Confirmed!';
      case 'preparing':
        return '👨‍🍳 Food Being Prepared!';
      case 'ready':
        return '🔔 Order Ready for Collection!';
      case 'out_for_delivery':
        return '🚗 Out for Delivery!';
      case 'delivered':
        return '🏠 Order Delivered!';
      case 'collected':
        return '🎉 Order Collected!';
      case 'cancelled':
        return '❌ Order Cancelled';
      default:
        return '📱 Order Update';
    }
  }

  // Get notification body based on status
  static String _getNotificationBody(String status, String orderNumber) {
    String shortOrderNumber = orderNumber.length > 6
        ? orderNumber.substring(orderNumber.length - 6)
        : orderNumber;

    switch (status.toLowerCase()) {
      case 'pending':
        return 'We\'ve received order #$shortOrderNumber and will start preparing it soon!';
      case 'confirmed':
        return 'Order #$shortOrderNumber confirmed. Estimated time: 25-35 minutes.';
      case 'preparing':
        return 'Our chefs are preparing your delicious order #$shortOrderNumber!';
      case 'ready':
        return 'Order #$shortOrderNumber is ready! Please come and collect it.';
      case 'out_for_delivery':
        return 'Order #$shortOrderNumber is on its way to you!';
      case 'delivered':
        return 'Order #$shortOrderNumber has been delivered. Enjoy your meal!';
      case 'collected':
        return 'Thank you for collecting order #$shortOrderNumber! Enjoy your meal! 😊';
      case 'cancelled':
        return 'Order #$shortOrderNumber has been cancelled. Please contact us if you have questions.';
      default:
        return 'Order #$shortOrderNumber status updated to: $status';
    }
  }

  // Check notification permissions
  static Future<bool> areNotificationsEnabled() async {
    try {
      final bool? isGranted = await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return isGranted ?? false;
    } catch (e) {
      print('❌ Error checking notification permissions: $e');
      return false;
    }
  }

  // Check if currently listening to an order
  static bool get isListening => _orderSubscription != null;

  // Get current order being listened to
  static String? get currentOrderId => _currentOrderId;
}
