import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class ProfileRepository {
  /// Fetches a user profile by [userId].
  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to get profile for user $userId: $e');
    }
  }

  /// Fetches the current authenticated user's profile.
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to get current user profile: $e');
    }
  }

  /// Updates the profile for the given [userId] with [data].
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await supabase.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile for user $userId: $e');
    }
  }

  /// Uploads an avatar image for [userId] and returns the public URL.
  Future<String> uploadAvatar(String userId, File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final filePath = '$userId/avatar.$fileExt';

      await supabase.storage.from('avatars').upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          supabase.storage.from('avatars').getPublicUrl(filePath);

      await supabase
          .from('profiles')
          .update({'avatar_url': publicUrl}).eq('id', userId);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar for user $userId: $e');
    }
  }

  /// Updates the FCM token for push notifications.
  Future<void> updateFcmToken(String token) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase
          .from('profiles')
          .update({'fcm_token': token}).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }

  /// Updates the user's location using a PostGIS-compatible RPC call.
  Future<void> updateLocation(double lat, double lng) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.rpc('update_user_location', params: {
        'user_id': userId,
        'lat': lat,
        'lng': lng,
      });
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }
}
