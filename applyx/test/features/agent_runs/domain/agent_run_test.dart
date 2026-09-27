import 'package:flutter_test/flutter_test.dart';
import 'package:applyx/features/agent_runs/domain/agent_run.dart';

void main() {
  group('AgentRunEvent', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'e1',
        'event_type': 'task_started',
        'message': 'Starting task',
        'payload': {'task_name': 'Research'},
        'task_id': 't1',
        'created_at': '2026-09-27T10:00:00Z',
      };
      final event = AgentRunEvent.fromJson(json);

      expect(event.id, 'e1');
      expect(event.eventType, 'task_started');
      expect(event.message, 'Starting task');
      expect(event.payload['task_name'], 'Research');
      expect(event.taskId, 't1');
      expect(event.createdAt, DateTime.parse('2026-09-27T10:00:00Z'));
    });
  });

  group('AgentRun', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'run1',
        'goal_id': 'g1',
        'user_id': 'u1',
        'status': 'running',
        'current_step': 'profile_fit',
        'progress': 62,
        'final_summary': null,
        'error': null,
      };
      final run = AgentRun.fromJson(json);

      expect(run.id, 'run1');
      expect(run.goalId, 'g1');
      expect(run.status, AgentStatus.running);
      expect(run.currentStep, 'profile_fit');
      expect(run.progress, 62);
      expect(run.finalSummary, isNull);
      expect(run.events, isEmpty);
    });

    test('copyWith updates fields', () {
      final run = const AgentRun(
        id: '1',
        goalId: '2',
        status: AgentStatus.queued,
      );
      
      final updated = run.copyWith(status: AgentStatus.completed, progress: 100);
      expect(updated.status, AgentStatus.completed);
      expect(updated.progress, 100);
      expect(updated.id, '1');
    });
  });
}
