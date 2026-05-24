# Firebase Cloud Messaging Debugging Checklist

This guide explains how notifications flow through the application, where listeners execute, how to test each scenario, and common failure points.

## How Notifications Flow

1. **Sender Action:** User A sends a message. The app writes the message to Firestore locally (`DatabaseService.sendMessage`).
2. **Cloud Function:** Firestore triggers `functions/index.js` (`onCreate`).
3. **Suppression Logic:** 
   - The cloud function checks if User B has an FCM token.
   - It checks if User B's `activeChatId` matches the `chatId`. 
   - If conditions are met, it sends the payload to FCM.
4. **FCM Delivery:** FCM routes the message to User B's device based on the token.

## Where Listeners Execute

| App State | Platform | Execution Context | Action |
| --- | --- | --- | --- |
| **Foreground** | Android/iOS | Main Flutter Isolate (`FirebaseMessaging.onMessage`) | Shows heads-up UI via `flutter_local_notifications`. |
| **Background** | Android/iOS | Background Isolate (`FirebaseMessaging.onBackgroundMessage`) | OS shows system tray. Background isolate executes silently. |
| **Terminated** | Android/iOS | Background Isolate (`FirebaseMessaging.onBackgroundMessage`) | OS shows system tray. Flutter isolate boots up purely to run the background handler. |
| **Foreground** | Web | Main Thread (`FirebaseMessaging.onMessage`) | Silently logged. |
| **Background/Closed**| Web | Service Worker (`firebase-messaging-sw.js`) | Spawns system notification. |

## How to Test Each Case

### 1. Foreground Notifications
- **Test:** Keep the app open on the chat list (not the active chat). Send a message from another user.
- **Expected:** A heads-up notification drops down from the top of the screen.
- **Verify Log:** `Received foreground message: <Sender Name>`

### 2. Background Notifications
- **Test:** Press the Home button to background the app. Send a message.
- **Expected:** System tray notification appears.
- **Verify Log:** `Handling background message: <MessageID>`

### 3. Terminated/Killed App Notifications
- **Test:** Swipe the app away from the recent apps list. Send a message.
- **Expected:** System tray notification appears.
- **Verify Log:** Connect via `adb logcat | grep flutter` to verify the background isolate boots and logs `Handling background message`.

### 4. Notification Tap Navigation
- **Test:** Tap the notification from the system tray (both background and terminated states).
- **Expected:** The app opens and navigates directly to the chat room.
- **Verify Log:** `App opened from terminated state by message` OR `Notification tap detected!`

## Common Failure Points

1. **Terminated Pushes Not Arriving:** 
   - **Cause:** The background handler was registered inside a class that wasn't initialized in the background isolate.
   - **Fix:** We moved `FirebaseMessaging.onBackgroundMessage` to `main.dart` right after `Firebase.initializeApp()`.
2. **Clicking Notification Does Nothing:** 
   - **Cause:** The payload key mismatch (`roomId` vs `chatId`).
   - **Fix:** We updated the payload to include `chatId`, `senderId`, `senderName`, and updated the click handlers to parse `chatId`.
3. **Receiving Pushes After Logout:** 
   - **Cause:** The token was nulled in Firestore but not deleted from the device.
   - **Fix:** `deleteToken()` is now called during sign out.
4. **Web Pushes Not Arriving:** 
   - **Cause:** Service worker not registered or scope mismatch.
   - **Fix:** Ensure `web/index.html` registers `/firebase-messaging-sw.js` correctly and the script intercepts `onBackgroundMessage`.
