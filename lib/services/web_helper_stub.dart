/// Stub listener helper for mobile environments.
void setupWebNotificationClickListener(void Function(String roomId) onClick) {
  // No-op on mobile platforms.
}

/// Stub waiter for service worker on mobile environments.
Future<void> waitForServiceWorkerReady() async {
  // No-op on mobile platforms.
}

void showWebNotification(String title, String body, String roomId) {
  // No-op on mobile platforms.
}
