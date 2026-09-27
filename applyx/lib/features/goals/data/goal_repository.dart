import '../domain/goal.dart';
import '../../../core/network/api_client.dart';

abstract class GoalRepository {
  Future<List<Goal>> getGoals();
  Future<Goal?> getActiveGoal();
  Future<Goal> createGoal(CreateGoalRequest request);
  Future<Goal> getGoal(String id);
  Future<Goal> updateGoal(String id, UpdateGoalRequest request);
}

class ApiGoalRepository implements GoalRepository {
  final ApiClient _apiClient;

  ApiGoalRepository(this._apiClient);

  @override
  Future<List<Goal>> getGoals() async {
    final response = await _apiClient.get('/goals');
    if (response is List) {
      return response.map((json) => Goal.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<Goal?> getActiveGoal() async {
    final goals = await getGoals();
    try {
      return goals.firstWhere((g) => g.status == 'active');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Goal> createGoal(CreateGoalRequest request) async {
    final response = await _apiClient.post('/goals', body: request.toJson());
    return Goal.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Goal> getGoal(String id) async {
    final response = await _apiClient.get('/goals/$id');
    return Goal.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Goal> updateGoal(String id, UpdateGoalRequest request) async {
    final response = await _apiClient.patch('/goals/$id', body: request.toJson());
    return Goal.fromJson(response as Map<String, dynamic>);
  }
}
