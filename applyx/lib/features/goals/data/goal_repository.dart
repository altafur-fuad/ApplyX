import '../domain/goal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      rawGoal:
          'Find paid remote Flutter internships suitable for a final-year CSE student.',
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

class SupabaseGoalRepository implements GoalRepository {
  final SupabaseClient _supabase;

  SupabaseGoalRepository(this._supabase);

  @override
  Future<List<Goal>> getGoals() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map(
          (data) => Goal(
            id: data['id'],
            title: data['title'],
            rawGoal: data['raw_goal'],
            createdAt: DateTime.parse(data['created_at']),
          ),
        )
        .toList();
  }

  @override
  Future<Goal?> getActiveGoal() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('goals')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return Goal(
      id: response['id'],
      title: response['title'],
      rawGoal: response['raw_goal'],
      createdAt: DateTime.parse(response['created_at']),
    );
  }

  @override
  Future<void> createGoal(Goal goal) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('goals').insert({
      'user_id': userId,
      'title': goal.title,
      'raw_goal': goal.rawGoal,
      'status': 'active',
      'created_at': goal.createdAt.toIso8601String(),
    });
  }
}
