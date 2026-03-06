import 'enums.dart';

class DisputeModel {
  final String id;
  final String bookingId;
  final String initiatorId;
  final String reason;
  final List<String> evidence;
  final DisputeStatus status;
  final String? resolution;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const DisputeModel({
    required this.id,
    required this.bookingId,
    required this.initiatorId,
    required this.reason,
    this.evidence = const [],
    this.status = DisputeStatus.open,
    this.resolution,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      initiatorId: json['initiator_id'] as String,
      reason: json['reason'] as String,
      evidence: json['evidence'] != null
          ? List<String>.from(json['evidence'] as List)
          : [],
      status: DisputeStatus.fromString(json['status'] as String?),
      resolution: json['resolution'] as String?,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'initiator_id': initiatorId,
      'reason': reason,
      'evidence': evidence,
      'status': status.name,
      'resolution': resolution,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  DisputeModel copyWith({
    String? id,
    String? bookingId,
    String? initiatorId,
    String? reason,
    List<String>? evidence,
    DisputeStatus? status,
    String? resolution,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return DisputeModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      initiatorId: initiatorId ?? this.initiatorId,
      reason: reason ?? this.reason,
      evidence: evidence ?? this.evidence,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisputeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DisputeModel(id: $id, bookingId: $bookingId, status: $status)';
}
