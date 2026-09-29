import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:applyx/core/network/api_client.dart';
import 'package:applyx/features/opportunities/data/opportunity_repository.dart';

void main() {
  group('ApiOpportunityRepository', () {
    final mockOppJson = {
      'id': 'opp1',
      'source_name': 'linkedin',
      'source_url': 'https://example.com',
      'title': 'Flutter Developer',
      'organization': 'Tech Co',
      'type': 'full_time',
      'fetched_at': '2026-09-27T10:00:00Z',
      'created_at': '2026-09-27T10:00:00Z',
      'updated_at': '2026-09-27T10:00:00Z',
    };

    test('getOpportunities parses items and handles query params', () async {
      final apiClient = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/opportunities');
          expect(request.url.queryParameters['limit'], '10');
          expect(request.url.queryParameters['q'], 'flutter');
          return http.Response(jsonEncode({'items': [mockOppJson], 'next_cursor': null}), 200);
        }),
      );
      final repo = ApiOpportunityRepository(apiClient);

      final opps = await repo.getOpportunities(limit: 10, q: 'flutter');
      expect(opps.length, 1);
      expect(opps.first.id, 'opp1');
    });

    test('getOpportunity returns opportunity', () async {
      final apiClient = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/opportunities/opp1');
          return http.Response(jsonEncode(mockOppJson), 200);
        }),
      );
      final repo = ApiOpportunityRepository(apiClient);

      final opp = await repo.getOpportunity('opp1');
      expect(opp.id, 'opp1');
    });

    test('getOpportunityMatch returns match', () async {
      final apiClient = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/opportunities/opp1/match');
          return http.Response(jsonEncode({
            'eligibility_status': 'eligible',
            'fit_reasons': ['Great fit'],
            'missing_requirements': [],
            'evidence': []
          }), 200);
        }),
      );
      final repo = ApiOpportunityRepository(apiClient);

      final match = await repo.getOpportunityMatch('opp1');
      expect(match.eligibilityStatus, 'eligible');
    });

    test('saveOpportunity calls post endpoint', () async {
      final apiClient = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/opportunities/opp1/save');
          expect(request.method, 'POST');
          return http.Response('{}', 200);
        }),
      );
      final repo = ApiOpportunityRepository(apiClient);

      await repo.saveOpportunity('opp1');
    });
  });
}
