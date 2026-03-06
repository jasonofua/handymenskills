import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level handler for background / terminated-state FCM messages.
///
/// Must be a top-level function (not a class method) so that the Flutter
/// engine can invoke it in a separate isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to interact with plugins here, make sure to call
  // `WidgetsFlutterBinding.ensureInitialized()` first.
  // For now we silently acknowledge receipt; the OS tray handles display.
}

/// Service responsible for push notification setup and display.
///
/// Wraps Firebase Cloud Messaging for remote push delivery and
/// [FlutterLocalNotificationsPlugin] for heads-up / foreground display.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// The Android notification channel used for all local notifications.
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'artisan_marketplace',
    'Artisan Marketplace',
    description: 'Notifications for Artisan Marketplace',
    importance: Importance.high,
  );

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes permissions, local notification channels, and FCM handlers.
  ///
  /// Returns the current FCM registration token (may be `null` on simulators
  /// or if the user declines push permissions).
  Future<String?> initialize() async {
    // 1. Request push permissions (iOS & Android 13+).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Create the Android notification channel.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 3. Initialize the local notifications plugin.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final initSettings = const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    // 4. Register the background message handler.
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // 5. Listen for foreground messages.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Retrieve the FCM token.
    final token = await getToken();
    return token;
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  /// Returns the current FCM registration token.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }

  /// Stream that emits a new token whenever FCM rotates it.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  // ---------------------------------------------------------------------------
  // Foreground message handling
  // ---------------------------------------------------------------------------

  /// Called when a push notification arrives while the app is in the
  /// foreground. Displays a local heads-up notification.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    showLocalNotification(
      notification.title ?? 'Artisan Marketplace',
      notification.body ?? '',
      data: message.data,
    );
  }

  // ---------------------------------------------------------------------------
  // Local notification display
  // ---------------------------------------------------------------------------

  /// Displays a local notification with the given [title] and [body].
  ///
  /// An optional [data] map is serialized into the notification payload so
  /// it can be recovered when the user taps the notification.
  Future<void> showLocalNotification(
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Notification tap handling
  // ---------------------------------------------------------------------------

  /// Invoked when the user taps a local notification.
  ///
  /// The [response] payload contains a JSON-encoded map of the original
  /// push data, which can be used for in-app navigation.
  void onNotificationTap(NotificationResponse response) {
    if (response.payload == null || response.payload!.isEmpty) return;

    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;

      // Route based on the notification type embedded in the payload.
      // The actual navigation logic should be delegated to the app's
      // router / navigation controller. Example:
      //
      //   final type = data['type'] as String?;
      //   final id = data['id'] as String?;
      //   NavigationService.navigateToNotification(type, id);
      //
      // For now we leave this as a hook that consumers can override or
      // extend via a callback.
      _onNotificationTapCallback?.call(data);
    } catch (_) {
      // Malformed payload -- silently ignore.
    }
  }

  /// Optional callback that consumers can set to handle notification taps.
  void Function(Map<String, dynamic> data)? _onNotificationTapCallback;

  /// Registers a callback invoked when the user taps a notification.
  void setOnNotificationTap(
    void Function(Map<String, dynamic> data) callback,
  ) {
    _onNotificationTapCallback = callback;
  }
}
