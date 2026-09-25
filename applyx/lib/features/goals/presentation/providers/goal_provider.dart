import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/goal.dart';
import '../../data/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return MockGoalRepository();
});

final activeGoalProvider = FutureProvider<Goal?>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.getActiveGoal();
});
