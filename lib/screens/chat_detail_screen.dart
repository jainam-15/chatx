import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user_model.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../theme/brand_colors.dart';
import '../core/utils/logger.dart';
import '../services/database_service.dart';
import '../widgets/ambient_background.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  final VoidCallback? onBack;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    this.onBack,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  
  late final DatabaseService _db;
  late final String? _userId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    print("[ACTIVE_CHAT] Entering room: ${widget.roomId}");
    
    // Safely capture dependencies to avoid defunct access during dispose
    _db = ref.read(databaseServiceProvider);
    _userId = ref.read(currentUserProvider)?.id;

    if (_userId != null) {
      print("[ACTIVE_CHAT] Setting activeChatId -> ${widget.roomId}");
      _db.updateUserActiveChat(_userId!, widget.roomId);
    }
  }

  @override
  void dispose() {
    print("[ACTIVE_CHAT] Leaving room: ${widget.roomId}");
    if (_userId != null) {
      print("[ACTIVE_CHAT] Clearing activeChatId");
      _db.updateUserActiveChat(_userId!, null);
    }
    
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // User scrolled near the top (which is maxScrollExtent in a reversed list)
      Logger.debug('ChatDetailScreen', 'Top of scroll reached, requesting older messages...');
      ref.read(activeRoomLimitProvider.notifier).update((state) => state + 50);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('========== CHAT DETAIL SCREEN ==========');
    print('CURRENT OPEN CHAT = ${widget.roomId}');
    print('========================================');

    final theme = Theme.of(context);
    final messagesAsync = ref.watch(messagesStreamProvider(widget.roomId));
    final usersAsync = ref.watch(allUsersStreamProvider);
    final self = ref.watch(currentUserProvider);
    final roomsAsync = ref.watch(chatRoomsStreamProvider);

    // 1. Resolve other user info
    String otherUserName = 'Conversation';
    bool otherUserOnline = false;

    final room = roomsAsync.value?.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => throw Exception('Room not found'),
    );

    if (room != null && self != null) {
      final otherUserId = room.participantIds.firstWhere(
        (id) => id != self.id,
        orElse: () => '',
      );

      final otherUser = usersAsync.value?.firstWhere(
        (u) => u.id == otherUserId,
        orElse: () => UserModel(id: otherUserId, email: '', displayName: 'User'),
      );

      if (otherUser != null) {
        otherUserName = otherUser.displayName ?? otherUser.email;
        otherUserOnline = otherUser.isOnline;
      }
    }

    // Handle new messages and read status synchronization
    ref.listen(messagesStreamProvider(widget.roomId), (prev, next) {
      if (next.hasValue && next.value!.isNotEmpty) {
        final messages = next.value!;
        if (self != null) {
          final hasUnread = messages.any((m) => m.senderId != self.id && !m.readBy.contains(self.id));
          if (hasUnread) {
            ref.read(chatControllerProvider).markRoomMessagesAsRead(widget.roomId, self.id);
            ref.read(chatControllerProvider).clearRoomUnreads(widget.roomId);
          }
        }
        _scrollToBottom();
      }
    });

    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget content = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: widget.onBack,
              )
            : null,
        titleSpacing: widget.onBack != null ? 0 : null,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                otherUserName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: theme.textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Container(
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: otherUserOnline ? BrandColors.online : BrandColors.offline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        otherUserOnline ? 'Active now' : 'Offline',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Scroll to bottom once messages load
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                final reversedMessages = messages.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Render from bottom up for smooth pagination offsets
                  itemCount: reversedMessages.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final message = reversedMessages[index];
                    final isSelf = message.senderId == self?.id;

                    // Calculate consecutive grouping indices
                    final prevMessage = (index + 1 < reversedMessages.length)
                        ? reversedMessages[index + 1]
                        : null;
                    final nextMessage = (index - 1 >= 0)
                        ? reversedMessages[index - 1]
                        : null;

                    final isFirstInGroup = prevMessage == null ||
                        prevMessage.senderId != message.senderId ||
                        message.timestamp.difference(prevMessage.timestamp).inMinutes > 5;

                    final isLastInGroup = nextMessage == null ||
                        nextMessage.senderId != message.senderId ||
                        nextMessage.timestamp.difference(message.timestamp).inMinutes > 5;

                    return MessageBubble(
                      message: message,
                      isSelf: isSelf,
                      isFirstInGroup: isFirstInGroup,
                      isLastInGroup: isLastInGroup,
                    );
                  },
                );
              },
              loading: () => const LoadingView(message: 'Loading messages...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(messagesStreamProvider(widget.roomId)),
              ),
            ),
          ),
          ChatInputBar(
            onSendMessage: (text) => ref.read(chatControllerProvider).sendTextMessage(widget.roomId, text),
          ),
        ],
      ),
    );

    // Only wrap in AmbientBackground if we're on mobile (single pane) and it's full screen
    if (isMobile && widget.onBack != null) {
      return AmbientBackground(child: content);
    }
    return content;
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start the Conversation',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to say hello! Your conversation is real-time and fully synchronized.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
