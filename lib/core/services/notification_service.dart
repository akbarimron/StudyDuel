import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handles background messages
  debugPrint("Handling a background message: ${message.messageId}");
  // The OS will automatically show notification if payload has "notification" field.
  // We can also trigger a local notification here if it is data-only.
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  StreamSubscription<User?>? _authSubscription;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Request Notification permissions (especially Android 13+ / iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User notification permission status: ${settings.authorizationStatus}');

    // 2. Initialize Local Notifications for Foreground display
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click action here if needed
        debugPrint("Notification clicked: ${response.payload}");
      },
    );

    // Create high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'study_duel_chat_channel', // id
      'StudyDuel Chat Notifications', // title
      description: 'Channel used for StudyDuel chat message push notifications.', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Configure FCM listeners
    // Foreground Messages handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      
      // If we are already in ChatScreen and the message is from the active friend, do not show any alert
      // This matches the muted state we implemented in HomeScreen
      final type = message.data['type'] ?? '';
      final fromUid = message.data['from_uid'] ?? '';
      
      // If the app is actively on the ChatScreen with this specific friend, suppress it.
      // We will let the custom home screen overlay handle normal in-app alerts if not in ChatScreen,
      // but we can also trigger a local notification here as fallback if the user wants it in the system tray.
      
      // If we decide to show a local notification:
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon ?? '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // App opened via notification click handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked and app opened: ${message.data}');
    });

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Start Auth token synchronization
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        syncTokenToFirestore();
      }
    });

    // Also watch for token refreshes
    _fcm.onTokenRefresh.listen((String newToken) {
      syncTokenToFirestore();
    });

    _initialized = true;
  }

  // Fetch the FCM token and save to Firestore user document
  Future<void> syncTokenToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? token = await _fcm.getToken();
      if (token == null) return;

      debugPrint("FCM Registration Token: $token");

      // Save token directly to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcm_token': token,
        'updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint("Successfully synchronized FCM token in Firestore for user: ${user.uid}");
    } catch (e) {
      debugPrint("Error syncing FCM token to Firestore: $e");
    }
  }

  // Clear token from Firestore (call on logout)
  Future<void> clearTokenFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcm_token': FieldValue.delete(),
      });
      debugPrint("Successfully cleared FCM token from Firestore for user: ${user.uid}");
    } catch (e) {
      debugPrint("Error clearing FCM token from Firestore: $e");
    }
  }
}
