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

  /// Creates a pending payout record for a worker after client payment.
  Future<void> createPayout({
    required String workerId,
    required String bookingId,
    required double amount,
  }) async {
    try {
      await supabase.from('payouts').insert({
        'worker_id': workerId,
        'booking_id': bookingId,
        'amount': amount,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to create payout: $e');
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

  /// Calculates the worker's available balance for withdrawal.
  /// Balance = sum(bookings.worker_payout for completed/confirmed) - sum(withdrawal payouts not failed)
  Future<double> getWorkerBalance() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // Sum worker_payout from completed bookings
      final bookings = await supabase
          .from('bookings')
          .select('worker_payout')
          .eq('worker_id', userId)
          .inFilter('status', ['completed', 'client_confirmed']);
      double totalEarned = 0.0;
      for (final b in bookings) {
        totalEarned += ((b['worker_payout'] ?? 0) as num).toDouble();
      }

      // Subtract withdrawn amounts (payouts where booking_id IS NULL and status != 'failed')
      final withdrawals = await supabase
          .from('payouts')
          .select('amount, status')
          .eq('worker_id', userId)
          .isFilter('booking_id', null);
      double totalWithdrawn = 0.0;
      for (final w in withdrawals) {
        if (w['status'] != 'failed') {
          totalWithdrawn += ((w['amount'] ?? 0) as num).toDouble();
        }
      }

      return totalEarned - totalWithdrawn;
    } catch (e) {
      throw Exception('Failed to get worker balance: $e');
    }
  }

  /// Creates a withdrawal payout record after a successful Paystack transfer.
  Future<void> createWithdrawalRecord({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String status,
    String? transferCode,
    String? recipientCode,
    String? reference,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = <String, dynamic>{
        'worker_id': userId,
        'amount': amount,
        'status': status,
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_name': accountName,
      };
      if (status == 'completed' || status == 'processing') {
        data['processed_at'] = DateTime.now().toIso8601String();
      }
      if (transferCode != null) {
        data['paystack_transfer_code'] = transferCode;
      }
      if (recipientCode != null) {
        data['paystack_recipient_code'] = recipientCode;
      }
      if (reference != null) {
        data['reference'] = reference;
      }
      await supabase.from('payouts').insert(data);
    } catch (e) {
      throw Exception('Failed to create withdrawal record: $e');
    }
  }
}
