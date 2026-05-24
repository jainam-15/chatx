import 'package:flutter/material.dart';

enum ChatXButtonVariant {
  primary,
  secondary,
  text,
}

class ChatXButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ChatXButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  const ChatXButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ChatXButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<ChatXButton> createState() => _ChatXButtonState();
}

class _ChatXButtonState extends State<ChatXButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.variant) {
      case ChatXButtonVariant.primary:
        backgroundColor = isEnabled ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.5);
        textColor = theme.colorScheme.onPrimary;
        break;
      case ChatXButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        textColor = isEnabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5);
        borderSide = BorderSide(
          color: isEnabled ? theme.colorScheme.outline : theme.colorScheme.outline.withOpacity(0.5),
          width: 1.5,
        );
        break;
      case ChatXButtonVariant.text:
        backgroundColor = Colors.transparent;
        textColor = isEnabled ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.5);
        break;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.fromBorderSide(borderSide),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: widget.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: textColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
