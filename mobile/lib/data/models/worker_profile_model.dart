import 'enums.dart';
import 'worker_skill_model.dart';

class WorkerProfileModel {
  final String id;
  final String userId;
  final String? bio;
  final String? headline;
  final int experienceYears;
  final bool isAvailable;
  final int serviceRadiusKm;
  final VerificationStatus verificationStatus;
  final String? idDocumentUrl;
  final double averageRating;
  final int totalReviews;
  final int totalJobsCompleted;
  final double totalEarnings;
  final double completionRate;
  final List<String> portfolioImages;
  final double? latitude;
  final double? longitude;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WorkerSkillModel>? skills;

  const WorkerProfileModel({
    required this.id,
    required this.userId,
    this.bio,
    this.headline,
    this.experienceYears = 0,
    this.isAvailable = true,
    this.serviceRadiusKm = 10,
    this.verificationStatus = VerificationStatus.unverified,
    this.idDocumentUrl,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalJobsCompleted = 0,
    this.totalEarnings = 0.0,
    this.completionRate = 0.0,
    this.portfolioImages = const [],
    this.latitude,
    this.longitude,
    this.bankName,
    this.accountNumber,
    this.accountName,
    required this.createdAt,
    required this.updatedAt,
    this.skills,
  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    return WorkerProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bio: json['bio'] as String?,
      headline: json['headline'] as String?,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      serviceRadiusKm: (json['service_radius_km'] as num?)?.toInt() ?? 10,
      verificationStatus: VerificationStatus.fromString(
        json['verification_status'] as String?,
      ),
      idDocumentUrl: json['id_document_url'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      totalJobsCompleted:
          (json['total_jobs_completed'] as num?)?.toInt() ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      portfolioImages: json['portfolio_images'] != null
          ? List<String>.from(json['portfolio_images'] as List)
          : [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      accountName: json['account_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      skills: json['skills'] != null
          ? (json['skills'] as List)
              .map((e) =>
                  WorkerSkillModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bio': bio,
      'headline': headline,
      'experience_years': experienceYears,
      'is_available': isAvailable,
      'service_radius_km': serviceRadiusKm,
      'verification_status': verificationStatus.name,
      'id_document_url': idDocumentUrl,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'total_jobs_completed': totalJobsCompleted,
      'total_earnings': totalEarnings,
      'completion_rate': completionRate,
      'portfolio_images': portfolioImages,
      'latitude': latitude,
      'longitude': longitude,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (skills != null)
        'skills': skills!.map((e) => e.toJson()).toList(),
    };
  }

  WorkerProfileModel copyWith({
    String? id,
    String? userId,
    String? bio,
    String? headline,
    int? experienceYears,
    bool? isAvailable,
    int? serviceRadiusKm,
    VerificationStatus? verificationStatus,
    String? idDocumentUrl,
    double? averageRating,
    int? totalReviews,
    int? totalJobsCompleted,
    double? totalEarnings,
    double? completionRate,
    List<String>? portfolioImages,
    double? latitude,
    double? longitude,
    String? bankName,
    String? accountNumber,
    String? accountName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<WorkerSkillModel>? skills,
  }) {
    return WorkerProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bio: bio ?? this.bio,
      headline: headline ?? this.headline,
      experienceYears: experienceYears ?? this.experienceYears,
      isAvailable: isAvailable ?? this.isAvailable,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      idDocumentUrl: idDocumentUrl ?? this.idDocumentUrl,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalJobsCompleted: totalJobsCompleted ?? this.totalJobsCompleted,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      completionRate: completionRate ?? this.completionRate,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      skills: skills ?? this.skills,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WorkerProfileModel(id: $id, userId: $userId, verification: $verificationStatus)';
}
