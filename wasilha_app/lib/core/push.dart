import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../data/backend.dart';
import '../theme/tokens.dart';

/// Global keys so push handling can navigate / show banners from anywhere.
final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Background messages are displayed by the OS; nothing to do here, but the
/// handler must exist as a top-level function.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {}

/// Firebase Cloud Messaging wiring. Cloud Functions (functions/src/index.ts)
/// send messages with `data.route` (e.g. "offer", "tracking", "driverRequests")
/// so a tap opens the right screen.
class PushService {
  PushService._();

  static bool _started = false;
  static StreamSubscription<String>? _tokenSub;

  /// Call once the user is signed in (Firebase mode only).
  static Future<void> start(WasilhaBackend backend) async {
    if (backend.isDemo || _started) return;
    _started = true;
    try {
      final fm = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
      final settings = await fm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await fm.getToken();
      if (token != null) await backend.registerPushToken(token);
      _tokenSub = fm.onTokenRefresh.listen(backend.registerPushToken);

      // App open: show an in-app banner.
      FirebaseMessaging.onMessage.listen(_showBanner);
      // Tapped while in background, or launched from a notification.
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      final initial = await fm.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (e) {
      debugPrint('Push setup failed: $e');
    }
  }

  static Future<void> stop() async {
    await _tokenSub?.cancel();
    _started = false;
  }

  static void _open(RemoteMessage m) {
    final route = m.data['route'];
    if (route is String && route.isNotEmpty) {
      navigatorKey.currentState?.pushNamed(route, arguments: m.data['tripId']);
    }
  }

  static void _showBanner(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    messengerKey.currentState?.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: W.text,
      duration: const Duration(seconds: 5),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (n.title != null) Text(n.title!, style: W.sans(size: 14, weight: FontWeight.w600, color: Colors.white)),
        if (n.body != null) Text(n.body!, style: W.sans(size: 13, color: Colors.white70)),
      ]),
      action: m.data['route'] == null
          ? null
          : SnackBarAction(label: 'Open', textColor: Colors.white, onPressed: () => _open(m)),
    ));
  }
}
