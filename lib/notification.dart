// ignore_for_file: avoid_print

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:memoauthapp/main.dart'; // Needed for context

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('assets/KDSG.jpeg');

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

    try {
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
    });
  }

  static void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      print("Notification payload: $payload");
      // Navigate to login screen
      Navigator.pushAndRemoveUntil(
        navigatorKey.currentState!.context,
        MaterialPageRoute(builder: (context) => const LoginScreenPage()),
        (route) => false,
      );
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(
      const DrawableResourceAndroidBitmap('assets/KDSG.jpeg'),
      largeIcon: const DrawableResourceAndroidBitmap('assets/KDSG.jpeg'),
      contentTitle: message.notification?.title,
      summaryText: message.notification?.body,
    );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Provide a valid channel ID
      'KDSG MemoApp',
      channelDescription: 'To attend to a notification sent',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigPictureStyleInformation,
      showWhen: false,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title ?? 'You have a new notification',
        message.notification?.body ?? '',
        platformChannelSpecifics,
        payload: '',
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
