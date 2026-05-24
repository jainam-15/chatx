import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatx_interview_task/app.dart';
import 'package:chatx_interview_task/providers/auth_provider.dart';
import 'package:chatx_interview_task/services/auth_service.dart';
import 'package:chatx_interview_task/services/database_service.dart';
import 'package:chatx_interview_task/services/notification_service.dart';
import 'package:chatx_interview_task/models/user_model.dart';
import 'package:chatx_interview_task/models/chat_room_model.dart';
import 'package:chatx_interview_task/models/message_model.dart';

class MockAuthService implements AuthService {
  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

class MockDatabaseService implements DatabaseService {
  @override
  Future<void> createUserProfile(UserModel user) async {}

  @override
  Future<UserModel?> getUserProfile(String userId, {bool forceFetch = false}) async => null;

  @override
  Stream<UserModel?> streamUserProfile(String userId) => Stream.value(null);

  @override
  Stream<List<UserModel>> streamAllUsers() => Stream.value([]);

  @override
  Stream<List<ChatRoomModel>> streamChatRooms(String userId) => Stream.value([]);

  @override
  Stream<List<MessageModel>> streamMessages(String roomId, {int limit = 50}) => Stream.value([]);

  @override
  Future<void> sendMessage(String roomId, MessageModel message) async {}

  @override
  Future<ChatRoomModel> createDirectChatRoom(String userA, String userB) async {
    throw UnimplementedError();
  }

  @override
  Future<void> clearUnreadCount(String roomId, String userId) async {}

  @override
  Future<void> updateUserPresence(String userId, bool isOnline) async {}

  @override
  Future<void> updateUserActiveChat(String userId, String? roomId) async {}

  @override
  Future<void> updateUserFcmToken(String userId, String? token) async {}

  @override
  Future<void> markMessagesAsRead(String roomId, String userId) async {}
}

class MockNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => 'mock-token';

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
}

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app with service overrides to bypass real Firebase connection requirements.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService()),
          databaseServiceProvider.overrideWithValue(MockDatabaseService()),
          notificationServiceProvider.overrideWithValue(MockNotificationService()),
        ],
        child: const ChatXApp(),
      ),
    );

    // Verify if MaterialApp.router is rendered successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
