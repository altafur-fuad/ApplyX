import 'package:equatable/equatable.dart';

class StructuredConstraints extends Equatable {
  final List<String>? opportunityTypes;
  final List<String>? skills;
  final bool? paid;
  final bool? remote;

  const StructuredConstraints({
    this.opportunityTypes,
    this.skills,
    this.paid,
    this.remote,
  });

  factory StructuredConstraints.fromJson(Map<String, dynamic> json) {
    return StructuredConstraints(
      opportunityTypes: (json['opportunity_types'] as List<dynamic>?)?.map((e) => e as String).toList(),
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList(),
      paid: json['paid'] as bool?,
      remote: json['remote'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (opportunityTypes != null) 'opportunity_types': opportunityTypes,
      if (skills != null) 'skills': skills,
      if (paid != null) 'paid': paid,
      if (remote != null) 'remote': remote,
    };
  }

  @override
  List<Object?> get props => [opportunityTypes, skills, paid, remote];
}

class Goal extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String rawGoal;
  final StructuredConstraints structuredConstraints;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.rawGoal,
    required this.structuredConstraints,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      rawGoal: json['raw_goal'] as String,
      structuredConstraints: json['structured_constraints_json'] != null 
          ? StructuredConstraints.fromJson(json['structured_constraints_json'] as Map<String, dynamic>)
          : const StructuredConstraints(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, title, rawGoal, structuredConstraints, status, createdAt, updatedAt];
}

class CreateGoalRequest extends Equatable {
  final String title;
  final String rawGoal;
  final StructuredConstraints? structuredConstraints;

  const CreateGoalRequest({
    required this.title,
    required this.rawGoal,
    this.structuredConstraints,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'raw_goal': rawGoal,
      if (structuredConstraints != null) 'structured_constraints': structuredConstraints!.toJson(),
    };
  }

  @override
  List<Object?> get props => [title, rawGoal, structuredConstraints];
}

class UpdateGoalRequest extends Equatable {
  final String? title;
  final String? rawGoal;
  final StructuredConstraints? structuredConstraints;
  final String? status;

  const UpdateGoalRequest({
    this.title,
    this.rawGoal,
    this.structuredConstraints,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (rawGoal != null) 'raw_goal': rawGoal,
      if (structuredConstraints != null) 'structured_constraints': structuredConstraints!.toJson(),
      if (status != null) 'status': status,
    };
  }

  @override
  List<Object?> get props => [title, rawGoal, structuredConstraints, status];
}
