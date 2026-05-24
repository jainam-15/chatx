import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../core/utils/logger.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? firebaseUser;
  final UserModel? profile;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.firebaseUser,
    this.profile,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  factory AuthState.loading() => AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated(User user, UserModel profile) => AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: user,
        profile: profile,
      );

  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.error(String message) => AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );

  AuthState copyWith({
    AuthStatus? status,
    User? firebaseUser,
    UserModel? profile,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Service Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService(ref));

// Auth State Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authService: ref.watch(authServiceProvider),
    databaseService: ref.watch(databaseServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

// Selector for ease of access
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).profile;
});

class AuthNotifier extends StateNotifier<AuthState> with WidgetsBindingObserver {
  final AuthService _authService;
  final DatabaseService _databaseService;
  final NotificationService _notificationService;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _profileSubscription;
  StreamSubscription<String>? _tokenSubscription;
  static const String _tag = 'AuthNotifier';

  AuthNotifier({
    required AuthService authService,
    required DatabaseService databaseService,
    required NotificationService notificationService,
  })  : _authService = authService,
        _databaseService = databaseService,
        _notificationService = notificationService,
        super(AuthState.initial()) {
    _init();
  }

  void _init() {
    WidgetsBinding.instance.addObserver(this);
    Logger.info(_tag, 'Initializing AuthNotifier');
    state = AuthState.loading();
    _authSubscription = _authService.authStateChanges.listen((User? user) async {
      await _handleAuthStateChange(user);
    });
  }

  Future<void> _handleAuthStateChange(User? user) async {
    _profileSubscription?.cancel();
    _tokenSubscription?.cancel();

    if (user == null) {
      Logger.info(_tag, 'User is unauthenticated');
      state = AuthState.unauthenticated();
      return;
    }

    Logger.info(_tag, 'User authenticated with ID: ${user.uid}');

    try {
      // Stream user profile to get real-time status updates (e.g. online toggles)
      _profileSubscription = _databaseService.streamUserProfile(user.uid).listen((profile) async {
        if (profile == null) {
          // If profile doesn't exist, create it (new user)
          Logger.info(_tag, 'No user profile found, creating a new profile');
          final email = user.email ?? '';
          final newProfile = UserModel(
            id: user.uid,
            email: email,
            displayName: user.displayName ?? (email.isNotEmpty ? email.split('@')[0] : 'User'),
            isOnline: true,
            lastActive: DateTime.now(),
            createdAt: DateTime.now(),
          );
          await _databaseService.createUserProfile(newProfile);
        } else {
          Logger.info(_tag, 'Profile loaded for user: ${profile.email}');
          state = AuthState.authenticated(user, profile);

          // Update online presence if needed
          if (!profile.isOnline) {
            await _databaseService.updateUserPresence(user.uid, true);
          }
        }
      });

      // Initialize notifications background/foreground listener
      await _notificationService.initialize();
      final fcmToken = await _notificationService.getToken();
      if (fcmToken != null) {
        await _databaseService.updateUserFcmToken(user.uid, fcmToken);
      }

      // Listen to token refresh events
      _tokenSubscription = _notificationService.onTokenRefresh.listen((token) {
        Logger.info(_tag, 'FCM token refreshed. Updating in Firestore...');
        _databaseService.updateUserFcmToken(user.uid, token);
      });
    } catch (e, stack) {
      Logger.error(_tag, 'Error mapping auth state changes', e, stack);
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signIn(String email, String password) async {
    state = AuthState.loading();
    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
    } catch (e) {
      state = AuthState.error('An unexpected login error occurred.');
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = AuthState.loading();
    try {
      final credential = await _authService.signUpWithEmailAndPassword(email, password);
      if (credential.user != null) {
        final fcmToken = await _notificationService.getToken();
        final newProfile = UserModel(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
          isOnline: true,
          lastActive: DateTime.now(),
          createdAt: DateTime.now(),
          fcmToken: fcmToken,
        );
        await _databaseService.createUserProfile(newProfile);
      }
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
    } catch (e) {
      state = AuthState.error('An unexpected sign up error occurred.');
    }
  }

  Future<void> signOut() async {
    final currentUserId = state.profile?.id;
    if (currentUserId != null) {
      // Mark presence offline prior to signing out
      await _databaseService.updateUserPresence(currentUserId, false);
      // Clear FCM token on logout to prevent push routing to logged out device session
      await _databaseService.updateUserFcmToken(currentUserId, null);
      await _notificationService.deleteToken();
    }
    state = AuthState.loading();
    try {
      await _authService.signOut();
    } catch (e) {
      state = AuthState.error('An unexpected sign out error occurred.');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    _tokenSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final user = state.firebaseUser;
    if (user == null) return;

    if (lifecycleState == AppLifecycleState.resumed) {
      Logger.info(_tag, 'App resumed. Marking user online.');
      _databaseService.updateUserPresence(user.uid, true);
    } else if (lifecycleState == AppLifecycleState.paused || lifecycleState == AppLifecycleState.detached || lifecycleState == AppLifecycleState.hidden) {
      Logger.info(_tag, 'App backgrounded/killed. Marking user offline and clearing active chat.');
      _databaseService.updateUserPresence(user.uid, false);
      _databaseService.updateUserActiveChat(user.uid, null);
    }
  }
}
