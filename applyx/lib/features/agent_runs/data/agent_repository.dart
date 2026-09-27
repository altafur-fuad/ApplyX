import '../domain/agent_run.dart';
import '../../../core/network/api_client.dart';

abstract class AgentRepository {
  Future<AgentRun> createAgentRun(String goalId, String mode);
  Future<AgentRun> getAgentRun(String runId);
  Future<List<AgentRunEvent>> getAgentRunEvents(String runId);
  Future<AgentRun> cancelAgentRun(String runId);
}

class ApiAgentRepository implements AgentRepository {
  final ApiClient _apiClient;

  ApiAgentRepository(this._apiClient);

  @override
  Future<AgentRun> createAgentRun(String goalId, String mode) async {
    final response = await _apiClient.post('/agent-runs', body: {
      'goal_id': goalId,
      'mode': mode,
    });
    return AgentRun.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AgentRun> getAgentRun(String runId) async {
    final response = await _apiClient.get('/agent-runs/$runId');
    return AgentRun.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<AgentRunEvent>> getAgentRunEvents(String runId) async {
    final response = await _apiClient.get('/agent-runs/$runId/events');
    final events = (response['events'] as List<dynamic>)
        .map((e) => AgentRunEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    return events;
  }

  @override
  Future<AgentRun> cancelAgentRun(String runId) async {
    final response = await _apiClient.post('/agent-runs/$runId/cancel');
    return AgentRun.fromJson(response as Map<String, dynamic>);
  }
}
