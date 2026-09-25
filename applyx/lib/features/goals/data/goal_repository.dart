import '../domain/goal.dart';

abstract class GoalRepository {
  Future<List<Goal>> getGoals();
  Future<Goal?> getActiveGoal();
  Future<void> createGoal(Goal goal);
}

class MockGoalRepository implements GoalRepository {
  final List<Goal> _goals = [
    Goal(
      id: 'g1',
      title: 'Find paid remote Flutter internships',
      rawGoal: 'Find paid remote Flutter internships suitable for a final-year CSE student.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<Goal>> getGoals() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _goals;
  }

  @override
  Future<Goal?> getActiveGoal() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _goals.isNotEmpty ? _goals.first : null;
  }

  @override
  Future<void> createGoal(Goal goal) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _goals.insert(0, goal);
  }
}
