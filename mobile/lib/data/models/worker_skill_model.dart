import 'skill_model.dart';

class WorkerSkillModel {
  final String id;
  final String workerId;
  final String skillId;
  final int proficiencyLevel;
  final int yearsExperience;
  final double hourlyRate;
  final SkillModel? skill;

  const WorkerSkillModel({
    required this.id,
    required this.workerId,
    required this.skillId,
    required this.proficiencyLevel,
    required this.yearsExperience,
    required this.hourlyRate,
    this.skill,
  });

  factory WorkerSkillModel.fromJson(Map<String, dynamic> json) {
    return WorkerSkillModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      skillId: json['skill_id'] as String,
      proficiencyLevel: (json['proficiency_level'] as num?)?.toInt() ?? 1,
      yearsExperience: (json['years_experience'] as num?)?.toInt() ?? 0,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      skill: json['skill'] != null
          ? SkillModel.fromJson(json['skill'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'skill_id': skillId,
      'proficiency_level': proficiencyLevel,
      'years_experience': yearsExperience,
      'hourly_rate': hourlyRate,
      if (skill != null) 'skill': skill!.toJson(),
    };
  }

  WorkerSkillModel copyWith({
    String? id,
    String? workerId,
    String? skillId,
    int? proficiencyLevel,
    int? yearsExperience,
    double? hourlyRate,
    SkillModel? skill,
  }) {
    return WorkerSkillModel(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      skillId: skillId ?? this.skillId,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      skill: skill ?? this.skill,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerSkillModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WorkerSkillModel(id: $id, skillId: $skillId, proficiency: $proficiencyLevel)';
}
