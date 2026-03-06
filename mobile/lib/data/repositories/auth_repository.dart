import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class AuthRepository {
  /// Sends an OTP code to the given phone number.
  Future<void> signInWithOtp(String phone) async {
    try {
      await supabase.auth.signInWithOtp(phone: phone);
    } catch (e) {
      throw Exception('Failed to send OTP to $phone: $e');
    }
  }

  /// Verifies the OTP code sent to the given phone number.
  Future<AuthResponse> verifyOtp(String phone, String token) async {
    try {
      final response = await supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
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
