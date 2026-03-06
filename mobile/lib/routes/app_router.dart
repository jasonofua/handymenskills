import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/onboarding/onboarding_screen.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/otp_screen.dart';
import '../modules/auth/register_screen.dart';
import '../modules/auth/role_selection_screen.dart';
import '../modules/worker/dashboard/worker_dashboard_screen.dart';
import '../modules/worker/job_feed/job_feed_screen.dart';
import '../modules/worker/job_feed/job_detail_screen.dart';
import '../modules/worker/applications/my_applications_screen.dart';
import '../modules/worker/bookings/worker_bookings_screen.dart';
import '../modules/worker/bookings/worker_booking_detail_screen.dart';
import '../modules/worker/earnings/earnings_screen.dart';
import '../modules/worker/profile/worker_profile_screen.dart';
import '../modules/worker/profile/edit_worker_profile_screen.dart';
import '../modules/worker/subscription/subscription_screen.dart';
import '../modules/worker/subscription/plan_selection_screen.dart';
import '../modules/client/dashboard/client_dashboard_screen.dart';
import '../modules/client/post_job/post_job_screen.dart';
import '../modules/client/my_jobs/my_jobs_screen.dart';
import '../modules/client/my_jobs/client_job_detail_screen.dart';
import '../modules/client/find_workers/find_workers_screen.dart';
import '../modules/client/find_workers/worker_profile_view_screen.dart';
import '../modules/client/bookings/client_bookings_screen.dart';
import '../modules/client/bookings/client_booking_detail_screen.dart';
import '../modules/shared/chat/conversations_screen.dart';
import '../modules/shared/chat/chat_screen.dart';
import '../modules/shared/notifications/notifications_screen.dart';
import '../modules/shared/settings/settings_screen.dart';
import '../modules/shared/reviews/reviews_list_screen.dart';
import '../modules/shared/reviews/write_review_screen.dart';
import '../modules/shared/favorites/favorites_screen.dart';
import '../modules/shared/report/report_screen.dart';
import '../modules/shared/disputes/disputes_list_screen.dart';
import '../modules/shared/disputes/create_dispute_screen.dart';
import '../modules/shared/disputes/dispute_detail_screen.dart';
import '../modules/shared/map/map_screen.dart';
import '../widgets/navigation/worker_bottom_nav.dart';
import '../widgets/navigation/client_bottom_nav.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _workerShellKey = GlobalKey<NavigatorState>();
final _clientShellKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter get router => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: _redirect,
    routes: [
      // Auth routes
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.otp, builder: (_, state) => OtpScreen(phone: state.extra as String)),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.roleSelection, builder: (_, __) => const RoleSelectionScreen()),

      // Worker shell with bottom navigation
      ShellRoute(
        navigatorKey: _workerShellKey,
        builder: (_, state, child) => WorkerBottomNav(child: child),
        routes: [
          GoRoute(path: AppRoutes.workerDashboard, builder: (_, __) => const WorkerDashboardScreen()),
          GoRoute(path: AppRoutes.workerJobFeed, builder: (_, __) => const JobFeedScreen()),
          GoRoute(path: AppRoutes.workerApplications, builder: (_, __) => const MyApplicationsScreen()),
          GoRoute(path: AppRoutes.workerBookings, builder: (_, __) => const WorkerBookingsScreen()),
          GoRoute(path: AppRoutes.workerProfile, builder: (_, __) => const WorkerProfileScreen()),
        ],
      ),

      // Client shell with bottom navigation
      ShellRoute(
        navigatorKey: _clientShellKey,
        builder: (_, state, child) => ClientBottomNav(child: child),
        routes: [
          GoRoute(path: AppRoutes.clientDashboard, builder: (_, __) => const ClientDashboardScreen()),
          GoRoute(path: AppRoutes.clientPostJob, builder: (_, __) => const PostJobScreen()),
          GoRoute(path: AppRoutes.clientMyJobs, builder: (_, __) => const MyJobsScreen()),
          GoRoute(path: AppRoutes.clientFindWorkers, builder: (_, __) => const FindWorkersScreen()),
          GoRoute(path: AppRoutes.clientBookings, builder: (_, __) => const ClientBookingsScreen()),
        ],
      ),

      // Worker detail routes (outside shell for full-screen)
      GoRoute(path: '/worker/jobs/:id', builder: (_, state) => JobDetailScreen(jobId: state.pathParameters['id']!)),
      GoRoute(path: '/worker/bookings/:id', builder: (_, state) => WorkerBookingDetailScreen(bookingId: state.pathParameters['id']!)),
      GoRoute(path: AppRoutes.workerEarnings, builder: (_, __) => const EarningsScreen()),
      GoRoute(path: AppRoutes.workerEditProfile, builder: (_, __) => const EditWorkerProfileScreen()),
      GoRoute(path: AppRoutes.workerSubscription, builder: (_, __) => const SubscriptionScreen()),
      GoRoute(path: AppRoutes.workerPlanSelection, builder: (_, __) => const PlanSelectionScreen()),

      // Client detail routes
      GoRoute(path: '/client/my-jobs/:id', builder: (_, state) => ClientJobDetailScreen(jobId: state.pathParameters['id']!)),
      GoRoute(path: '/client/workers/:id', builder: (_, state) => WorkerProfileViewScreen(workerId: state.pathParameters['id']!)),
      GoRoute(path: '/client/bookings/:id', builder: (_, state) => ClientBookingDetailScreen(bookingId: state.pathParameters['id']!)),

      // Shared routes
      GoRoute(path: AppRoutes.chat, builder: (_, __) => const ConversationsScreen()),
      GoRoute(path: '/chat/:id', builder: (_, state) => ChatScreen(conversationId: state.pathParameters['id']!)),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/reviews/:userId', builder: (_, state) => ReviewsListScreen(userId: state.pathParameters['userId']!)),
      GoRoute(path: '/reviews/write/:bookingId', builder: (_, state) => WriteReviewScreen(bookingId: state.pathParameters['bookingId']!)),
      GoRoute(path: AppRoutes.favorites, builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: '/report/:userId', builder: (_, state) => ReportScreen(userId: state.pathParameters['userId']!)),
      GoRoute(path: AppRoutes.disputes, builder: (_, __) => const DisputesListScreen()),
      GoRoute(path: '/dispute/create/:bookingId', builder: (_, state) => CreateDisputeScreen(bookingId: state.pathParameters['bookingId']!)),
      GoRoute(path: '/dispute/:id', builder: (_, state) => DisputeDetailScreen(disputeId: state.pathParameters['id']!)),
      GoRoute(path: AppRoutes.mapView, builder: (_, __) => const MapScreen()),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final authController = Get.find<AuthController>();
    final isLoggedIn = authController.isLoggedIn.value;
    final location = state.matchedLocation;

    final isAuthRoute = location == AppRoutes.splash ||
        location == AppRoutes.onboarding ||
        location == AppRoutes.login ||
        location == AppRoutes.otp ||
        location == AppRoutes.register ||
        location == AppRoutes.roleSelection;

    // Not logged in and not on an auth route → redirect to login
    if (!isLoggedIn && !isAuthRoute) {
      return AppRoutes.login;
    }

    // Logged in and on login page → redirect to appropriate dashboard
    if (isLoggedIn && (location == AppRoutes.login || location == AppRoutes.otp)) {
      final role = authController.userRole.value;
      if (role == 'worker') return AppRoutes.workerDashboard;
      if (role == 'client') return AppRoutes.clientDashboard;
      return AppRoutes.roleSelection;
    }

    return null;
  }
}
