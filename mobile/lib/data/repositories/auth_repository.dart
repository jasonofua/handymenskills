import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class AuthRepository {
  /// Signs up a new user with email and password.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Signs in a user with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sends a password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }

  /// Resend confirmation email.
  Future<void> resendConfirmation(String email) async {
    try {
      await supabase.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw Exception('Failed to resend confirmation: $e');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Stream of authentication state changes.
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Returns the currently signed-in user, or null.
  User? get currentUser => supabase.auth.currentUser;

  /// Returns the current session, or null.
  Session? get currentSession => supabase.auth.currentSession;
}
