import 'profile_model.dart';

class ReviewModel {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String revieweeId;
  final int overallRating;
  final int? qualityRating;
  final int? communicationRating;
  final int? punctualityRating;
  final int? valueRating;
  final String? comment;
  final String? response;
  final bool isVisible;
  final DateTime createdAt;
  final ProfileModel? reviewer;
  final ProfileModel? reviewee;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.overallRating,
    this.qualityRating,
    this.communicationRating,
    this.punctualityRating,
    this.valueRating,
    this.comment,
    this.response,
    this.isVisible = true,
    required this.createdAt,
    this.reviewer,
    this.reviewee,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      revieweeId: json['reviewee_id'] as String,
      overallRating: (json['overall_rating'] as num?)?.toInt() ?? 1,
      qualityRating: (json['quality_rating'] as num?)?.toInt(),
      communicationRating: (json['communication_rating'] as num?)?.toInt(),
      punctualityRating: (json['punctuality_rating'] as num?)?.toInt(),
      valueRating: (json['value_rating'] as num?)?.toInt(),
      comment: json['comment'] as String?,
      response: json['response'] as String?,
      isVisible: json['is_visible'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewer: json['reviewer'] != null
          ? ProfileModel.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
      reviewee: json['reviewee'] != null
          ? ProfileModel.fromJson(json['reviewee'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'overall_rating': overallRating,
      'quality_rating': qualityRating,
      'communication_rating': communicationRating,
      'punctuality_rating': punctualityRating,
      'value_rating': valueRating,
      'comment': comment,
      'response': response,
      'is_visible': isVisible,
      'created_at': createdAt.toIso8601String(),
      if (reviewer != null) 'reviewer': reviewer!.toJson(),
      if (reviewee != null) 'reviewee': reviewee!.toJson(),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? bookingId,
    String? reviewerId,
    String? revieweeId,
    int? overallRating,
    int? qualityRating,
    int? communicationRating,
    int? punctualityRating,
    int? valueRating,
    String? comment,
    String? response,
    bool? isVisible,
    DateTime? createdAt,
    ProfileModel? reviewer,
    ProfileModel? reviewee,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      overallRating: overallRating ?? this.overallRating,
      qualityRating: qualityRating ?? this.qualityRating,
      communicationRating: communicationRating ?? this.communicationRating,
      punctualityRating: punctualityRating ?? this.punctualityRating,
      valueRating: valueRating ?? this.valueRating,
      comment: comment ?? this.comment,
      response: response ?? this.response,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      reviewer: reviewer ?? this.reviewer,
      reviewee: reviewee ?? this.reviewee,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ReviewModel(id: $id, bookingId: $bookingId, rating: $overallRating)';
}
