import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'message_bubble.dart';
import '../models/message_model.dart';
import '../theme/brand_colors.dart';

class MockChatPreview extends StatelessWidget {
  const MockChatPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final messages = [
      MessageModel(
        id: '1',
        senderId: 'user1',
        senderName: 'Alice',
        text: 'Hey! Did you check out the new design?',
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
      MessageModel(
        id: '2',
        senderId: 'me',
        senderName: 'Me',
        text: 'Yes, it looks amazing! Very clean and stark.',
        timestamp: now.subtract(const Duration(minutes: 4)),
      ),
      MessageModel(
        id: '3',
        senderId: 'user1',
        senderName: 'Alice',
        text: 'I know right? The real-time messaging is so fast too ⚡',
        timestamp: now.subtract(const Duration(minutes: 1)),
      ),
    ];

    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return Transform(
      // Subtle 3D tilt
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(0.02)
        ..rotateY(-0.02),
      alignment: FractionalOffset.center,
      child: Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.05),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Container(
          // Simulate an inner phone bezel
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
              width: 8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mock App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                      child: Text('A', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alice',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Online',
                            style: theme.textTheme.labelSmall?.copyWith(color: BrandColors.online),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.video_call_rounded, size: 28, color: isDark ? Colors.white70 : Colors.black54),
                    const SizedBox(width: 16),
                    Icon(Icons.more_vert_rounded, size: 24, color: isDark ? Colors.white70 : Colors.black54),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: borderColor),
              const SizedBox(height: 24),
              // Mock Messages
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: messages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final msg = entry.value;
                    final isSelf = msg.senderId == 'me';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: MessageBubble(
                        message: msg,
                        isSelf: isSelf,
                        showSenderName: !isSelf,
                        isFirstInGroup: true,
                        isLastInGroup: true,
                      ),
                    )
                    .animate(delay: (index * 400 + 400).ms)
                    .fade(duration: 600.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutQuart);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
