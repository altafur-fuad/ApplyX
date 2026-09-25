import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/goal.dart';
import '../../data/goal_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return SupabaseGoalRepository(Supabase.instance.client);
});

final activeGoalProvider = FutureProvider<Goal?>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.getActiveGoal();
});
