import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class SubscriptionRepository {
  /// Fetches all active subscription plans, ordered by price ascending.
  Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final response = await supabase
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get subscription plans: $e');
    }
  }

  /// Fetches the current user's active subscription with plan details.
  Future<Map<String, dynamic>?> getMySubscription() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('subscriptions')
          .select('*, subscription_plans(*)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to get current subscription: $e');
    }
  }

  /// Checks the current worker's subscription status via RPC.
  Future<Map<String, dynamic>> checkSubscriptionStatus() async {
    try {
      final response = await supabase.rpc('check_worker_subscription');
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw Exception('Failed to check subscription status: $e');
    }
  }
}
