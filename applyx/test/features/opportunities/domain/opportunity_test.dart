import 'package:flutter_test/flutter_test.dart';
import 'package:applyx/features/opportunities/domain/opportunity.dart';

void main() {
  group('Opportunity Models', () {
    test('Opportunity.fromJson parses correctly', () {
      final json = {
        'id': 'opp1',
        'source_name': 'linkedin',
        'source_url': 'https://example.com',
        'external_id': 'ext1',
        'title': 'Flutter Developer',
        'organization': 'Tech Co',
        'type': 'full_time',
        'location': 'Remote',
        'remote_status': 'remote',
        'deadline': '2026-10-01T00:00:00Z',
        'description': 'A great job',
        'requirements_json': ['req1', 'req2'],
        'compensation_text': '\$100k',
        'fetched_at': '2026-09-27T10:00:00Z',
        'created_at': '2026-09-27T10:00:00Z',
        'updated_at': '2026-09-27T10:00:00Z',
      };

      final opp = Opportunity.fromJson(json);

      expect(opp.id, 'opp1');
      expect(opp.title, 'Flutter Developer');
      expect(opp.remoteStatus, 'remote');
      expect(opp.deadline, DateTime.parse('2026-10-01T00:00:00Z'));
      expect(opp.requirementsJson.length, 2);
    });

    test('Evidence.fromJson parses correctly', () {
      final json = {
        'claim': 'Remote work allowed',
        'source_url': 'https://example.com',
      };

      final evidence = Evidence.fromJson(json);

      expect(evidence.claim, 'Remote work allowed');
      expect(evidence.sourceUrl, 'https://example.com');
    });

    test('OpportunityMatch.fromJson parses correctly', () {
      final json = {
        'eligibility_status': 'eligible',
        'fit_reasons': ['Great fit'],
        'missing_requirements': ['needs 10 years exp'],
        'evidence': [
          {'claim': 'Good pay', 'source_url': null}
        ]
      };

      final match = OpportunityMatch.fromJson(json);

      expect(match.eligibilityStatus, 'eligible');
      expect(match.fitReasons.first, 'Great fit');
      expect(match.missingRequirements.first, 'needs 10 years exp');
      expect(match.evidence.first.claim, 'Good pay');
    });
  });
}
