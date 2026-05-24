import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../core/utils/logger.dart';

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tag = 'DatabaseService';

  // Create or update user profile
  Future<void> createUserProfile(UserModel user) async {
    try {
      Logger.info(_tag, 'Creating user profile: ${user.id}');
      await _firestore.collection('users').doc(user.id).set(
            user.toMap(),
            SetOptions(merge: true),
          );
      Logger.info(_tag, 'User profile created successfully');
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to create user profile', e, stack);
      throw DatabaseException('Failed to store user profile data.');
    }
  }

  UserModel? _cachedUserProfile;

  // Get user profile once
  Future<UserModel?> getUserProfile(String userId, {bool forceFetch = false}) async {
    if (!forceFetch && _cachedUserProfile != null && _cachedUserProfile!.id == userId) {
      Logger.debug(_tag, 'Returning cached user profile for $userId');
      return _cachedUserProfile;
    }
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      _cachedUserProfile = UserModel.fromMap(doc.data()!);
      return _cachedUserProfile;
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to get user profile', e, stack);
      throw DatabaseException('Failed to load user profile data.');
    }
  }

  // Stream user profile
  Stream<UserModel?> streamUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      _cachedUserProfile = UserModel.fromMap(snapshot.data()!);
      return _cachedUserProfile;
    });
  }

  // Stream all users for starting new chat rooms
  Stream<List<UserModel>> streamAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Stream chat rooms for a specific user
  Stream<List<ChatRoomModel>> streamChatRooms(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoomModel.fromMap(doc.data()))
          .toList();
      // Client-side sort as fallback, or to handle no-index environments gracefully
      rooms.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      return rooms;
    });
  }

  // Stream messages in a chat room with a query pagination limit
  Stream<List<MessageModel>> streamMessages(String roomId, {int limit = 50}) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      Logger.debug(_tag, 'Stream Receive Telemetry: Received snapshot with ${snapshot.docs.length} messages at ${DateTime.now().toIso8601String()}');
      final messages = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
      // Reverse back to chronological order (oldest first) for UI rendering
      return messages.reversed.toList();
    });
  }

  // Mark messages as read by the current user (Atomic batch of the most recent 50 messages)
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final batch = _firestore.batch();
      bool hasUpdates = false;

      for (final doc in snapshot.docs) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        final senderId = doc.data()['senderId'] as String;

        if (senderId != userId && !readBy.contains(userId)) {
          readBy.add(userId);
          batch.update(doc.reference, {'readBy': readBy});
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
        Logger.debug(_tag, 'Marked messages as read in room: $roomId');
      }
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to mark messages as read', e, stack);
    }
  }

  // Send message and update chat room metadata instantly
  Future<void> sendMessage(String roomId, MessageModel message) async {
    try {
      final roomRef = _firestore.collection('chat_rooms').doc(roomId);
      final messageRef = roomRef.collection('messages').doc(message.id);

      // 1. Write the message immediately to trigger optimistic UI locally.
      // We inject serverTimestamp here.
      final messageData = message.toMap();
      messageData['serverTimestamp'] = FieldValue.serverTimestamp();
      
      await messageRef.set(messageData);
      Logger.info(_tag, 'Firestore Write Completion Telemetry: Message ${message.id} written at ${DateTime.now().toIso8601String()}');

      // 2. Fire-and-forget: Fetch the room to update unread counts and last message (async)
      _updateRoomMetadata(roomRef, message).catchError((e, stack) {
        Logger.error(_tag, 'Failed to update room metadata after sending', e, stack);
      });
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to send message', e, stack);
      throw DatabaseException('Failed to transmit message.');
    }
  }

  Future<void> _updateRoomMetadata(DocumentReference roomRef, MessageModel message) async {
    final roomSnap = await roomRef.get();
    if (roomSnap.exists) {
      final room = ChatRoomModel.fromMap(roomSnap.data()! as Map<String, dynamic>);
      final Map<String, dynamic> unreadUpdates = {};

      // Increment unread count for other participants
      for (final pId in room.participantIds) {
        if (pId != message.senderId) {
          final currentUnread = room.unreadCounts[pId] ?? 0;
          unreadUpdates['unreadCounts.$pId'] = currentUnread + 1;

          // Trigger Railway backend notification API
          print("========== FRONTEND NOTIFICATION TRIGGER ==========");
          print("Source: _updateRoomMetadata loop");
          print("Room ID fetched from Firestore snap: ${room.id}");
          print("Passing chatId to _sendNotification: ${room.id}");
          print("====================================================");
          
          _sendNotification(
            senderName: message.senderName,
            receiverId: pId,
            messageText: message.text,
            chatId: room.id,
          );
        }
      }

      // Update room with last message info
      unreadUpdates['lastMessage'] = message.text;
      unreadUpdates['lastMessageTime'] = message.timestamp.millisecondsSinceEpoch;
      unreadUpdates['lastMessageSenderId'] = message.senderId;

      await roomRef.update(unreadUpdates);
    }
  }

  // Create chat room (if it doesn't already exist)
  Future<ChatRoomModel> createDirectChatRoom(String userA, String userB) async {
    try {
      // Check if room with exactly these participants exists
      final query = await _firestore
          .collection('chat_rooms')
          .where('participantIds', arrayContains: userA)
          .get();

      for (final doc in query.docs) {
        final room = ChatRoomModel.fromMap(doc.data());
        if (!room.isGroup &&
            room.participantIds.contains(userB) &&
            room.participantIds.length == 2) {
          return room;
        }
      }

      // If not, create a new one
      final roomId = _firestore.collection('chat_rooms').doc().id;
      final newRoom = ChatRoomModel(
        id: roomId,
        isGroup: false,
        participantIds: [userA, userB],
        unreadCounts: {userA: 0, userB: 0},
      );

      await _firestore.collection('chat_rooms').doc(roomId).set(newRoom.toMap());
      return newRoom;
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to create chat room', e, stack);
      throw DatabaseException('Failed to establish conversation room.');
    }
  }

  Future<void> _sendNotification({
    required String senderName,
    required String receiverId,
    required String messageText,
    required String chatId,
  }) async {
    try {
      final receiverProfile = await getUserProfile(receiverId, forceFetch: true);
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastActive = receiverProfile?.lastActive?.millisecondsSinceEpoch ?? 0;
      final isStale = (now - lastActive) > 60000;
      
      // Safety timeout: If heartbeat/update is older than 60s, treat as offline
      final isEffectivelyOnline = (receiverProfile?.isOnline == true) && !isStale;

      // Check if user is actively viewing this specific chat room
      if (isEffectivelyOnline && receiverProfile?.activeChatId == chatId) {
        Logger.info(_tag, 'Skipping notification: Receiver $receiverId is actively viewing chat $chatId');
        return;
      }

      final receiverToken = receiverProfile?.fcmToken;

      if (receiverToken == null || receiverToken.isEmpty) {
        Logger.warning(_tag, 'Cannot send notification: Receiver $receiverId has no FCM token');
        return;
      }

      final url = Uri.parse('https://chatx-backend-production-c569.up.railway.app/sendNotification');
      
      print("========== FRONTEND SENDING TO BACKEND ==========");
      print("Payload chatId: $chatId");
      print("Receiver activeChatId: ${receiverProfile?.activeChatId}");
      print("=================================================");
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'receiverToken': receiverToken,
          'receiverActiveChatId': receiverProfile?.activeChatId,
          'senderName': senderName,
          'message': messageText,
          'chatId': chatId,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        Logger.info(_tag, 'Notification sent successfully to receiver: $receiverId');
      } else {
        Logger.warning(_tag, 'Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      Logger.error(_tag, 'Error calling notification API', e, stack);
    }
  }

  // Reset unread count for a user in a specific room
  Future<void> clearUnreadCount(String roomId, String userId) async {
    try {
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to clear unread count', e, stack);
    }
  }

  bool? _lastIsOnline;
  int _lastActiveTime = 0;

  // Update online presence status
  Future<void> updateUserPresence(String userId, bool isOnline) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Debounce/Throttle: Only update lastSeen if more than 60 seconds have passed or online status changed
    if (_lastIsOnline == isOnline && (now - _lastActiveTime) < 60000) {
      Logger.debug(_tag, 'Throttled user presence update for $userId');
      return;
    }
    
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastActive': now,
      });
      _lastIsOnline = isOnline;
      _lastActiveTime = now;
      Logger.debug(_tag, 'Updated presence for $userId: isOnline=$isOnline');
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to update user presence', e, stack);
    }
  }

  String? _lastActiveChatId;

  // Update active chat room user is currently viewing
  Future<void> updateUserActiveChat(String userId, String? roomId) async {
    if (_lastActiveChatId == roomId) {
      Logger.debug(_tag, 'Skipped duplicate activeChatId update for $userId');
      return;
    }
    try {
      await _firestore.collection('users').doc(userId).update({
        'activeChatId': roomId,
      });
      _lastActiveChatId = roomId;
      Logger.debug(_tag, 'Updated activeChatId for $userId to $roomId');
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to update user active chat ID', e, stack);
    }
  }

  String? _lastFcmToken;

  // Update FCM token for push notifications routing
  Future<void> updateUserFcmToken(String userId, String? token) async {
    if (_lastFcmToken == token) {
      Logger.debug(_tag, 'Skipped duplicate fcmToken update for $userId');
      return;
    }
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      _lastFcmToken = token;
      Logger.debug(_tag, 'Updated fcmToken for $userId');
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to update user FCM token', e, stack);
    }
  }
}
