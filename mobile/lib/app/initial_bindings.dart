import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/connectivity_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/worker_profile_controller.dart';
import '../controllers/job_controller.dart';
import '../controllers/application_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/payment_controller.dart';
import '../controllers/subscription_controller.dart';
import '../controllers/review_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/dispute_controller.dart';
import '../controllers/map_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/worker_repository.dart';
import '../data/repositories/skill_repository.dart';
import '../data/repositories/job_repository.dart';
import '../data/repositories/application_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/review_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/storage_repository.dart';
import '../data/repositories/favorite_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/dispute_repository.dart';
import '../data/services/realtime_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/location_service.dart';
import '../data/services/paystack_service.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut(() => RealtimeService(), fenix: true);
    Get.lazyPut(() => NotificationService(), fenix: true);
    Get.lazyPut(() => LocationService(), fenix: true);
    Get.lazyPut(() => PaystackService(), fenix: true);

    // Repositories
    Get.lazyPut(() => AuthRepository(), fenix: true);
    Get.lazyPut(() => ProfileRepository(), fenix: true);
    Get.lazyPut(() => NotificationRepository(), fenix: true);
    Get.lazyPut(() => WorkerRepository(), fenix: true);
    Get.lazyPut(() => SkillRepository(), fenix: true);
    Get.lazyPut(() => JobRepository(), fenix: true);
    Get.lazyPut(() => ApplicationRepository(), fenix: true);
    Get.lazyPut(() => BookingRepository(), fenix: true);
    Get.lazyPut(() => ReviewRepository(), fenix: true);
    Get.lazyPut(() => ChatRepository(), fenix: true);
    Get.lazyPut(() => PaymentRepository(), fenix: true);
    Get.lazyPut(() => SubscriptionRepository(), fenix: true);
    Get.lazyPut(() => StorageRepository(), fenix: true);
    Get.lazyPut(() => FavoriteRepository(), fenix: true);
    Get.lazyPut(() => ReportRepository(), fenix: true);
    Get.lazyPut(() => DisputeRepository(), fenix: true);

    // Global controllers (permanent)
    Get.put(ThemeController(), permanent: true);
    Get.put(ConnectivityController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(NotificationController(), permanent: true);

    // Lazy controllers (created on demand)
    Get.lazyPut(() => ProfileController(), fenix: true);
    Get.lazyPut(() => WorkerProfileController(), fenix: true);
    Get.lazyPut(() => JobController(), fenix: true);
    Get.lazyPut(() => ApplicationController(), fenix: true);
    Get.lazyPut(() => BookingController(), fenix: true);
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(() => PaymentController(), fenix: true);
    Get.lazyPut(() => SubscriptionController(), fenix: true);
    Get.lazyPut(() => ReviewController(), fenix: true);
    Get.lazyPut(() => LocationController(), fenix: true);
    Get.lazyPut(() => DisputeController(), fenix: true);
    Get.lazyPut(() => MapController(), fenix: true);
  }
}
