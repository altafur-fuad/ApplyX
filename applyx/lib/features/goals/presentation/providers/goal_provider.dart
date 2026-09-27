import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/goal.dart';
import '../../data/goal_repository.dart';
import '../../../../core/network/api_client.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiGoalRepository(apiClient);
});

final activeGoalProvider = FutureProvider<Goal?>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.getActiveGoal();
});
