import 'package:equatable/equatable.dart';

enum AgentStatus { queued, planning, running, waitingForInput, waitingForApproval, completed, failed, cancelled }

class AgentRunEvent extends Equatable {
  final String id;
  final String eventType;
  final String? message;
  final Map<String, dynamic> payload;
  final String? taskId;
  final DateTime createdAt;

  const AgentRunEvent({
    required this.id,
    required this.eventType,
    this.message,
    this.payload = const {},
    this.taskId,
    required this.createdAt,
  });

  factory AgentRunEvent.fromJson(Map<String, dynamic> json) {
    return AgentRunEvent(
      id: json['id'] as String,
      eventType: json['event_type'] as String,
      message: json['message'] as String?,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      taskId: json['task_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, eventType, message, payload, taskId, createdAt];
}

class AgentRun extends Equatable {
  final String id;
  final String goalId;
  final AgentStatus status;
  final String? currentStep;
  final int? progress;
  final String? finalSummary;
  final String? error;
  final List<AgentRunEvent> events;

  const AgentRun({
    required this.id,
    required this.goalId,
    required this.status,
    this.currentStep,
    this.progress,
    this.finalSummary,
    this.error,
    this.events = const [],
  });

  factory AgentRun.fromJson(Map<String, dynamic> json) {
    return AgentRun(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      status: _parseStatus(json['status'] as String),
      currentStep: json['current_step'] as String?,
      progress: json['progress'] as int?,
      finalSummary: json['final_summary'] as String?,
      error: json['error'] as String?,
      events: const [], // populated separately
    );
  }

  AgentRun copyWith({
    String? id,
    String? goalId,
    AgentStatus? status,
    String? currentStep,
    int? progress,
    String? finalSummary,
    String? error,
    List<AgentRunEvent>? events,
  }) {
    return AgentRun(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      finalSummary: finalSummary ?? this.finalSummary,
      error: error ?? this.error,
      events: events ?? this.events,
    );
  }

  static AgentStatus _parseStatus(String status) {
    switch (status) {
      case 'queued': return AgentStatus.queued;
      case 'planning': return AgentStatus.planning;
      case 'running': return AgentStatus.running;
      case 'waiting_for_input': return AgentStatus.waitingForInput;
      case 'waiting_for_approval': return AgentStatus.waitingForApproval;
      case 'completed': return AgentStatus.completed;
      case 'failed': return AgentStatus.failed;
      case 'cancelled': return AgentStatus.cancelled;
      default: return AgentStatus.running;
    }
  }

  @override
  List<Object?> get props => [id, goalId, status, currentStep, progress, finalSummary, error, events];
}
