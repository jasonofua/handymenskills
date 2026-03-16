/// All enums used across the Handymenskills data models.

enum UserRole {
  client,
  worker,
  admin;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.client,
    );
  }
}

enum AccountStatus {
  active,
  suspended,
  banned;

  static AccountStatus fromString(String? value) {
    return AccountStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccountStatus.active,
    );
  }
}

enum VerificationStatus {
  unverified,
  pending,
  verified,
  rejected;

  static VerificationStatus fromString(String? value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VerificationStatus.unverified,
    );
  }
}

enum BudgetType {
  fixed,
  hourly,
  negotiable;

  static BudgetType fromString(String? value) {
    return BudgetType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BudgetType.fixed,
    );
  }
}

enum UrgencyLevel {
  low,
  normal,
  urgent,
  emergency;

  static UrgencyLevel fromString(String? value) {
    return UrgencyLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UrgencyLevel.normal,
    );
  }
}

enum JobStatus {
  draft,
  open,
  assigned,
  inProgress,
  completed,
  cancelled,
  expired;

  /// Maps from snake_case DB values to enum values.
  static JobStatus fromString(String? value) {
    if (value == 'in_progress') return JobStatus.inProgress;
    return JobStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => JobStatus.draft,
    );
  }

  /// Returns the snake_case string suitable for DB storage.
  String toJsonValue() {
    switch (this) {
      case JobStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }
}

enum ApplicationStatus {
  pending,
  accepted,
  rejected,
  withdrawn;

  static ApplicationStatus fromString(String? value) {
    return ApplicationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ApplicationStatus.pending,
    );
  }
}

enum BookingStatus {
  pending,
  confirmed,
  workerEnRoute,
  inProgress,
  completed,
  clientConfirmed,
  cancelled,
  disputed;

  static BookingStatus fromString(String? value) {
    switch (value) {
      case 'worker_en_route':
        return BookingStatus.workerEnRoute;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'client_confirmed':
        return BookingStatus.clientConfirmed;
      default:
        return BookingStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => BookingStatus.pending,
        );
    }
  }

  String toJsonValue() {
    switch (this) {
      case BookingStatus.workerEnRoute:
        return 'worker_en_route';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.clientConfirmed:
        return 'client_confirmed';
      default:
        return name;
    }
  }
}

enum MessageType {
  text,
  image,
  file,
  location,
  system;

  static MessageType fromString(String? value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

enum NotificationType {
  newApplication,
  applicationAccepted,
  applicationRejected,
  bookingCreated,
  bookingConfirmed,
  bookingStarted,
  bookingCompleted,
  bookingCancelled,
  bookingDisputed,
  newMessage,
  newReview,
  paymentReceived,
  payoutProcessed,
  subscriptionExpiring,
  subscriptionExpired,
  verificationApproved,
  verificationRejected,
  systemAnnouncement,
  strikeWarning,
  accountSuspended,
  workerEnRoute;

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'new_application':
        return NotificationType.newApplication;
      case 'application_accepted':
        return NotificationType.applicationAccepted;
      case 'application_rejected':
        return NotificationType.applicationRejected;
      case 'booking_created':
        return NotificationType.bookingCreated;
      case 'booking_confirmed':
        return NotificationType.bookingConfirmed;
      case 'booking_started':
        return NotificationType.bookingStarted;
      case 'booking_completed':
        return NotificationType.bookingCompleted;
      case 'booking_cancelled':
        return NotificationType.bookingCancelled;
      case 'booking_disputed':
        return NotificationType.bookingDisputed;
      case 'new_message':
        return NotificationType.newMessage;
      case 'new_review':
        return NotificationType.newReview;
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'payout_processed':
        return NotificationType.payoutProcessed;
      case 'subscription_expiring':
        return NotificationType.subscriptionExpiring;
      case 'subscription_expired':
        return NotificationType.subscriptionExpired;
      case 'verification_approved':
        return NotificationType.verificationApproved;
      case 'verification_rejected':
        return NotificationType.verificationRejected;
      case 'system_announcement':
        return NotificationType.systemAnnouncement;
      case 'strike_warning':
        return NotificationType.strikeWarning;
      case 'account_suspended':
        return NotificationType.accountSuspended;
      case 'worker_en_route':
        return NotificationType.workerEnRoute;
      default:
        return NotificationType.systemAnnouncement;
    }
  }

  String toJsonValue() {
    switch (this) {
      case NotificationType.newApplication:
        return 'new_application';
      case NotificationType.applicationAccepted:
        return 'application_accepted';
      case NotificationType.applicationRejected:
        return 'application_rejected';
      case NotificationType.bookingCreated:
        return 'booking_created';
      case NotificationType.bookingConfirmed:
        return 'booking_confirmed';
      case NotificationType.bookingStarted:
        return 'booking_started';
      case NotificationType.bookingCompleted:
        return 'booking_completed';
      case NotificationType.bookingCancelled:
        return 'booking_cancelled';
      case NotificationType.bookingDisputed:
        return 'booking_disputed';
      case NotificationType.newMessage:
        return 'new_message';
      case NotificationType.newReview:
        return 'new_review';
      case NotificationType.paymentReceived:
        return 'payment_received';
      case NotificationType.payoutProcessed:
        return 'payout_processed';
      case NotificationType.subscriptionExpiring:
        return 'subscription_expiring';
      case NotificationType.subscriptionExpired:
        return 'subscription_expired';
      case NotificationType.verificationApproved:
        return 'verification_approved';
      case NotificationType.verificationRejected:
        return 'verification_rejected';
      case NotificationType.systemAnnouncement:
        return 'system_announcement';
      case NotificationType.strikeWarning:
        return 'strike_warning';
      case NotificationType.accountSuspended:
        return 'account_suspended';
      case NotificationType.workerEnRoute:
        return 'worker_en_route';
    }
  }
}

enum PaymentType {
  bookingPayment,
  subscriptionPayment,
  tip,
  refund;

  static PaymentType fromString(String? value) {
    switch (value) {
      case 'booking_payment':
        return PaymentType.bookingPayment;
      case 'subscription_payment':
        return PaymentType.subscriptionPayment;
      case 'tip':
        return PaymentType.tip;
      case 'refund':
        return PaymentType.refund;
      default:
        return PaymentType.bookingPayment;
    }
  }

  String toJsonValue() {
    switch (this) {
      case PaymentType.bookingPayment:
        return 'booking_payment';
      case PaymentType.subscriptionPayment:
        return 'subscription_payment';
      case PaymentType.tip:
        return 'tip';
      case PaymentType.refund:
        return 'refund';
    }
  }
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded;

  static PaymentStatus fromString(String? value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

enum PayoutStatus {
  pending,
  processing,
  completed,
  failed;

  static PayoutStatus fromString(String? value) {
    return PayoutStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PayoutStatus.pending,
    );
  }
}

enum SubscriptionStatus {
  active,
  expired,
  gracePeriod,
  cancelled;

  static SubscriptionStatus fromString(String? value) {
    if (value == 'grace_period') return SubscriptionStatus.gracePeriod;
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SubscriptionStatus.active,
    );
  }

  String toJsonValue() {
    switch (this) {
      case SubscriptionStatus.gracePeriod:
        return 'grace_period';
      default:
        return name;
    }
  }
}

enum ReportReason {
  spam,
  harassment,
  fraud,
  inappropriateContent,
  fakeProfile,
  poorService,
  noShow,
  other;

  static ReportReason fromString(String? value) {
    switch (value) {
      case 'spam':
        return ReportReason.spam;
      case 'harassment':
        return ReportReason.harassment;
      case 'fraud':
        return ReportReason.fraud;
      case 'inappropriate_content':
        return ReportReason.inappropriateContent;
      case 'fake_profile':
        return ReportReason.fakeProfile;
      case 'poor_service':
        return ReportReason.poorService;
      case 'no_show':
        return ReportReason.noShow;
      case 'other':
        return ReportReason.other;
      default:
        return ReportReason.other;
    }
  }

  String toJsonValue() {
    switch (this) {
      case ReportReason.inappropriateContent:
        return 'inappropriate_content';
      case ReportReason.fakeProfile:
        return 'fake_profile';
      case ReportReason.poorService:
        return 'poor_service';
      case ReportReason.noShow:
        return 'no_show';
      default:
        return name;
    }
  }
}

enum ReportStatus {
  pending,
  investigating,
  resolved,
  dismissed;

  static ReportStatus fromString(String? value) {
    return ReportStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

enum DisputeStatus {
  open,
  investigating,
  resolved,
  closed;

  static DisputeStatus fromString(String? value) {
    return DisputeStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DisputeStatus.open,
    );
  }
}
