import 'job_model.dart';
import 'profile_model.dart';

class ConversationModel {
  final String id;
  final String participantOne;
  final String participantTwo;
  final String? jobId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageBy;
  final DateTime createdAt;
  final ProfileModel? otherUser;
  final JobModel? job;

  const ConversationModel({
    required this.id,
    required this.participantOne,
    required this.participantTwo,
    this.jobId,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageBy,
    required this.createdAt,
    this.otherUser,
    this.job,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      participantOne: json['participant_one'] as String,
      participantTwo: json['participant_two'] as String,
      jobId: json['job_id'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)
          : null,
      lastMessageBy: json['last_message_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      otherUser: json['other_user'] != null
          ? ProfileModel.fromJson(
              json['other_user'] as Map<String, dynamic>)
          : null,
      job: json['job'] != null
          ? JobModel.fromJson(json['job'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_one': participantOne,
      'participant_two': participantTwo,
      'job_id': jobId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_by': lastMessageBy,
      'created_at': createdAt.toIso8601String(),
      if (otherUser != null) 'other_user': otherUser!.toJson(),
      if (job != null) 'job': job!.toJson(),
    };
  }

  ConversationModel copyWith({
    String? id,
    String? participantOne,
    String? participantTwo,
    String? jobId,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageBy,
    DateTime? createdAt,
    ProfileModel? otherUser,
    JobModel? job,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participantOne: participantOne ?? this.participantOne,
      participantTwo: participantTwo ?? this.participantTwo,
      jobId: jobId ?? this.jobId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageBy: lastMessageBy ?? this.lastMessageBy,
      createdAt: createdAt ?? this.createdAt,
      otherUser: otherUser ?? this.otherUser,
      job: job ?? this.job,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ConversationModel(id: $id, lastMessage: $lastMessage)';
}
