class SkillModel {
  final String id;
  final String name;
  final String slug;
  final String categoryId;
  final bool isActive;

  const SkillModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.categoryId,
    this.isActive = true,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      categoryId: json['category_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'category_id': categoryId,
      'is_active': isActive,
    };
  }

  SkillModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? categoryId,
    bool? isActive,
  }) {
    return SkillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SkillModel(id: $id, name: $name)';
}
