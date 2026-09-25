import '../domain/opportunity.dart';

abstract class OpportunityRepository {
  Future<List<Opportunity>> getOpportunities();
  Future<Opportunity?> getOpportunityById(String id);
}

class MockOpportunityRepository implements OpportunityRepository {
  final List<Opportunity> _opportunities = [
    Opportunity(
      id: 'o1',
      title: 'Flutter Developer Intern',
      organization: 'TechCorp Inc.',
      location: 'Remote',
      deadline: 'Oct 15, 2026',
      reason: 'Strong Flutter skills match. Remote position.',
      matchLevel: MatchLevel.strong,
      sourceUrl: 'https://example.com/job1',
      fetchedAt: DateTime.now(),
    ),
    Opportunity(
      id: 'o2',
      title: 'Mobile App Engineering Intern',
      organization: 'StartupAI',
      location: 'Remote',
      deadline: 'Oct 20, 2026',
      reason: 'Dart/Flutter listed. Paid internship.',
      matchLevel: MatchLevel.strong,
      sourceUrl: 'https://example.com/job2',
      fetchedAt: DateTime.now(),
    ),
    Opportunity(
      id: 'o3',
      title: 'Mobile App Research Assistant',
      organization: 'University of Dhaka',
      location: 'Hybrid — Dhaka',
      deadline: 'Nov 1, 2026',
      reason: 'Relevant skills but hybrid preference unclear.',
      matchLevel: MatchLevel.review,
      sourceUrl: 'https://example.com/job3',
      fetchedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<Opportunity>> getOpportunities() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _opportunities;
  }

  @override
  Future<Opportunity?> getOpportunityById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _opportunities.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
