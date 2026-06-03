import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/routing/route_paths.dart';
import '../widgets/chatx_button.dart';
import '../widgets/mock_chat_preview.dart';
import '../widgets/feature_card.dart';
import '../theme/brand_colors.dart';
import '../providers/theme_provider.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  Widget _buildHeroContent(BuildContext context, ThemeData theme, bool isDark) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo instead of badge
            Image.asset(
              'assets/logo.png',
              height: 64,
              errorBuilder: (context, error, stackTrace) => ShaderMask(
                shaderCallback: (bounds) => BrandColors.brandGradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Icon(Icons.chat_bubble_rounded, size: 64),
              ),
            )
            .animate()
            .fade(duration: 800.ms, curve: Curves.easeOut)
            .slideY(begin: 0.1, curve: Curves.easeOutBack),

            const SizedBox(height: 32),

            // Gradient Headline
            ShaderMask(
              shaderCallback: (bounds) => BrandColors.brandGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                'Connect.',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 88,
                  height: 1.0,
                  letterSpacing: -4.0,
                ),
              ),
            )
            .animate()
            .fade(delay: 200.ms, duration: 800.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutQuart),

            Text(
              'Instantly.',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 88,
                height: 1.0,
                letterSpacing: -4.0,
                color: isDark ? Colors.white : Colors.black,
              ),
            )
            .animate()
            .fade(delay: 300.ms, duration: 800.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutQuart),

            const SizedBox(height: 32),

            Text(
              'Experience the future of messaging.\nClean. Fast. Secure by design.',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
            )
            .animate()
            .fade(delay: 400.ms, duration: 800.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutQuart),

            const SizedBox(height: 56),

            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(
                  height: 56,
                  width: 180,
                  child: ChatXButton(
                    text: 'Get Started',
                    onPressed: () => context.go(RoutePaths.register),
                  ),
                ),
                SizedBox(
                  height: 56,
                  width: 180,
                  child: ChatXButton(
                    text: 'Log In',
                    variant: ChatXButtonVariant.secondary,
                    onPressed: () => context.go(RoutePaths.login),
                  ),
                ),
              ],
            )
            .animate()
            .fade(delay: 600.ms, duration: 800.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutQuart),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Stark background colors
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Spacer for floating navbar
                const SizedBox(height: 100),
                // Hero Area (responsive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 900) {
                        // Desktop Layout
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildHeroContent(context, theme, isDark),
                            ),
                            const SizedBox(width: 80),
                            Expanded(
                              flex: 4,
                              child: const MockChatPreview()
                                  .animate()
                                  .fade(duration: 1000.ms, delay: 300.ms)
                                  .slideX(begin: 0.1, curve: Curves.easeOutQuart),
                            ),
                          ],
                        );
                      } else {
                        // Mobile Layout
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildHeroContent(context, theme, isDark),
                            const SizedBox(height: 80),
                            const MockChatPreview()
                                  .animate()
                                  .fade(duration: 1000.ms, delay: 300.ms)
                                  .slideY(begin: 0.1, curve: Curves.easeOutQuart),
                          ],
                        );
                      }
                    },
                  ),
                ),

                // Bento Box Features Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 120),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF09090B) : const Color(0xFFFAFAFA),
                    border: Border(
                      top: BorderSide(color: borderColor, width: 1.0),
                      bottom: BorderSide(color: borderColor, width: 1.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Why ChatX?',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2.0,
                          fontSize: 56,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Built for speed, privacy, and absolute clarity.',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 80),
                      
                      // Bento Grid Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 900;
                          if (isWide) {
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: const FeatureCard(
                                      icon: Icons.speed_rounded,
                                      title: 'Lightning Fast',
                                      description: 'Built on a custom high-performance engine, your messages arrive instantly with ultra-low latency.',
                                    ).animate().fade(duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        const FeatureCard(
                                          icon: Icons.security_rounded,
                                          title: 'End-to-End Secure',
                                          description: 'Privacy first. Every conversation is secured so only you and the recipient have the keys.',
                                          height: 220,
                                          width: double.infinity,
                                        ).animate().fade(delay: 150.ms, duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                                        const SizedBox(height: 24),
                                        const FeatureCard(
                                          icon: Icons.devices_rounded,
                                          title: 'Cross Platform',
                                          description: 'Start a conversation on your phone, finish it on your desktop. Flawless sync.',
                                          height: 220,
                                          width: double.infinity,
                                        ).animate().fade(delay: 300.ms, duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Mobile: Stacked Bento
                            return Column(
                              children: [
                                const FeatureCard(
                                  icon: Icons.speed_rounded,
                                  title: 'Lightning Fast',
                                  description: 'Built on a custom high-performance engine, your messages arrive instantly with ultra-low latency.',
                                  width: double.infinity,
                                ).animate().fade(duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                                const SizedBox(height: 24),
                                const FeatureCard(
                                  icon: Icons.security_rounded,
                                  title: 'End-to-End Secure',
                                  description: 'Privacy first. Every conversation is secured so only you and the recipient have the keys.',
                                  width: double.infinity,
                                ).animate().fade(delay: 150.ms, duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                                const SizedBox(height: 24),
                                const FeatureCard(
                                  icon: Icons.devices_rounded,
                                  title: 'Cross Platform',
                                  description: 'Start a conversation on your phone, finish it on your desktop. Flawless sync.',
                                  width: double.infinity,
                                ).animate().fade(delay: 300.ms, duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // How It Works Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 120),
                  color: bgColor,
                  child: Column(
                    children: [
                      Text(
                        'How it works',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2.0,
                          fontSize: 56,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 80),
                      Wrap(
                        spacing: 48,
                        runSpacing: 48,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildStep(context, '1', 'Create Account', 'Sign up in seconds using your email or Google account.', isDark),
                          _buildStep(context, '2', 'Connect', 'Find your friends or invite them via a secure link.', isDark),
                          _buildStep(context, '3', 'Start Chatting', 'Send messages, images, and more in real-time.', isDark),
                        ],
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Liquid Navbar
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.brandPurple.withOpacity(isDark ? 0.3 : 0.15),
                      blurRadius: 40,
                      spreadRadius: -10,
                    ),
                    BoxShadow(
                      color: BrandColors.brandBlue.withOpacity(isDark ? 0.3 : 0.15),
                      blurRadius: 40,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 28,
                            errorBuilder: (context, error, stackTrace) => ShaderMask(
                              shaderCallback: (bounds) => BrandColors.brandGradient.createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: const Icon(Icons.chat_bubble_rounded, size: 28),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ChatX',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Navigation Links (Desktop only to prevent overflow)
                          if (MediaQuery.of(context).size.width > 600) ...[
                            Container(height: 16, width: 1, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {},
                              child: Text('Features', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () {},
                              child: Text('How it Works', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            Container(height: 16, width: 1, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(width: 16),
                          ] else ...[
                            const SizedBox(width: 4),
                          ],
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: isDark ? Colors.white : Colors.black,
                            size: 20,
                          ),
                          onPressed: () {
                            ref.read(themeModeProvider.notifier).updateTheme(
                              isDark ? ThemeMode.light : ThemeMode.dark,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fade(duration: 800.ms).slideY(begin: -0.5, curve: Curves.easeOutBack),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String title, String desc, bool isDark) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 120,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? BrandColors.darkTextSecondary : BrandColors.lightTextSecondary,
              height: 1.5,
              fontSize: 16,
            ),
          ),
        ],
      ).animate().fade(duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
    );
  }
}
