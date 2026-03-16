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
          .eq('user_id', userId);

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

  /// Fetches all wallet-related payments (topup & booking) for balance
  /// calculation. Lightweight query — no joins, no limit.
  Future<List<Map<String, dynamic>>> getWalletPayments() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('payments')
          .select('amount, payment_type, status, created_at')
          .eq('user_id', userId)
          .inFilter('payment_type', ['wallet_topup', 'booking_payment', 'booking_deposit']);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get wallet payments: $e');
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
          .from('payouts')
          .select('*, bookings(*, jobs(*))')
          .eq('worker_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get payouts: $e');
    }
  }
}
