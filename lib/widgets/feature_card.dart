import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double? width;
  final double? height;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF09090B) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => BrandColors.brandGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Icon(
                icon,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
              height: 1.6,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
