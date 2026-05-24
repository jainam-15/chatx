import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/logger.dart';

class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException: $message ($code)';
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _tag = 'AuthService';

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      Logger.info(_tag, 'Attempting sign in for: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.info(_tag, 'Sign in successful for: $email');
      return credential;
    } on FirebaseAuthException catch (e, stack) {
      Logger.error(_tag, 'Sign in failed for $email', e, stack);
      throw _handleAuthException(e);
    } catch (e, stack) {
      Logger.error(_tag, 'Unexpected sign in error for $email', e, stack);
      throw AuthException('An unexpected error occurred during sign in.', 'unknown');
    }
  }

  // Register with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      Logger.info(_tag, 'Attempting registration for: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.info(_tag, 'Registration successful for: $email');
      return credential;
    } on FirebaseAuthException catch (e, stack) {
      Logger.error(_tag, 'Registration failed for $email', e, stack);
      throw _handleAuthException(e);
    } catch (e, stack) {
      Logger.error(_tag, 'Unexpected registration error for $email', e, stack);
      throw AuthException('An unexpected error occurred during sign up.', 'unknown');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      Logger.info(_tag, 'Signing out user: ${currentUser?.email}');
      await _auth.signOut();
      Logger.info(_tag, 'Sign out successful');
    } catch (e, stack) {
      Logger.error(_tag, 'Sign out failed', e, stack);
      throw AuthException('An unexpected error occurred during sign out.', 'unknown');
    }
  }

  // Helper to map Firebase Auth codes to readable messages
  AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('No user found for that email.', e.code);
      case 'wrong-password':
        return AuthException('Incorrect password provided.', e.code);
      case 'email-already-in-use':
        return AuthException('The account already exists for that email.', e.code);
      case 'invalid-email':
        return AuthException('The email address is badly formatted.', e.code);
      case 'weak-password':
        return AuthException('The password provided is too weak.', e.code);
      case 'user-disabled':
        return AuthException('This user account has been disabled.', e.code);
      case 'operation-not-allowed':
        return AuthException('Operation not allowed on firebase auth console.', e.code);
      case 'network-request-failed':
        return AuthException('Network request failed. Please check your connection.', e.code);
      default:
        return AuthException(e.message ?? 'Authentication failed.', e.code);
    }
  }
}
