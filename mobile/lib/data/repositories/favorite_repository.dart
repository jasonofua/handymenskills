import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class FavoriteRepository {
  /// Saves a worker to the current user's favorites.
  Future<void> saveWorker(String workerId) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('saved_workers').insert({
        'user_id': userId,
        'worker_id': workerId,
      });
    } catch (e) {
      throw Exception('Failed to save worker $workerId: $e');
    }
  }

  /// Removes a worker from the current user's favorites.
  Future<void> unsaveWorker(String workerId) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase
          .from('saved_workers')
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId);
    } catch (e) {
      throw Exception('Failed to unsave worker $workerId: $e');
    }
  }

  /// Fetches all saved workers for the current user with worker profile data.
  Future<List<Map<String, dynamic>>> getSavedWorkers() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('saved_workers')
          .select('*, profiles!saved_workers_worker_id_fkey(*, worker_profiles(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get saved workers: $e');
    }
  }

  /// Checks whether a worker is saved by the current user.
  Future<bool> isWorkerSaved(String workerId) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('saved_workers')
          .select()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      throw Exception(
          'Failed to check if worker $workerId is saved: $e');
    }
  }
}
