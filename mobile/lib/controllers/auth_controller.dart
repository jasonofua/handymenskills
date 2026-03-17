import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../widgets/common/app_snackbar.dart';

class AuthController extends GetxController {
  final _authRepo = Get.find<AuthRepository>();
  final _profileRepo = Get.find<ProfileRepository>();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxMap<String, dynamic> profile = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final RxString userRole = ''.obs;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = supabase.auth.currentUser;
    isLoggedIn.value = currentUser.value != null;
    _authSubscription = _authRepo.authStateChanges.listen(_onAuthStateChanged);
    if (isLoggedIn.value) {
      _loadProfile();
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  void _onAuthStateChanged(AuthState state) {
    final event = state.event;
    currentUser.value = state.session?.user;
    isLoggedIn.value = currentUser.value != null;

    if (event == AuthChangeEvent.signedIn) {
      _loadProfile();
    } else if (event == AuthChangeEvent.signedOut) {
      profile.clear();
      userRole.value = '';
    }
  }

  Future<void> _loadProfile() async {
    final user = currentUser.value ?? supabase.auth.currentUser;
    if (user == null) return;
    currentUser.value = user;
    isLoggedIn.value = true;
    try {
      final data = await _profileRepo.getMyProfile();
      profile.assignAll(data);
      userRole.value = data['role'] ?? '';
    } catch (e) {
      // Profile might not exist yet for new users
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      isLoading.value = true;
      debugPrint('AuthController: Signing up $email');
      await _authRepo.signUp(
        email: email,
        password: password,
        metadata: metadata,
      );
      debugPrint('AuthController: Sign up successful');
    } catch (e) {
      debugPrint('AuthController: Sign up error: $e');
      AppSnackbar.error('Sign up failed: ${e.toString()}');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      debugPrint('AuthController: Signing in $email');
      await _authRepo.signIn(email: email, password: password);
      debugPrint('AuthController: Sign in successful');
    } catch (e) {
      debugPrint('AuthController: Sign in error: $e');
      AppSnackbar.error('Invalid email or password.');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      await _authRepo.resetPassword(email);
      AppSnackbar.success('Password reset email sent. Check your inbox.');
    } catch (e) {
      AppSnackbar.error('Failed to send reset email: ${e.toString()}');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerProfile({
    required String fullName,
    String? email,
    required String role,
  }) async {
    try {
      isLoading.value = true;
      await _profileRepo.updateProfile(currentUser.value!.id, {
        'full_name': fullName,
        'email': email,
        'role': role,
      });
      await _loadProfile();
    } catch (e) {
      AppSnackbar.error('Registration failed: ${e.toString()}');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendConfirmation({required String email}) async {
    try {
      isLoading.value = true;
      await _authRepo.resendConfirmation(email);
      AppSnackbar.success('Confirmation email resent. Check your inbox.');
    } catch (e) {
      AppSnackbar.error('Failed to resend: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepo.signOut();
      currentUser.value = null;
      isLoggedIn.value = false;
      profile.clear();
      userRole.value = '';
    } catch (e) {
      AppSnackbar.error('Failed to sign out');
    }
  }

  String get userId => currentUser.value?.id ?? '';
  String get userName => profile['full_name'] ?? '';
  String get userEmail => profile['email'] ?? '';
  String? get userAvatar => profile['avatar_url'];
  bool get isWorker => userRole.value == 'worker';
  bool get isClient => userRole.value == 'client';

  Future<void> refreshProfile() => _loadProfile();
}
