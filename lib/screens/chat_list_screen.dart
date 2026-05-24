import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';
import '../theme/brand_colors.dart';

class ChatListScreen extends ConsumerWidget {
  final String? selectedRoomId;
  final Function(String) onRoomSelected;

  const ChatListScreen({
    super.key,
    required this.onRoomSelected,
    this.selectedRoomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(chatRoomsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () => _showStartChatDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rooms.length,
            separatorBuilder: (context, index) => Divider(
              indent: 80,
              endIndent: 16,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _ChatRoomTile(
                room: room,
                isSelected: room.id == selectedRoomId,
                onTap: () {
                  onRoomSelected(room.id);
                  ref.read(chatControllerProvider).clearRoomUnreads(room.id);
                },
              );
            },
          );
        },
        loading: () => const LoadingView(isSkeleton: true),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(chatRoomsStreamProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Conversations Yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a direct chat with anyone in your directory.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showStartChatDialog(context, ref),
              child: const Text('Start Messaging'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStartChatDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final usersAsync = ref.watch(allUsersStreamProvider);
                final self = ref.watch(currentUserProvider);

                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'New Conversation',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: usersAsync.when(
                        data: (users) {
                          // Filter out current user
                          final filteredUsers = users.where((u) => u.id != self?.id).toList();

                          if (filteredUsers.isEmpty) {
                            return const Center(child: Text('No other users found.'));
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Text(
                                    (user.displayName ?? user.email).substring(0, 1).toUpperCase(),
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                                title: Text(user.displayName ?? user.email),
                                subtitle: Text(user.email),
                                onTap: () async {
                                  Navigator.pop(context);
                                  try {
                                    final roomId = await ref
                                        .read(chatControllerProvider)
                                        .startDirectChat(user.id);
                                    if (!context.mounted) return;
                                    onRoomSelected(roomId);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to start chat: $e')),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error loading directory: $err')),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ChatRoomTile extends ConsumerWidget {
  final ChatRoomModel room;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.room,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final self = ref.watch(currentUserProvider);
    final usersAsync = ref.watch(allUsersStreamProvider);

    // Find the other participant's profile
    final otherUserId = room.participantIds.firstWhere(
      (id) => id != self?.id,
      orElse: () => '',
    );

    return usersAsync.when(
      data: (users) {
        final otherUser = users.firstWhere(
          (u) => u.id == otherUserId,
          orElse: () => UserModel(id: otherUserId, email: 'unknown@chatx.com', displayName: 'User'),
        );

        final unreadCount = room.unreadCounts[self?.id] ?? 0;
        final timeStr = room.lastMessageTime != null
            ? '${room.lastMessageTime!.hour.toString().padLeft(2, '0')}:${room.lastMessageTime!.minute.toString().padLeft(2, '0')}'
            : '';

        return ListTile(
          selected: isSelected,
          selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
          onTap: onTap,
          leading: Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    (otherUser.displayName ?? otherUser.email).substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: otherUser.isOnline ? BrandColors.online : BrandColors.offline,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  otherUser.displayName ?? otherUser.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (timeStr.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: unreadCount > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  room.lastMessage ?? 'Draft message...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: unreadCount > 0 ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: BrandColors.brandGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 72),
      error: (error, stackTrace) => const SizedBox(height: 72),
    );
  }
}
