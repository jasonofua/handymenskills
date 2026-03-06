import 'enums.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String reportedId;
  final ReportReason reason;
  final String description;
  final ReportStatus status;
  final List<String> evidenceUrls;
  final String? resolvedBy;
  final String? resolutionNotes;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    required this.description,
    this.status = ReportStatus.pending,
    this.evidenceUrls = const [],
    this.resolvedBy,
    this.resolutionNotes,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reportedId: json['reported_id'] as String,
      reason: ReportReason.fromString(json['reason'] as String?),
      description: json['description'] as String,
      status: ReportStatus.fromString(json['status'] as String?),
      evidenceUrls: json['evidence_urls'] != null
          ? List<String>.from(json['evidence_urls'] as List)
          : [],
      resolvedBy: json['resolved_by'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reported_id': reportedId,
      'reason': reason.toJsonValue(),
      'description': description,
      'status': status.name,
      'evidence_urls': evidenceUrls,
      'resolved_by': resolvedBy,
      'resolution_notes': resolutionNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reportedId,
    ReportReason? reason,
    String? description,
    ReportStatus? status,
    List<String>? evidenceUrls,
    String? resolvedBy,
    String? resolutionNotes,
    DateTime? createdAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedId: reportedId ?? this.reportedId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ReportModel(id: $id, reason: $reason, status: $status)';
}
