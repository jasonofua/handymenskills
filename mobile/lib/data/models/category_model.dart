class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? description;
  final bool isActive;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.description,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
      'description': description,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? icon,
    String? description,
    bool? isActive,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategoryModel(id: $id, name: $name, slug: $slug)';
}
