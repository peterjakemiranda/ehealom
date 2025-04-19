import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/api_service.dart';

/// Service for handling Firebase Cloud Messaging (FCM) functionality
class FirebaseMessagingService {
  final ApiService _apiService;
  FirebaseMessaging? _messaging;
  
  // For local notifications on Android
  FlutterLocalNotificationsPlugin? _localNotifications;
  AndroidNotificationChannel? _androidChannel;

  FirebaseMessagingService(this._apiService);

  /// Initialize Firebase messaging, request permissions and setup handlers
  Future<void> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;
      
      // Request permission for iOS and web
      await _requestPermission();
      
      // Setup foreground notification channel for Android
      await _setupLocalNotifications();
      
      // Setup message handlers
      _setupMessageHandlers();
      
      // Get the FCM token if available
      String? token = await _messaging?.getToken();
      if (token != null) {
        await saveFcmToken(token);
      }
      
      // Listen for token refreshes
      _messaging?.onTokenRefresh.listen((newToken) {
        saveFcmToken(newToken);
      });
    } catch (e) {
      debugPrint('Failed to initialize Firebase Messaging: $e');
    }
  }
  
  /// Request notification permissions
  Future<void> _requestPermission() async {
    if (_messaging == null) return;
    
    if (Platform.isIOS || kIsWeb) {
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('User declined or has not accepted permission');
      }
    }
  }
  
  /// Setup local notifications for Android foreground messages
  Future<void> _setupLocalNotifications() async {
    if (Platform.isAndroid) {
      _localNotifications = FlutterLocalNotificationsPlugin();
      
      _androidChannel = const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );
      
      await _localNotifications!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_androidChannel!);
      
      // Initialize local notifications
      await _localNotifications!.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
    }
  }
  
  /// Setup message handlers for different states
  void _setupMessageHandlers() {
    if (_messaging == null) return;
    
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      
      // Show local notification on Android for foreground messages
      if (Platform.isAndroid && _localNotifications != null && _androidChannel != null) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        
        if (notification != null && android != null) {
          _localNotifications!.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _androidChannel!.id,
                _androidChannel!.name,
                channelDescription: _androidChannel!.description,
                icon: android.smallIcon,
              ),
            ),
            payload: message.data.toString(),
          );
        }
      }
    });
    
    // Handle when a notification was tapped to open the app from terminated state
    _messaging!.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessage(message);
      }
    });
    
    // Handle when a notification was tapped to open the app from background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }
  
  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse details) {
    // Handle notification tap based on the payload
    if (details.payload != null) {
      debugPrint('Notification tapped with payload: ${details.payload}');
      // Handle navigation based on payload if needed
    }
  }
  
  /// Handle a message that opened the app
  void _handleMessage(RemoteMessage message) {
    debugPrint('Handling notification click: ${message.data}');
    
    // Handle specific actions based on the message data
    if (message.data.containsKey('appointment_id')) {
      // Navigate to appointment detail page
      // Navigation can be implemented as needed
      debugPrint('Should navigate to appointment: ${message.data['appointment_id']}');
    }
  }
  
  /// Save the FCM token to the backend
  Future<void> saveFcmToken(String token) async {
    try {
      await _apiService.post('/api/notification/token', data: {'fcm_token': token});
      debugPrint('FCM token saved successfully');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }
} 