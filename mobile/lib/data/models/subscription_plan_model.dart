class SubscriptionPlanModel {
  final String id;
  final String name;
  final String slug;
  final int durationMonths;
  final double price;
  final Map<String, dynamic> features;
  final int maxActiveApplications;
  final bool priorityListing;
  final bool isActive;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.durationMonths,
    required this.price,
    required this.features,
    required this.maxActiveApplications,
    this.priorityListing = false,
    this.isActive = true,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      durationMonths: (json['duration_months'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      features: json['features'] != null
          ? Map<String, dynamic>.from(json['features'] as Map)
          : {},
      maxActiveApplications:
          (json['max_active_applications'] as num?)?.toInt() ?? 10,
      priorityListing: json['priority_listing'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'duration_months': durationMonths,
      'price': price,
      'features': features,
      'max_active_applications': maxActiveApplications,
      'priority_listing': priorityListing,
      'is_active': isActive,
    };
  }

  SubscriptionPlanModel copyWith({
    String? id,
    String? name,
    String? slug,
    int? durationMonths,
    double? price,
    Map<String, dynamic>? features,
    int? maxActiveApplications,
    bool? priorityListing,
    bool? isActive,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      durationMonths: durationMonths ?? this.durationMonths,
      price: price ?? this.price,
      features: features ?? this.features,
      maxActiveApplications:
          maxActiveApplications ?? this.maxActiveApplications,
      priorityListing: priorityListing ?? this.priorityListing,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlanModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SubscriptionPlanModel(id: $id, name: $name, price: $price)';
}
