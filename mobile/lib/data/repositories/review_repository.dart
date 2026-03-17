import '../../config/supabase_config.dart';

class ReviewRepository {
  /// Creates a new review.
  /// Automatically sets reviewer_id from the current user.
  /// If reviewee_id is empty, resolves it from the booking's worker_id.
  Future<void> createReview(Map<String, dynamic> data) async {
    try {
      final reviewData = Map<String, dynamic>.from(data);

      // Set reviewer as the current user
      reviewData['reviewer_id'] = supabase.auth.currentUser!.id;

      // Resolve reviewee_id from booking if not provided
      final revieweeId = reviewData['reviewee_id']?.toString() ?? '';
      if (revieweeId.isEmpty && reviewData['booking_id'] != null) {
        final booking = await supabase
            .from('bookings')
            .select('worker_id')
            .eq('id', reviewData['booking_id'])
            .single();
        reviewData['reviewee_id'] = booking['worker_id'];
      }

      // Remove null optional ratings
      reviewData.removeWhere((key, value) => value == null && key != 'comment');

      await supabase.from('reviews').insert(reviewData);
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  /// Fetches reviews for a specific user, paginated.
  Future<List<Map<String, dynamic>>> getReviewsForUser(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await supabase
          .from('reviews')
          .select('*, profiles!reviews_reviewer_id_fkey(*)')
          .eq('reviewee_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get reviews for user $userId: $e');
    }
  }

  /// Fetches a single review associated with a [bookingId], if it exists.
  Future<Map<String, dynamic>?> getReviewForBooking(
    String bookingId,
  ) async {
    try {
      final response = await supabase
          .from('reviews')
          .select('*, profiles!reviews_reviewer_id_fkey(*)')
          .eq('booking_id', bookingId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception(
          'Failed to get review for booking $bookingId: $e');
    }
  }

  /// Updates an existing review.
  Future<void> updateReview(String reviewId, Map<String, dynamic> data) async {
    try {
      await supabase.from('reviews').update(data).eq('id', reviewId);
    } catch (e) {
      throw Exception('Failed to update review $reviewId: $e');
    }
  }

  /// Deletes a review by ID.
  Future<void> deleteReview(String reviewId) async {
    try {
      await supabase.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      throw Exception('Failed to delete review $reviewId: $e');
    }
  }
}
