import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:applyx/core/network/api_client.dart';
import 'package:applyx/features/agent_runs/domain/agent_run.dart';
import 'package:applyx/features/agent_runs/data/agent_repository.dart';

void main() {
  group('ApiAgentRepository', () {
    test('createAgentRun parses correctly', () async {
      final mockResponse = {
        'id': 'run1',
        'goal_id': 'g1',
        'user_id': 'u1',
        'status': 'queued',
      };
      
      final apiClient = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/agent-runs');
          expect(request.method, 'POST');
          return http.Response(jsonEncode(mockResponse), 201);
        }),
      );
      final repository = ApiAgentRepository(apiClient);

      final run = await repository.createAgentRun('g1', 'mode1');
      expect(run.id, 'run1');
      expect(run.status, AgentStatus.queued);
    });

    test('getAgentRunEvents parses list correctly', () async {
      final mockResponse = {
        'events': [
          {
            'id': 'e1',
            'event_type': 'task_started',
            'created_at': '2026-09-27T10:00:00Z'
          }
        ]
      };
      
      final apiClient = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/agent-runs/run1/events');
          return http.Response(jsonEncode(mockResponse), 200);
        }),
      );
      final repository = ApiAgentRepository(apiClient);

      final events = await repository.getAgentRunEvents('run1');
      expect(events.length, 1);
      expect(events.first.id, 'e1');
    });

    test('cancelAgentRun calls cancel endpoint', () async {
      final mockResponse = {
        'id': 'run1',
        'goal_id': 'g1',
        'status': 'cancelled',
      };
      
      final apiClient = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/agent-runs/run1/cancel');
          expect(request.method, 'POST');
          return http.Response(jsonEncode(mockResponse), 200);
        }),
      );
      final repository = ApiAgentRepository(apiClient);

      final run = await repository.cancelAgentRun('run1');
      expect(run.status, AgentStatus.cancelled);
    });
  });
}
