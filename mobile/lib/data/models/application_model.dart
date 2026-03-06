import 'enums.dart';
import 'job_model.dart';
import 'worker_profile_model.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String workerId;
  final ApplicationStatus status;
  final String coverLetter;
  final double proposedPrice;
  final String? estimatedDuration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WorkerProfileModel? worker;
  final JobModel? job;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    this.status = ApplicationStatus.pending,
    required this.coverLetter,
    required this.proposedPrice,
    this.estimatedDuration,
    required this.createdAt,
    required this.updatedAt,
    this.worker,
    this.job,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      workerId: json['worker_id'] as String,
      status: ApplicationStatus.fromString(json['status'] as String?),
      coverLetter: json['cover_letter'] as String,
      proposedPrice: (json['proposed_price'] as num?)?.toDouble() ?? 0.0,
      estimatedDuration: json['estimated_duration'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      worker: json['worker'] != null
          ? WorkerProfileModel.fromJson(
              json['worker'] as Map<String, dynamic>)
          : null,
      job: json['job'] != null
          ? JobModel.fromJson(json['job'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'worker_id': workerId,
      'status': status.name,
      'cover_letter': coverLetter,
      'proposed_price': proposedPrice,
      'estimated_duration': estimatedDuration,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (worker != null) 'worker': worker!.toJson(),
      if (job != null) 'job': job!.toJson(),
    };
  }

  ApplicationModel copyWith({
    String? id,
    String? jobId,
    String? workerId,
    ApplicationStatus? status,
    String? coverLetter,
    double? proposedPrice,
    String? estimatedDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
    WorkerProfileModel? worker,
    JobModel? job,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      workerId: workerId ?? this.workerId,
      status: status ?? this.status,
      coverLetter: coverLetter ?? this.coverLetter,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      worker: worker ?? this.worker,
      job: job ?? this.job,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ApplicationModel(id: $id, jobId: $jobId, status: $status)';
}
