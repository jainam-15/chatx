import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/routing/route_paths.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/ambient_background.dart';
import '../widgets/liquid_glass.dart';
import 'chat_list_screen.dart';
import 'chat_detail_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  final String? selectedRoomId;

  const ShellScreen({
    super.key,
    this.selectedRoomId,
  });

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex = 0; // 0: Chats, 1: Profile

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final selectedRoomId = widget.selectedRoomId;

    // Use a Stack to overlay the floating bottom navigation
    return Scaffold(
      body: AmbientBackground(
        child: Stack(
          children: [
            // Main Content Layer
            Positioned.fill(
              child: _buildMainContent(width, selectedRoomId),
            ),
            
            // Floating Bottom Navigation (Hide on mobile when chat detail is open)
            if (!(width < 800 && selectedRoomId != null))
              width >= 800
                  ? Positioned(
                      left: 0,
                      width: 380, // Same width as the ChatListScreen container
                      bottom: 24,
                      child: SafeArea(
                        child: Center(
                          child: _buildFloatingBottomNav(),
                        ),
                      ),
                    )
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: _buildFloatingBottomNav(),
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double width, String? activeRoomId) {
    if (_currentIndex == 1) {
      return const Center(child: Text('Profile Screen (Coming Soon)'));
    }

    if (width < 800) {
      // Mobile / narrow layout
      if (activeRoomId != null) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            ref.read(selectedChatProvider.notifier).state = null;
            context.go(RoutePaths.chatList);
          },
          child: ChatDetailScreen(
            roomId: activeRoomId,
            onBack: () {
              ref.read(selectedChatProvider.notifier).state = null;
              context.go(RoutePaths.chatList);
            },
          ),
        );
      }
      return ChatListScreen(
        selectedRoomId: activeRoomId,
        onRoomSelected: (roomId) => context.go(RoutePaths.chatDetail.replaceAll(':roomId', roomId)),
      );
    } else {
      // Desktop / wide layout (Split pane)
      return Row(
        children: [
          SizedBox(
            width: 380,
            child: ChatListScreen(
              selectedRoomId: activeRoomId,
              onRoomSelected: (roomId) => context.go(RoutePaths.chatDetail.replaceAll(':roomId', roomId)),
            ),
          ),
          VerticalDivider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2), width: 1),
          Expanded(
            child: activeRoomId != null
                ? ChatDetailScreen(
                    roomId: activeRoomId,
                    onBack: () {
                      ref.read(selectedChatProvider.notifier).state = null;
                      context.go(RoutePaths.chatList);
                    },
                  )
                : _buildPlaceholderView(),
          ),
        ],
      );
    }
  }

  Widget _buildFloatingBottomNav() {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return LiquidGlass(
      borderRadius: 40, // Pill shape
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNavItem(
            icon: Icons.chat_bubble_rounded,
            isSelected: _currentIndex == 0,
            onTap: () {
              setState(() => _currentIndex = 0);
              context.go(RoutePaths.chatList);
            },
          ),
          const SizedBox(width: 16),
          _buildNavItem(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            isSelected: false,
            onTap: () {
              ref.read(themeModeProvider.notifier).updateTheme(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          const SizedBox(width: 16),
          _buildNavItem(
            icon: Icons.person_rounded,
            isSelected: _currentIndex == 1,
            onTap: () => setState(() => _currentIndex = 1),
          ),
          const SizedBox(width: 16),
          _buildNavItem(
            icon: Icons.logout_rounded,
            isSelected: false,
            onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = isDark ? Colors.white.withOpacity(0.6) : Colors.black87;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(
          icon,
          color: isSelected ? selectedColor : (color ?? unselectedColor),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPlaceholderView() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.mark_chat_unread_rounded,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No conversation selected',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a chat to start messaging.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
