import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class WorkerRepository {
  /// Fetches a worker profile by [userId], including skills data.
  Future<Map<String, dynamic>?> getWorkerProfile(String userId) async {
    try {
      final response = await supabase
          .from('worker_profiles')
          .select('*, worker_skills(*, skills(*))')
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to get worker profile for $userId: $e');
    }
  }

  /// Updates the worker profile for [userId] with [data].
  Future<void> updateWorkerProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await supabase
          .from('worker_profiles')
          .update(data)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update worker profile for $userId: $e');
    }
  }

  /// Searches for workers near the given coordinates within [radiusKm].
  /// Optionally filters by [skillId] and [minRating].
  Future<List<Map<String, dynamic>>> searchWorkersNearby(
    double lat,
    double lng,
    int radiusKm, {
    String? skillId,
    double? minRating,
  }) async {
    try {
      final params = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'radius_km': radiusKm,
      };
      if (skillId != null) params['skill_id'] = skillId;
      if (minRating != null) params['min_rating'] = minRating;

      final response = await supabase.rpc(
        'search_workers_nearby',
        params: params,
      );
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to search workers nearby: $e');
    }
  }

  /// Toggles the availability status for a worker.
  Future<void> toggleAvailability(String userId, bool isAvailable) async {
    try {
      await supabase
          .from('worker_profiles')
          .update({'is_available': isAvailable}).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to toggle availability for $userId: $e');
    }
  }

  /// Uploads a portfolio image for [userId] and returns the public URL.
  Future<String> uploadPortfolioImage(String userId, File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/portfolio/$fileName';

      await supabase.storage.from('portfolios').upload(filePath, file);

      final publicUrl =
          supabase.storage.from('portfolios').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload portfolio image for $userId: $e');
    }
  }

  /// Removes a portfolio image for [userId] by its [imageUrl].
  Future<void> removePortfolioImage(String userId, String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      // Extract the storage path after 'portfolios/'
      final bucketIndex = pathSegments.indexOf('portfolios');
      if (bucketIndex == -1) {
        throw Exception('Invalid portfolio image URL');
      }
      final storagePath =
          pathSegments.sublist(bucketIndex + 1).join('/');

      await supabase.storage.from('portfolios').remove([storagePath]);
    } catch (e) {
      throw Exception(
          'Failed to remove portfolio image for $userId: $e');
    }
  }

  /// Uploads an ID document for [userId] and returns the public URL.
  Future<String> uploadIdDocument(String userId, File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await supabase.storage.from('id-documents').upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          supabase.storage.from('id-documents').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload ID document for $userId: $e');
    }
  }

  /// Fetches the weekly schedule for a worker profile.
  Future<List<Map<String, dynamic>>> getSchedule(
      String workerProfileId) async {
    try {
      final response = await supabase
          .from('worker_schedule')
          .select()
          .eq('worker_id', workerProfileId)
          .order('day_of_week');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get schedule: $e');
    }
  }

  /// Upserts a single day's schedule for a worker.
  Future<void> upsertScheduleDay(Map<String, dynamic> data) async {
    try {
      await supabase
          .from('worker_schedule')
          .upsert(data, onConflict: 'worker_id,day_of_week');
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  /// Updates the bank details for a worker.
  Future<void> updateBankDetails(
    String userId,
    Map<String, dynamic> bankData,
  ) async {
    try {
      await supabase
          .from('worker_profiles')
          .update({'bank_details': bankData}).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update bank details for $userId: $e');
    }
  }
}
