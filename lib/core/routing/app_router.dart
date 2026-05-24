import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_paths.dart';
import '../../providers/auth_provider.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/shell_screen.dart';
import '../../screens/chat_detail_screen.dart';
import '../../screens/splash_screen.dart';

// Global navigator key for raw Flutter navigation bypasses
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (previous, next) {
        if (previous?.status != next.status) {
          notifyListeners();
        }
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final status = authState.status;

      final isLoggingIn = state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register;

      // During initial startup or loading, stay on splash screen
      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return state.matchedLocation == RoutePaths.splash ? null : RoutePaths.splash;
      }

      // Guard: Unauthenticated users go to Login
      if (status == AuthStatus.unauthenticated || status == AuthStatus.error) {
        if (!isLoggingIn) {
          return RoutePaths.login;
        }
        return null;
      }

      // Guard: Authenticated users go to Chats, away from login screens and splash
      if (status == AuthStatus.authenticated) {
        if (isLoggingIn || state.matchedLocation == RoutePaths.splash) {
          return RoutePaths.chatList;
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/notification-chat/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return ChatDetailScreen(
            roomId: roomId,
            onBack: () => context.go(RoutePaths.chatList),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.chatList,
        builder: (context, state) => const ShellScreen(),
      ),
      GoRoute(
        path: RoutePaths.chatDetail,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'];
          return ShellScreen(selectedRoomId: roomId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Route Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Page not found',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.chatList),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
