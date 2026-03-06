import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class PaymentRepository {
  /// Inserts a new payment record and returns the created row.
  Future<Map<String, dynamic>> insertPayment(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await supabase
          .from('payments')
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to insert payment: $e');
    }
  }

  /// Fetches payment history for the current user, optionally filtered
  /// by [paymentType], paginated with [limit] and [offset].
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    String? paymentType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      var query = supabase
          .from('payments')
          .select('*, bookings(*, jobs(*))')
          .or('payer_id.eq.$userId,payee_id.eq.$userId');

      if (paymentType != null) {
        query = query.eq('payment_type', paymentType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get payment history: $e');
    }
  }

  /// Fetches payouts for the current worker, paginated.
  Future<List<Map<String, dynamic>>> getPayouts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('payments')
          .select('*, bookings(*, jobs(*))')
          .eq('payee_id', userId)
          .eq('payment_type', 'payout')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get payouts: $e');
    }
  }
}
