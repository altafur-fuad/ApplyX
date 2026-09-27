import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:applyx/core/network/api_client.dart';
import 'package:applyx/core/network/api_exception.dart';
import 'package:applyx/features/goals/domain/goal.dart';
import 'package:applyx/features/goals/data/goal_repository.dart';

void main() {
  group('ApiGoalRepository', () {
    test('getGoals parses list of goals successfully', () async {
      final mockResponse = [
        {
          'id': 'g1',
          'user_id': 'u1',
          'title': 'Test Goal',
          'raw_goal': 'Raw text',
          'structured_constraints_json': {},
          'status': 'active',
          'created_at': '2026-09-27T10:00:00Z',
          'updated_at': '2026-09-27T10:00:00Z',
        }
      ];
      final apiClient = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v1/goals');
          return http.Response(jsonEncode(mockResponse), 200);
        }),
      );
      final repository = ApiGoalRepository(apiClient);

      final goals = await repository.getGoals();
      expect(goals.length, 1);
      expect(goals.first.id, 'g1');
    });

    test('createGoal parses and returns created goal', () async {
      final mockResponse = {
        'id': 'g2',
        'user_id': 'u1',
        'title': 'New Goal',
        'raw_goal': 'Raw new',
        'structured_constraints_json': {},
        'status': 'active',
        'created_at': '2026-09-27T10:00:00Z',
        'updated_at': '2026-09-27T10:00:00Z',
      };
      final apiClient = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v1/goals');
          expect(request.method, 'POST');
          return http.Response(jsonEncode(mockResponse), 201);
        }),
      );
      final repository = ApiGoalRepository(apiClient);

      final request = CreateGoalRequest(title: 'New Goal', rawGoal: 'Raw new');
      final goal = await repository.createGoal(request);
      expect(goal.id, 'g2');
      expect(goal.title, 'New Goal');
    });

    test('createGoal throws ApiException on failure', () async {
      final apiClient = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          return http.Response(jsonEncode({'error': {'code': 'VALIDATION_ERROR', 'message': 'Invalid'}}), 422);
        }),
      );
      final repository = ApiGoalRepository(apiClient);

      final request = CreateGoalRequest(title: '', rawGoal: '');
      
      expect(
        () => repository.createGoal(request),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });
  });
}
