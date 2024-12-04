import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AndroidFirebasePushNotification {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _initLocalNotifications();
    await _requestPermissions();
    await _logFcmToken();
    await _initListeners();
  }

  Future<void> _initLocalNotifications() async {
    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInitSettings);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _requestPermissions() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final NotificationSettings settings = await messaging.requestPermission();
    log('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _logFcmToken() async {
    final String? fcmToken = await _firebaseMessaging.getToken();
    log('FCM Token: $fcmToken');
  }

  Future<void> _initListeners() async {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundApp);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    FirebaseMessaging.onMessage.listen(_onMessage);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    log('Push notification opened: ${message.notification?.title}, ${message.notification?.body}');
  }

  void _onMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: NotificationChannels.generalChannel,
    );
    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }
}

Future<void> _onBackgroundApp(RemoteMessage message) async {
  log('Push notification on background: ${message.notification?.title}, ${message.notification?.body}');
}

class NotificationChannels {
  static const AndroidNotificationDetails generalChannel = AndroidNotificationDetails(
    'general_notifications',
    'Общие уведомления',
    importance: Importance.max,
    priority: Priority.high,
  );
}