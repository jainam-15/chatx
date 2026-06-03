import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 32.0, // More pronounced rounding for Framer style
    this.blur = 60.0, // Extremely high blur for deep frosted glass
    this.color,
    this.borderColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Apple-style frosted glass colors
    final glassColor = isDark 
        ? Colors.black.withOpacity(0.4)
        : Colors.white.withOpacity(0.65);
        
    final glassBorder = isDark 
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.4);
        
    return Container(
      margin: margin,
      width: width,
      height: height,
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Ambient soft shadow
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? glassColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? glassBorder,
                width: 0.5, // Ultra-thin border
              ),
              // Inner light/gradient to give thickness to the glass
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(isDark ? 0.1 : 0.4),
                  Colors.white.withOpacity(isDark ? 0.0 : 0.1),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
