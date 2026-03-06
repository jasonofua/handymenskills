import 'category_model.dart';
import 'enums.dart';
import 'profile_model.dart';

class JobModel {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final String categoryId;
  final List<String> skillIds;
  final String address;
  final String city;
  final String state;
  final double? latitude;
  final double? longitude;
  final double budgetMin;
  final double budgetMax;
  final BudgetType budgetType;
  final UrgencyLevel urgency;
  final JobStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> imageUrls;
  final int applicationCount;
  final int viewCount;
  final bool isRemote;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryModel? category;
  final ProfileModel? client;

  const JobModel({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.categoryId,
    this.skillIds = const [],
    required this.address,
    required this.city,
    required this.state,
    this.latitude,
    this.longitude,
    required this.budgetMin,
    required this.budgetMax,
    this.budgetType = BudgetType.fixed,
    this.urgency = UrgencyLevel.normal,
    this.status = JobStatus.draft,
    this.startDate,
    this.endDate,
    this.imageUrls = const [],
    this.applicationCount = 0,
    this.viewCount = 0,
    this.isRemote = false,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.client,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['category_id'] as String,
      skillIds: json['skill_ids'] != null
          ? List<String>.from(json['skill_ids'] as List)
          : [],
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      budgetMin: (json['budget_min'] as num?)?.toDouble() ?? 0.0,
      budgetMax: (json['budget_max'] as num?)?.toDouble() ?? 0.0,
      budgetType: BudgetType.fromString(json['budget_type'] as String?),
      urgency: UrgencyLevel.fromString(json['urgency'] as String?),
      status: JobStatus.fromString(json['status'] as String?),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : [],
      applicationCount:
          (json['application_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      isRemote: json['is_remote'] as bool? ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      client: json['client'] != null
          ? ProfileModel.fromJson(json['client'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'skill_ids': skillIds,
      'address': address,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'budget_type': budgetType.name,
      'urgency': urgency.name,
      'status': status.toJsonValue(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'image_urls': imageUrls,
      'application_count': applicationCount,
      'view_count': viewCount,
      'is_remote': isRemote,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (category != null) 'category': category!.toJson(),
      if (client != null) 'client': client!.toJson(),
    };
  }

  JobModel copyWith({
    String? id,
    String? clientId,
    String? title,
    String? description,
    String? categoryId,
    List<String>? skillIds,
    String? address,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    double? budgetMin,
    double? budgetMax,
    BudgetType? budgetType,
    UrgencyLevel? urgency,
    JobStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? imageUrls,
    int? applicationCount,
    int? viewCount,
    bool? isRemote,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    CategoryModel? category,
    ProfileModel? client,
  }) {
    return JobModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      skillIds: skillIds ?? this.skillIds,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      budgetType: budgetType ?? this.budgetType,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrls: imageUrls ?? this.imageUrls,
      applicationCount: applicationCount ?? this.applicationCount,
      viewCount: viewCount ?? this.viewCount,
      isRemote: isRemote ?? this.isRemote,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      client: client ?? this.client,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'JobModel(id: $id, title: $title, status: $status)';
}
