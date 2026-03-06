import 'enums.dart';
import 'subscription_plan_model.dart';

class SubscriptionModel {
  final String id;
  final String workerId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime startsAt;
  final DateTime expiresAt;
  final DateTime? graceExpiresAt;
  final bool autoRenew;
  final DateTime createdAt;
  final SubscriptionPlanModel? plan;

  const SubscriptionModel({
    required this.id,
    required this.workerId,
    required this.planId,
    this.status = SubscriptionStatus.active,
    required this.startsAt,
    required this.expiresAt,
    this.graceExpiresAt,
    this.autoRenew = true,
    required this.createdAt,
    this.plan,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      planId: json['plan_id'] as String,
      status: SubscriptionStatus.fromString(json['status'] as String?),
      startsAt: DateTime.parse(json['starts_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      graceExpiresAt: json['grace_expires_at'] != null
          ? DateTime.tryParse(json['grace_expires_at'] as String)
          : null,
      autoRenew: json['auto_renew'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      plan: json['plan'] != null
          ? SubscriptionPlanModel.fromJson(
              json['plan'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'plan_id': planId,
      'status': status.toJsonValue(),
      'starts_at': startsAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'grace_expires_at': graceExpiresAt?.toIso8601String(),
      'auto_renew': autoRenew,
      'created_at': createdAt.toIso8601String(),
      if (plan != null) 'plan': plan!.toJson(),
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? workerId,
    String? planId,
    SubscriptionStatus? status,
    DateTime? startsAt,
    DateTime? expiresAt,
    DateTime? graceExpiresAt,
    bool? autoRenew,
    DateTime? createdAt,
    SubscriptionPlanModel? plan,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      startsAt: startsAt ?? this.startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      graceExpiresAt: graceExpiresAt ?? this.graceExpiresAt,
      autoRenew: autoRenew ?? this.autoRenew,
      createdAt: createdAt ?? this.createdAt,
      plan: plan ?? this.plan,
    );
  }

  /// Whether this subscription is currently valid (active or within grace period).
  bool get isValid {
    if (status == SubscriptionStatus.active) {
      return DateTime.now().isBefore(expiresAt);
    }
    if (status == SubscriptionStatus.gracePeriod &&
        graceExpiresAt != null) {
      return DateTime.now().isBefore(graceExpiresAt!);
    }
    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SubscriptionModel(id: $id, status: $status, expiresAt: $expiresAt)';
}
