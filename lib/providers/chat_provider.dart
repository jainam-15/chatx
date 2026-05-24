import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';
import '../core/utils/logger.dart';

// Explicit selected chat provider (used to determine which room is selected in desktop UI)
final selectedChatProvider = StateProvider<String?>((ref) => null);

// Streams all chat rooms where the current user is a participant
final chatRoomsStreamProvider = StreamProvider.autoDispose<List<ChatRoomModel>>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) {
    return Stream.value([]);
  }
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.streamChatRooms(userId);
});

// Message load limit provider for scroll pagination
final activeRoomLimitProvider = StateProvider.autoDispose<int>((ref) => 50);

// Streams messages for a specific chat room
final messagesStreamProvider = StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, roomId) {
  final limit = ref.watch(activeRoomLimitProvider);
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.streamMessages(roomId, limit: limit);
});

// Streams all users in the system (e.g. to search and start a new chat)
final allUsersStreamProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.streamAllUsers();
});

// Chat action controller
final chatControllerProvider = Provider<ChatController>((ref) {
  return ChatController(ref);
});

class ChatController {
  final Ref _ref;
  static const String _tag = 'ChatController';

  ChatController(this._ref);

  // Send a text message to a specific room
  Future<void> sendTextMessage(String roomId, String text) async {
    final userProfile = _ref.read(currentUserProvider);

    if (roomId.isEmpty) {
      Logger.warning(_tag, 'Cannot send message: no active chat room selected');
      return;
    }
    if (userProfile == null) {
      Logger.warning(_tag, 'Cannot send message: no authenticated user profile');
      return;
    }
    if (text.trim().isEmpty) return;

    final db = _ref.read(databaseServiceProvider);
    final messageId = _ref.read(databaseServiceProvider)._firestore.collection('placeholder').doc().id; // Get a unique Firestore doc ID

    final message = MessageModel(
      id: messageId,
      senderId: userProfile.id,
      senderName: userProfile.displayName ?? userProfile.email.split('@')[0],
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      final sendTime = message.timestamp;
      Logger.info(_tag, 'Message Send Telemetry: Message ${message.id} sent locally at ${sendTime.toIso8601String()}');
      await db.sendMessage(roomId, message);
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to send text message', e, stack);
    }
  }

  // Start/retrieve DM room with another user
  Future<String> startDirectChat(String targetUserId) async {
    final self = _ref.read(currentUserProvider);
    if (self == null) {
      throw Exception('Must be authenticated to start a chat');
    }

    final db = _ref.read(databaseServiceProvider);
    try {
      final room = await db.createDirectChatRoom(self.id, targetUserId);
      _ref.read(selectedChatProvider.notifier).state = room.id;
      return room.id;
    } catch (e, stack) {
      Logger.error(_tag, 'Failed to establish direct chat room', e, stack);
      rethrow;
    }
  }

  // Clear unread badge for active user in specific room
  Future<void> clearRoomUnreads(String roomId) async {
    final self = _ref.read(currentUserProvider);
    if (self == null) return;

    final db = _ref.read(databaseServiceProvider);
    await db.clearUnreadCount(roomId, self.id);
  }

  // Mark messages inside the room as read by the active user
  Future<void> markRoomMessagesAsRead(String roomId, String userId) async {
    final db = _ref.read(databaseServiceProvider);
    await db.markMessagesAsRead(roomId, userId);
  }
}

// Extension to access internal firestore instance safely for ID generation
extension on DatabaseService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
}
