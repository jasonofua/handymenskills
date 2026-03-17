import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/booking_repository.dart';
import '../data/services/realtime_service.dart';
import '../widgets/common/app_snackbar.dart';

class BookingController extends GetxController {
  final _bookingRepo = Get.find<BookingRepository>();
  final _realtimeService = Get.find<RealtimeService>();

  final RxList<Map<String, dynamic>> bookings = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> currentBooking = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;

  RealtimeChannel? _bookingChannel;
  RealtimeChannel? _bookingsListChannel;
  String? _currentRole;

  Future<void> loadBookings({String? role, String? status}) async {
    _currentRole = role ?? _currentRole;
    try {
      isLoading.value = true;
      final data = await _bookingRepo.getMyBookings(role: _currentRole, status: status);
      bookings.assignAll(data);
      _subscribeToBookingsList();
    } catch (e) {
      AppSnackbar.error('Failed to load bookings');
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToBookingsList() {
    if (_bookingsListChannel != null) return; // already subscribed
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _currentRole == null) return;

    _bookingsListChannel = _realtimeService.subscribeToMyBookings(
      userId,
      _currentRole!,
      () => loadBookings(role: _currentRole),
    );
  }

  Future<void> loadBookingDetail(String bookingId) async {
    try {
      isLoading.value = true;
      final data = await _bookingRepo.getBookingById(bookingId);
      currentBooking.assignAll(data);
      _subscribeToBooking(bookingId);
    } catch (e) {
      AppSnackbar.error('Failed to load booking');
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToBooking(String bookingId) {
    _bookingChannel?.unsubscribe();
    _bookingChannel = _realtimeService.subscribeToBookingUpdates(
      bookingId,
      (updated) {
        currentBooking.assignAll({...currentBooking, ...updated});
      },
    );
  }

  Future<bool> processAction(String action, String bookingId, {Map<String, dynamic>? extraData}) async {
    try {
      isProcessing.value = true;
      await _bookingRepo.processBookingAction(action, bookingId, extraData: extraData);

      // Refresh booking detail
      final updated = await _bookingRepo.getBookingById(bookingId);
      currentBooking.assignAll(updated);

      // Update in list
      final index = bookings.indexWhere((b) => b['id'] == bookingId);
      if (index != -1) {
        bookings[index] = updated;
        bookings.refresh();
      }

      final messages = {
        'confirm': 'Booking confirmed',
        'start': 'Job started',
        'complete': 'Job marked as completed',
        'client_confirm': 'Job confirmed. Payment will be processed.',
        'cancel': 'Booking cancelled',
        'dispute': 'Dispute created',
      };
      AppSnackbar.success(messages[action] ?? 'Booking updated');
      return true;
    } catch (e) {
      AppSnackbar.error('Failed to process action: ${e.toString()}');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  @override
  void onClose() {
    _bookingChannel?.unsubscribe();
    _bookingsListChannel?.unsubscribe();
    super.onClose();
  }
}
