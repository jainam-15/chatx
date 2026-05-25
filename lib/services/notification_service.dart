import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/routing/app_router.dart';
import '../core/routing/route_paths.dart';
import '../core/utils/logger.dart';
import '../providers/auth_provider.dart';
import '../screens/chat_detail_screen.dart';
import 'web_helper_stub.dart'
    if (dart.library.html) 'web_helper_web.dart' as web_helper;

// Top-level background message handler.
// Must be annotated with @pragma('vm:entry-point') to prevent tree-shaking in release builds.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Logger.info('NotificationService', 'Handling background message: ${message.messageId}');
}

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static const String _tag = 'NotificationService';

  // Android high importance notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important chat notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // VAPID public key for web push subscriptions.
  static const String? _vapidKey = kIsWeb
      ? 'BIACVDi7EDCKzB8m6KXUDZANTII6fnGCWpEoBE6MfevWIxlTnLPFqWGYq2yzQJKf2Aou2z07GXND6cvBIsZOg8g'
      : null;

  NotificationService(this._ref);

  // Initialize notifications
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        Logger.info(_tag, 'Web target detected. Awaiting service worker activation before initializing FCM...');
        await web_helper.waitForServiceWorkerReady();
        Logger.info(_tag, 'Service worker activation confirmed. Initializing FCM...');
      }

      // 1. Request permissions for iOS, Android & Web
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      Logger.info(
        _tag,
        'Notification authorization status: ${settings.authorizationStatus}',
      );

      // 2. Set up background messaging handler (non-web only, web uses the service worker)
      // Note: We register this in main.dart now to ensure it fires in terminated state, 
      // but leaving the web stub initialization logic here is fine if needed.

      // 3. Platform-specific initialization (Android notification channels & local notifications)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (!kIsWeb) {
        // Initialize local notifications for foreground alerts
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
        );

        await _localNotifications.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse details) {
            final roomId = details.payload;
            if (roomId != null && roomId.isNotEmpty) {
              Logger.info(_tag, 'FOREGROUND LOCAL NOTIFICATION TAPPED! Extracted roomId: $roomId');
              _navigateToRoom(roomId);
            } else {
              Logger.warning(_tag, 'Local notification clicked but NO roomId found in payload!');
            }
          },
        );

        // Create the Android channel
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(_channel);
          Logger.info(_tag, 'Android notification channel created');
        }
      } else {
        // Web-specific initialization: Listen to messages sent from firebase-messaging-sw.js
        web_helper.setupWebNotificationClickListener((roomId) {
          Logger.info(_tag, 'Web notification click message received for room: $roomId');
          _navigateToRoom(roomId);
        });
      }

      // 4. Set up foreground messaging handler (show local banner on Android, or print on Web)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        Logger.info(_tag, 'Received foreground message: ${message.notification?.title}');
        
        final notification = message.notification;
        final android = message.notification?.android;
        final roomId = message.data['chatId'] as String? ?? message.data['roomId'] as String?;

        if (notification != null) {
          if (kIsWeb) {
             web_helper.showWebNotification(notification.title ?? 'New Message', notification.body ?? '', roomId ?? '');
          } else if (android != null) {
            _localNotifications.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  _channel.id,
                  _channel.name,
                  channelDescription: _channel.description,
                  icon: android.smallIcon ?? '@mipmap/ic_launcher',
                  importance: Importance.max,
                  priority: Priority.high,
                  ticker: 'ticker',
                ),
              ),
              payload: roomId,
            );
          }
        }
      });

      // 5. Handle notification clicks (app was in background but open)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);

      // 6. Handle notification click (app was terminated and opened)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        Logger.info(_tag, 'App opened from terminated state by message: ${initialMessage.messageId}');
        _handleMessageClick(initialMessage);
      }
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to initialize notifications', e, stack);
    }
  }

  void _navigateToRoom(String roomId) {
    Logger.info(_tag, 'Navigating to chat room: $roomId');
    
    // Ensure the app has time to mount the router before navigating,
    // especially important when opening from a terminated state.
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        if (navigatorKey.currentContext != null) {
          _ref.read(routerProvider).go(RoutePaths.chatDetail.replaceAll(':roomId', roomId));
        } else {
          Logger.warning(_tag, 'Navigator context still null after delay. Retrying...');
          Future.delayed(const Duration(milliseconds: 500), () {
             _ref.read(routerProvider).go(RoutePaths.chatDetail.replaceAll(':roomId', roomId));
          });
        }
      } catch (e, stack) {
        Logger.error(_tag, 'Failed to navigate to room', e, stack);
      }
    });
  }

  // Handle notification tap payload
  void _handleMessageClick(RemoteMessage message) {
    Logger.info(_tag, '''
========================================
    NOTIFICATION TAPPED DETECTED
========================================
Raw Payload Data: ${message.data}
    ''');
    
    // Extract chatId exactly as requested
    String? roomId = message.data['chatId']?.toString();
    
    // Fallbacks just in case
    if (roomId == null || roomId.isEmpty) {
      roomId = message.data['roomId']?.toString();
    }
    
    if (roomId == null && message.data.containsKey('data')) {
      final nested = message.data['data'];
      if (nested is Map) {
        roomId = nested['chatId']?.toString() ?? nested['roomId']?.toString();
      }
    }

    if (roomId != null && roomId.isNotEmpty) {
      Logger.info(_tag, 'Successfully extracted chatId: $roomId. Triggering navigation...');
      _navigateToRoom(roomId);
    } else {
      Logger.error(_tag, '''
========================================
FAILED TO EXTRACT CHAT ID FROM PAYLOAD!
Payload was: ${message.data}
========================================
      ''');
    }
  }

  // Get device FCM token (submitting VAPID key on web)
  Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        Logger.info(_tag, 'Web target detected. Awaiting service worker activation before fetching token...');
        await web_helper.waitForServiceWorkerReady();
        Logger.info(_tag, 'Service worker activation confirmed. Fetching FCM token...');
      }
      final token = await _fcm.getToken(vapidKey: _vapidKey);
      Logger.info(_tag, 'FCM Token retrieved successfully: $token');
      return token;
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to retrieve FCM token', e, stack);
      return null;
    }
  }

  // Delete device FCM token (unsubscribe)
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      Logger.info(_tag, 'FCM Token deleted successfully from device');
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to delete FCM token', e, stack);
    }
  }

  // Stream token updates
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;
}
