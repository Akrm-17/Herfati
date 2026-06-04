import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('Handling a background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> initNotifications() async {
    NotificationSettings? settings;
    try {
      settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      log('User granted permission: ${settings.authorizationStatus == AuthorizationStatus.authorized}');
    } catch (e, st) {
      log('Notification permission request failed: $e');
      log(st.toString());
    }

    if (settings != null &&
        settings.authorizationStatus == AuthorizationStatus.denied) {
      log('Notification permission denied. Continuing without notifications.');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Get FCM token and save it for the current user.
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firebaseService.updateDeviceTokenForCurrentUser(token);
      }
      log('FCM Token: $token');
    } catch (e, st) {
      log('Failed to obtain FCM token: $e');
      log(st.toString());
    }

    // Keep the saved token up to date.
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      _firebaseService.updateDeviceTokenForCurrentUser(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('User opened a notification: ${message.data}');
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      log('App opened from a terminated state by a notification: ${initialMessage.data}');
    }

    // Handle background messages
    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (e, st) {
      log('Failed to register background message handler: $e');
      log(st.toString());
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'herfatiapp_channel',
      'Herfati App Notifications',
      channelDescription: 'Notifications for Herfati App',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data['orderId'],
    );
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }
}
