import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;

/// Sets up a message listener on the window to receive notification clicks
/// propagated by the firebase-messaging-sw.js service worker.
void setupWebNotificationClickListener(void Function(String roomId) onClick) {
  html.window.onMessage.listen((event) {
    final data = event.data;
    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map && parsed['type'] == 'NOTIFICATION_CLICK') {
          final roomId = parsed['roomId'] as String?;
          if (roomId != null) {
            onClick(roomId);
          }
        }
      } catch (_) {
        // Ignore parse errors from other messages
      }
    }
  });
}

/// Waits for the firebase-messaging-sw.js service worker registration to complete and activate.
Future<void> waitForServiceWorkerReady() async {
  int attempts = 0;
  while (attempts < 50) {
    final hasFlag = js.context.hasProperty('fcmServiceWorkerRegistered') &&
        js.context['fcmServiceWorkerRegistered'] == true;
    if (hasFlag) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 100));
    attempts++;
  }
}

/// Displays a foreground web push notification using the browser's Notification API.
void showWebNotification(String title, String body, String roomId) {
  if (html.Notification.permission == 'granted') {
    final notification = html.Notification(title, body: body, icon: '/favicon.png');
    notification.onClick.listen((_) {
      html.window.postMessage(jsonEncode({'type': 'NOTIFICATION_CLICK', 'roomId': roomId}), '*');
      notification.close();
    });
  }
}
