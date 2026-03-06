import 'package:get/get.dart';
import '../data/repositories/review_repository.dart';
import '../widgets/common/app_snackbar.dart';

class ReviewController extends GetxController {
  final _reviewRepo = Get.find<ReviewRepository>();

  final RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  Future<void> loadReviews(String userId, {bool refresh = false}) async {
    try {
      isLoading.value = true;
      final offset = refresh ? 0 : reviews.length;
      final data = await _reviewRepo.getReviewsForUser(
        userId,
        limit: 20,
        offset: offset,
      );
      if (refresh) {
        reviews.assignAll(data);
      } else {
        reviews.addAll(data);
      }
    } catch (e) {
      AppSnackbar.error('Failed to load reviews');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitReview({
    required String bookingId,
    required String revieweeId,
    required int overallRating,
    int? qualityRating,
    int? communicationRating,
    int? punctualityRating,
    int? valueRating,
    String? comment,
  }) async {
    try {
      isSubmitting.value = true;
      await _reviewRepo.createReview({
        'booking_id': bookingId,
        'reviewee_id': revieweeId,
        'overall_rating': overallRating,
        'quality_rating': qualityRating,
        'communication_rating': communicationRating,
        'punctuality_rating': punctualityRating,
        'value_rating': valueRating,
        'comment': comment,
      });
      AppSnackbar.success('Review submitted');
      return true;
    } catch (e) {
      AppSnackbar.error('Failed to submit review');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
