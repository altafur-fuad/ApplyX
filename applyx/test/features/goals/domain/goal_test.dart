import 'package:flutter_test/flutter_test.dart';
import 'package:applyx/features/goals/domain/goal.dart';

void main() {
  group('CreateGoalRequest', () {
    test('toJson serializes correctly without constraints', () {
      final request = CreateGoalRequest(
        title: 'Title',
        rawGoal: 'Raw goal',
      );
      
      expect(request.toJson(), {
        'title': 'Title',
        'raw_goal': 'Raw goal',
      });
    });

    test('toJson serializes correctly with constraints', () {
      final request = CreateGoalRequest(
        title: 'Title',
        rawGoal: 'Raw goal',
        structuredConstraints: StructuredConstraints(
          opportunityTypes: ['internship'],
          paid: true,
        ),
      );
      
      expect(request.toJson(), {
        'title': 'Title',
        'raw_goal': 'Raw goal',
        'structured_constraints': {
          'opportunity_types': ['internship'],
          'paid': true,
        },
      });
    });
  });

  group('Goal', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'g1',
        'user_id': 'u1',
        'title': 'Title',
        'raw_goal': 'Raw goal',
        'structured_constraints_json': {
          'remote': true,
        },
        'status': 'active',
        'created_at': '2026-09-27T10:00:00Z',
        'updated_at': '2026-09-27T10:00:00Z',
      };

      final goal = Goal.fromJson(json);

      expect(goal.id, 'g1');
      expect(goal.userId, 'u1');
      expect(goal.title, 'Title');
      expect(goal.structuredConstraints.remote, true);
      expect(goal.status, 'active');
      expect(goal.createdAt, DateTime.parse('2026-09-27T10:00:00Z'));
    });
  });
}
