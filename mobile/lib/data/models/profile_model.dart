import 'enums.dart';

class ProfileModel {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final UserRole role;
  final AccountStatus accountStatus;
  final String? city;
  final String? state;
  final String? lga;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? fcmToken;
  final int strikes;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    required this.role,
    required this.accountStatus,
    this.city,
    this.state,
    this.lga,
    this.address,
    this.latitude,
    this.longitude,
    this.fcmToken,
    this.strikes = 0,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      accountStatus:
          AccountStatus.fromString(json['account_status'] as String?),
      city: json['city'] as String?,
      state: json['state'] as String?,
      lga: json['lga'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      fcmToken: json['fcm_token'] as String?,
      strikes: (json['strikes'] as num?)?.toInt() ?? 0,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role.name,
      'account_status': accountStatus.name,
      'city': city,
      'state': state,
      'lga': lga,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'fcm_token': fcmToken,
      'strikes': strikes,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    UserRole? role,
    AccountStatus? accountStatus,
    String? city,
    String? state,
    String? lga,
    String? address,
    double? latitude,
    double? longitude,
    String? fcmToken,
    int? strikes,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      city: city ?? this.city,
      state: state ?? this.state,
      lga: lga ?? this.lga,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fcmToken: fcmToken ?? this.fcmToken,
      strikes: strikes ?? this.strikes,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ProfileModel(id: $id, fullName: $fullName, role: $role)';
}
