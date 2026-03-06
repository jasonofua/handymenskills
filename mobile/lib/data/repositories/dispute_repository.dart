import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class DisputeRepository {
  /// Creates a new dispute.
  Future<void> createDispute(Map<String, dynamic> data) async {
    try {
      await supabase.from('disputes').insert(data);
    } catch (e) {
      throw Exception('Failed to create dispute: $e');
    }
  }

  /// Fetches all disputes for the current user.
  Future<List<Map<String, dynamic>>> getMyDisputes() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('disputes')
          .select('*, bookings(*, jobs(*))')
          .or('raised_by.eq.$userId,raised_against.eq.$userId')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get disputes: $e');
    }
  }

  /// Fetches a single dispute by [id] with all related data.
  Future<Map<String, dynamic>> getDisputeById(String id) async {
    try {
      final response = await supabase
          .from('disputes')
          .select(
              '*, bookings(*, jobs(*)), profiles!disputes_raised_by_fkey(*), profiles!disputes_raised_against_fkey(*)')
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to get dispute $id: $e');
    }
  }
}
