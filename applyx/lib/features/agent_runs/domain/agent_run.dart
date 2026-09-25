import 'package:equatable/equatable.dart';

enum AgentStatus { queued, running, completed, approval, failed, cancelled }

class AgentStep extends Equatable {
  final String id;
  final String title;
  final String description;
  final AgentStatus status;

  const AgentStep({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  AgentStep copyWith({
    String? id,
    String? title,
    String? description,
    AgentStatus? status,
  }) {
    return AgentStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, title, description, status];
}

class AgentRun extends Equatable {
  final String id;
  final String goalId;
  final AgentStatus status;
  final List<AgentStep> steps;

  const AgentRun({
    required this.id,
    required this.goalId,
    required this.status,
    required this.steps,
  });

  AgentRun copyWith({
    String? id,
    String? goalId,
    AgentStatus? status,
    List<AgentStep>? steps,
  }) {
    return AgentRun(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      status: status ?? this.status,
      steps: steps ?? this.steps,
    );
  }

  @override
  List<Object?> get props => [id, goalId, status, steps];
}
