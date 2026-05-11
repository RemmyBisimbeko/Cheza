import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Handle background messages — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by FCM automatically
}

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const _channelId = 'matatu_turns';
  static const _channelName = 'Your Turn Alerts';

  // ── Initialize ────────────────────────────────────────

  Future<void> initialize(BuildContext context) async {
    // Request FCM permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // User denied — skip silently
    }

    // Setup local notifications for foreground display
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        // Notification tapped — handle navigation here if needed
      },
    );

    // Create Android notification channel
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Alerts when it is your turn in Matatu',
          importance: Importance.high,
          playSound: true,
        ),
      );
    }

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Save FCM token to Firestore
    await _saveToken();

    // Refresh token when it changes
    _messaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  // ── Token Management ──────────────────────────────────

  Future<void> _saveToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _db.collection('users').doc(uid).set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to refresh FCM token: $e');
    }
  }

  // ── Message Handlers ──────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Show local notification when app is open
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['roomId'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final roomId = message.data['roomId'];
    if (roomId != null) {
      debugPrint('Notification tapped for room: $roomId');
      // Navigation can be wired here via a global navigator key
    }
  }

  // ── Send Turn Notification ────────────────────────────
  // Called after a move — Cloud Function also handles this
  // This is a fallback for direct sends if needed

  Future<void> sendTurnNotification({
    required String targetUid,
    required String roomId,
    required String senderName,
  }) async {
    try {
      final snap = await _db.collection('users').doc(targetUid).get();
      if (!snap.exists) return;

      final token = snap.data()?['fcmToken'] as String?;
      if (token == null) return;

      // Store notification doc — Cloud Function picks it up
      await _db.collection('notifications').add({
        'token': token,
        'title': '🃏 Your Turn!',
        'body': '$senderName just played. Your move in Matatu!',
        'data': {'roomId': roomId},
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      debugPrint('Failed to send turn notification: $e');
    }
  }

  // ── Clear Badge ───────────────────────────────────────

  Future<void> clearBadge() async {
    await _localNotifications.cancelAll();
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
