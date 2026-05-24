# Firestore Optimization & Debugging Report

This document outlines the stream lifecycle flows, write operations, and the recent architectural optimizations implemented to prevent `RESOURCE_EXHAUSTED` (quota exceeded) errors.

## 1. Stream Lifecycle & Active Listeners

The application utilizes Riverpod's `StreamProvider.autoDispose` to manage Firestore snapshot listeners. This guarantees that streams are automatically shut down when the user navigates away from the dependent UI.

### Active Listeners
| Provider / Service | Path | Purpose | Lifecycle |
| --- | --- | --- | --- |
| `_profileSubscription` | `users/{userId}` | Tracks real-time online status and active chat state of the current user. | Starts on login, cancels on logout. Re-evaluated only on `authStateChanges`. |
| `chatRoomsStreamProvider` | `chat_rooms` | Populates the list of rooms where the user is a participant. | Disposed when `ChatListScreen` is unmounted. Re-fetches only if user ID changes. |
| `activeMessagesStreamProvider` | `chat_rooms/{roomId}/messages` | Streams the latest 50 messages for the active conversation. | Disposed when `ChatDetailScreen` unmounts or `activeRoomIdProvider` changes. |
| `allUsersStreamProvider` | `users` | Streams user directory to start new direct messages. | Disposed when the new chat modal/screen is closed. |

> **Warning**
> Previously, `chatRoomsStreamProvider` and `activeChatSyncProvider` watched the entire `currentUserProvider`. If a user's `isOnline` or `activeChatId` changed, it forced a complete teardown and rebuild of the listeners. This has been fixed by using `.select((user) => user?.id)`, which only watches for ID changes.

## 2. Firestore Write Operations & Safeguards

To prevent repeated or infinite writes, we implemented aggressive in-memory deduplication and debouncing at the `DatabaseService` layer.

### Write Operations
1. **User Presence (`updateUserPresence`)**
   - **Trigger:** App lifecycle changes (foreground/background) or profile load.
   - **Safeguard:** Throttled. The system checks `_lastIsOnline` and `_lastActiveTime`. Identical presence states are ignored if updated within the last 60 seconds.
2. **Active Chat Sync (`updateUserActiveChat`)**
   - **Trigger:** Navigating between chat rooms (updates `activeChatId` for push notification suppression).
   - **Safeguard:** Debounced by 500ms using a `Timer` in `activeChatSyncProvider`. Furthermore, `DatabaseService` caches `_lastActiveChatId` and drops identical updates before making network calls.
3. **FCM Token (`updateUserFcmToken`)**
   - **Trigger:** Login, token refresh, or app start.
   - **Safeguard:** Caches `_lastFcmToken` and drops identical updates.
4. **Message Sends (`sendMessage`)**
   - **Trigger:** User sends a message.
   - **Flow:** Writes to `messages` collection, then asynchronously updates `chat_rooms` metadata (last message, unread counts).
5. **Read Receipts (`markMessagesAsRead`)**
   - **Trigger:** User views a room with unread messages.
   - **Safeguard:** Uses an atomic batch write, restricted to the last 50 messages, and only modifies documents where the user ID isn't already in the `readBy` array.

## 3. Quota Leak Sources (Resolved)

The `RESOURCE_EXHAUSTED` errors were primarily caused by a cyclic dependency loop during the notification implementation:

1. **The Infinite Loop (Fixed):**
   - User opens a chat -> `activeChatSyncProvider` writes `roomId` to Firestore.
   - Firestore updates user document -> `_profileSubscription` emits new profile.
   - `currentUserProvider` updates -> `activeChatSyncProvider` detects a change and disposes itself.
   - During disposal, it writes `null` to Firestore.
   - It is immediately recreated, writing `roomId` to Firestore again.
   - **Result:** Thousands of writes and reads per minute.
   - **Fix:** Switched `ref.watch(currentUserProvider)` to `ref.watch(currentUserProvider.select((user) => user?.id))`.

2. **Stream Recreation Spam (Fixed):**
   - Same as above, `chatRoomsStreamProvider` was being torn down and re-established repeatedly, racking up document read charges.
   - **Fix:** `.select()` ensures the stream is only created once per authentication session.

3. **Notification Background Hooks (Optimized):**
   - **Fix:** Web FCM initialization `getToken()` no longer triggers redundant writes if the token is already cached in `DatabaseService`.

## 4. Architectural Guidelines for Future Work

- **Never `watch` entire profile objects in StreamProviders.** Always use `.select()` to extract primitive, unchanging keys (like `userId`) to prevent stream churn.
- **Always deduplicate writes.** Use the `_last*` state variables in `DatabaseService` before executing an `update()` or `set()`.
- **Prefer `merge: true` or `update()`** over replacing entire documents to minimize bandwidth and indexing overhead.
