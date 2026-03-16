class AppRoutes {
  // Auth
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const roleSelection = '/role-selection';
  static const forgotPassword = '/forgot-password';

  // Worker
  static const workerDashboard = '/worker/dashboard';
  static const workerJobFeed = '/worker/jobs';
  static const workerJobDetail = '/worker/jobs/:id';
  static const workerJobSearch = '/worker/jobs/search';
  static const workerApplications = '/worker/applications';
  static const workerApplicationDetail = '/worker/applications/:id';
  static const workerBookings = '/worker/bookings';
  static const workerBookingDetail = '/worker/bookings/:id';
  static const workerEarnings = '/worker/earnings';
  static const workerPayout = '/worker/payout';
  static const workerProfile = '/worker/profile';
  static const workerEditProfile = '/worker/profile/edit';
  static const workerPortfolio = '/worker/profile/portfolio';
  static const workerVerification = '/worker/profile/verification';
  static const workerSubscription = '/worker/subscription';
  static const workerPlanSelection = '/worker/subscription/plans';

  // Client
  static const clientDashboard = '/client/dashboard';
  static const clientPostJob = '/client/post-job';
  static const clientEditJob = '/client/edit-job/:id';
  static const clientMyJobs = '/client/my-jobs';
  static const clientJobDetail = '/client/my-jobs/:id';
  static const clientFindWorkers = '/client/find-workers';
  static const clientWorkerProfile = '/client/workers/:id';
  static const clientJobApplications = '/client/my-jobs/:id/applications';
  static const clientBookings = '/client/bookings';
  static const clientBookingDetail = '/client/bookings/:id';
  static const clientJobPostedSuccess = '/client/job-posted-success';

  // Shared
  static const chat = '/chat';
  static const chatConversation = '/chat/:id';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const editProfile = '/settings/edit-profile';
  static const notificationSettings = '/settings/notifications';
  static const about = '/settings/about';
  static const reviews = '/reviews/:userId';
  static const writeReview = '/reviews/write/:bookingId';
  static const favorites = '/favorites';
  static const reportUser = '/report/:userId';
  static const disputes = '/disputes';
  static const createDispute = '/dispute/create/:bookingId';
  static const disputeDetail = '/dispute/:id';
}
