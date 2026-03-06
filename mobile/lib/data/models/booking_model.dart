import 'enums.dart';
import 'job_model.dart';
import 'profile_model.dart';

class BookingModel {
  final String id;
  final String jobId;
  final String clientId;
  final String workerId;
  final String applicationId;
  final BookingStatus status;
  final double agreedPrice;
  final double platformCommission;
  final double workerPayout;
  final DateTime? scheduledDate;
  final String? scheduledTimeStart;
  final String? scheduledTimeEnd;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? clientConfirmedAt;
  final String? cancellationReason;
  final String? cancelledBy;
  final int bookingNumber;
  final List<String> completionPhotos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JobModel? job;
  final ProfileModel? client;
  final ProfileModel? worker;

  const BookingModel({
    required this.id,
    required this.jobId,
    required this.clientId,
    required this.workerId,
    required this.applicationId,
    this.status = BookingStatus.pending,
    required this.agreedPrice,
    required this.platformCommission,
    required this.workerPayout,
    this.scheduledDate,
    this.scheduledTimeStart,
    this.scheduledTimeEnd,
    this.startedAt,
    this.completedAt,
    this.clientConfirmedAt,
    this.cancellationReason,
    this.cancelledBy,
    this.bookingNumber = 0,
    this.completionPhotos = const [],
    required this.createdAt,
    required this.updatedAt,
    this.job,
    this.client,
    this.worker,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      clientId: json['client_id'] as String,
      workerId: json['worker_id'] as String,
      applicationId: json['application_id'] as String,
      status: BookingStatus.fromString(json['status'] as String?),
      agreedPrice: (json['agreed_price'] as num?)?.toDouble() ?? 0.0,
      platformCommission:
          (json['platform_commission'] as num?)?.toDouble() ?? 0.0,
      workerPayout: (json['worker_payout'] as num?)?.toDouble() ?? 0.0,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'] as String)
          : null,
      scheduledTimeStart: json['scheduled_time_start'] as String?,
      scheduledTimeEnd: json['scheduled_time_end'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      clientConfirmedAt: json['client_confirmed_at'] != null
          ? DateTime.tryParse(json['client_confirmed_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      bookingNumber: (json['booking_number'] as num?)?.toInt() ?? 0,
      completionPhotos: json['completion_photos'] != null
          ? List<String>.from(json['completion_photos'] as List)
          : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      job: json['job'] != null
          ? JobModel.fromJson(json['job'] as Map<String, dynamic>)
          : null,
      client: json['client'] != null
          ? ProfileModel.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      worker: json['worker'] != null
          ? ProfileModel.fromJson(json['worker'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'client_id': clientId,
      'worker_id': workerId,
      'application_id': applicationId,
      'status': status.toJsonValue(),
      'agreed_price': agreedPrice,
      'platform_commission': platformCommission,
      'worker_payout': workerPayout,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'scheduled_time_start': scheduledTimeStart,
      'scheduled_time_end': scheduledTimeEnd,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'client_confirmed_at': clientConfirmedAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'cancelled_by': cancelledBy,
      'booking_number': bookingNumber,
      'completion_photos': completionPhotos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (job != null) 'job': job!.toJson(),
      if (client != null) 'client': client!.toJson(),
      if (worker != null) 'worker': worker!.toJson(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? jobId,
    String? clientId,
    String? workerId,
    String? applicationId,
    BookingStatus? status,
    double? agreedPrice,
    double? platformCommission,
    double? workerPayout,
    DateTime? scheduledDate,
    String? scheduledTimeStart,
    String? scheduledTimeEnd,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? clientConfirmedAt,
    String? cancellationReason,
    String? cancelledBy,
    int? bookingNumber,
    List<String>? completionPhotos,
    DateTime? createdAt,
    DateTime? updatedAt,
    JobModel? job,
    ProfileModel? client,
    ProfileModel? worker,
  }) {
    return BookingModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      clientId: clientId ?? this.clientId,
      workerId: workerId ?? this.workerId,
      applicationId: applicationId ?? this.applicationId,
      status: status ?? this.status,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      platformCommission: platformCommission ?? this.platformCommission,
      workerPayout: workerPayout ?? this.workerPayout,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTimeStart: scheduledTimeStart ?? this.scheduledTimeStart,
      scheduledTimeEnd: scheduledTimeEnd ?? this.scheduledTimeEnd,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      clientConfirmedAt: clientConfirmedAt ?? this.clientConfirmedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      completionPhotos: completionPhotos ?? this.completionPhotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      job: job ?? this.job,
      client: client ?? this.client,
      worker: worker ?? this.worker,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BookingModel(id: $id, bookingNumber: $bookingNumber, status: $status)';
}
