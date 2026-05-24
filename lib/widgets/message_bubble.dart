import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../theme/brand_colors.dart';
import '../core/utils/logger.dart';
import 'liquid_glass.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSelf;
  final bool showSenderName;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSelf,
    this.showSenderName = false,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final renderTime = DateTime.now();
    final sendLatency = renderTime.difference(message.timestamp).inMilliseconds;
    
    // Only log if the message was sent very recently (within 10 seconds) to measure active chat latency
    if (sendLatency >= 0 && sendLatency < 10000) {
      if (message.serverTimestamp != null) {
        final serverLatency = renderTime.difference(message.serverTimestamp!).inMilliseconds;
        Logger.debug('MessageBubble', 'Render Telemetry - Msg ${message.id}: Send Latency = ${sendLatency}ms | Server Latency = ${serverLatency}ms');
      } else {
        Logger.debug('MessageBubble', 'Render Telemetry - Msg ${message.id}: Send Latency = ${sendLatency}ms (Optimistic UI, no server time yet)');
      }
    }

    // Formatting timestamp
    final timeStr = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    final incomingBg = theme.brightness == Brightness.dark 
        ? const Color(0x2A000000) 
        : const Color(0xB3FFFFFF);
        
    final incomingBorder = theme.brightness == Brightness.dark 
        ? const Color(0x33FFFFFF) 
        : const Color(0xE6FFFFFF);

    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      color: isSelf
          ? Colors.white
          : (isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary),
    );

    final timeStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 10,
      color: isSelf
          ? Colors.white.withOpacity(0.7)
          : (isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary),
    );

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isSelf ? 20 : (isLastInGroup ? 4 : 20)),
      bottomRight: Radius.circular(isSelf ? (isLastInGroup ? 4 : 20) : 20),
    );

    Widget bubbleContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              message.text,
              style: textStyle,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: timeStyle,
              ),
              if (isSelf) ...[
                const SizedBox(width: 4),
                Icon(
                  message.readBy.isNotEmpty ? Icons.done_all : Icons.done,
                  size: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          top: isFirstInGroup ? 6 : 2,
          bottom: isLastInGroup ? 6 : 2,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSenderName && !isSelf && isFirstInGroup) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  message.senderName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            isSelf
                ? Container(
                    decoration: BoxDecoration(
                      color: BrandColors.brandBlue, // iOS style solid blue
                      borderRadius: bubbleRadius,
                      boxShadow: [
                        BoxShadow(
                          color: BrandColors.brandBlue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: bubbleContent,
                  )
                : LiquidGlass(
                    borderRadius: 20,
                    blur: 25,
                    child: bubbleContent,
                  ),
          ],
        ),
      ),
    );
  }
}
