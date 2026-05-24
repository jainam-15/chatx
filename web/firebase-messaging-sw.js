importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize Firebase App in service worker. Must match the options in DefaultFirebaseOptions.web
firebase.initializeApp({
  apiKey: 'AIzaSyCLnrhJM2n2D9BLmtdKg0OeMpG89peTjUg',
  appId: '1:464056919731:web:333a8a101aeeb1cbcdb2c6',
  messagingSenderId: '464056919731',
  projectId: 'chatx-v2-a88a5',
  authDomain: 'chatx-v2-a88a5.firebaseapp.com',
  storageBucket: 'chatx-v2-a88a5.firebasestorage.app',
  measurementId: 'G-DC6CT96R10',
});

const messaging = firebase.messaging();

// Handle background notification triggers
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message: ', JSON.stringify(payload));

  const notificationTitle = payload.notification?.title || 'New Message';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/favicon.png',
    data: payload.data, // Attach payload data for click navigation
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click events (wake up and focus/open app)
self.addEventListener('notificationclick', function(event) {
  console.log('[firebase-messaging-sw.js] Notification clicked: ', event.notification);
  event.notification.close();

  // Retrieve chatId from payload data
  const roomId = event.notification.data?.chatId || event.notification.data?.roomId;
  console.log('[firebase-messaging-sw.js] Extracted chatId/roomId: ', roomId);
  
  // Define target paths for both hash routing and path URL strategy
  const targetPath = roomId ? `/chat/${roomId}` : '/chat';
  const targetHashPath = roomId ? `/#/chat/${roomId}` : '/#/chat';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // 1. If a tab is already open, focus it and notify the app of the click
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url.indexOf(self.location.origin) === 0 && 'focus' in client) {
          client.postMessage(JSON.stringify({
            type: 'NOTIFICATION_CLICK',
            roomId: roomId
          }));
          return client.focus();
        }
      }
      
      // 2. If no tab is open, open a new window with the deep-linked path
      // We check if clients.openWindow is supported (it is on most modern browsers)
      if (clients.openWindow) {
        // Standard Flutter web builds often use hash routing by default, but we support both
        return clients.openWindow(targetHashPath);
      }
    })
  );
});
