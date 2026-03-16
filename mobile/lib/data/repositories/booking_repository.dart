import '../../config/supabase_config.dart';

class BookingRepository {
  /// Processes a booking action (e.g., confirm, start, complete, cancel) via RPC.
  /// [action] is the action to perform (e.g., 'confirm', 'start', 'complete', 'cancel').
  /// [bookingId] is the target booking.
  /// [extraData] provides optional additional data for the action.
  Future<Map<String, dynamic>> processBookingAction(
    String action,
    String bookingId, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final params = <String, dynamic>{
        'action': action,
        'booking_id': bookingId,
      };
      if (extraData != null) {
        params['extra_data'] = extraData;
      }

      final response = await supabase.rpc(
        'process_booking_action',
        params: params,
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw Exception(
          'Failed to process booking action "$action" for $bookingId: $e');
    }
  }

  /// Fetches the current user's bookings.
  /// [role] filters by 'client' or 'worker'.
  /// [status] optionally filters by booking status.
  Future<List<Map<String, dynamic>>> getMyBookings({
    String? role,
    String? status,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      var query = supabase.from('bookings').select(
          '*, jobs(*), profiles!bookings_client_id_fkey(*), profiles!bookings_worker_id_fkey(*)');

      if (role == 'client') {
        query = query.eq('client_id', userId);
      } else if (role == 'worker') {
        query = query.eq('worker_id', userId);
      } else {
        query = query.or('client_id.eq.$userId,worker_id.eq.$userId');
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response =
          await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get bookings: $e');
    }
  }

  /// Fetches a single booking by [id] with all related data.
  Future<Map<String, dynamic>> getBookingById(String id) async {
    try {
      final response = await supabase
          .from('bookings')
          .select(
              '*, jobs(*, categories(*)), profiles!bookings_client_id_fkey(*), profiles!bookings_worker_id_fkey(*), reviews(*)')
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to get booking $id: $e');
    }
  }
}
