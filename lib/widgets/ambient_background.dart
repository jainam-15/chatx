import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/brand_colors.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          // Background Blob 1
          Positioned(
            top: -screenHeight * 0.1,
            left: -screenWidth * 0.2,
            child: Container(
              width: screenWidth * 0.8,
              height: screenWidth * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.brandBlue.withOpacity(isDark ? 0.3 : 0.2),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .move(
              duration: 15.seconds,
              curve: Curves.easeInOut,
              begin: const Offset(0, 0),
              end: Offset(screenWidth * 0.2, screenHeight * 0.1),
            )
            .scale(
              duration: 20.seconds,
              curve: Curves.easeInOutSine,
              begin: const Offset(1, 1),
              end: const Offset(1.2, 1.2),
            ),
          ),
          
          // Background Blob 2
          Positioned(
            bottom: -screenHeight * 0.2,
            right: -screenWidth * 0.1,
            child: Container(
              width: screenWidth * 0.7,
              height: screenWidth * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.brandPurple.withOpacity(isDark ? 0.25 : 0.15),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .move(
              duration: 18.seconds,
              curve: Curves.easeInOut,
              begin: const Offset(0, 0),
              end: Offset(-screenWidth * 0.15, -screenHeight * 0.15),
            )
            .scale(
              duration: 22.seconds,
              curve: Curves.easeInOutSine,
              begin: const Offset(1, 1),
              end: const Offset(1.3, 1.3),
            ),
          ),
          
          // Glass Blur Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Foreground Content
          Positioned.fill(
            child: SafeArea(child: child),
          ),
        ],
      ),
    );
  }
}
