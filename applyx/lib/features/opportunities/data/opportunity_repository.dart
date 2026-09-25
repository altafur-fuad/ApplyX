import '../domain/opportunity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class SupabaseOpportunityRepository implements OpportunityRepository {
  final SupabaseClient _supabase;

  SupabaseOpportunityRepository(this._supabase);

  @override
  Future<List<Opportunity>> getOpportunities() async {
    final response = await _supabase
        .from('opportunities')
        .select()
        .order('fetched_at', ascending: false)
        .limit(20);

    return (response as List).map((data) => _mapOpportunity(data)).toList();
  }

  @override
  Future<Opportunity?> getOpportunityById(String id) async {
    final response = await _supabase
        .from('opportunities')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _mapOpportunity(response);
  }

  Opportunity _mapOpportunity(Map<String, dynamic> data) {
    String deadlineStr = '';
    if (data['deadline'] != null) {
      final deadline = DateTime.parse(data['deadline']);
      deadlineStr = '${deadline.day}/${deadline.month}/${deadline.year}';
    }

    return Opportunity(
      id: data['id'],
      title: data['title'],
      organization: data['organization'],
      location: data['location'] ?? 'Unknown',
      deadline: deadlineStr,
      reason: data['description'] ?? '',
      matchLevel: MatchLevel.review, // Default for now
      sourceUrl: data['source_url'] ?? '',
      fetchedAt: DateTime.parse(data['fetched_at']),
    );
  }
}
