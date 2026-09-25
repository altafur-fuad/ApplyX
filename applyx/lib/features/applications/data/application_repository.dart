import '../domain/application.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ApplicationRepository {
  Future<List<Application>> getApplications();
  Future<Application?> getApplicationById(String id);
}

class MockApplicationRepository implements ApplicationRepository {
  final List<Application> _applications = [
    const Application(
      id: 'a1',
      opportunityId: 'o1',
      status: ApplicationStatus.readyForReview,
      title: 'Flutter Developer Intern',
      organization: 'TechCorp Inc.',
      deadline: 'Deadline in 3 days',
      deadlineUrgent: true,
    ),
    const Application(
      id: 'a2',
      opportunityId: 'o2',
      status: ApplicationStatus.preparing,
      title: 'Mobile App Engineering Intern',
      organization: 'StartupAI',
      deadline: 'Deadline in 12 days',
      deadlineUrgent: false,
    ),
    const Application(
      id: 'a3',
      opportunityId: 'o3',
      status: ApplicationStatus.submitted,
      title: 'Mobile App Research Assistant',
      organization: 'University of Dhaka',
      deadline: 'Follow-up next week',
      deadlineUrgent: false,
    ),
    const Application(
      id: 'a4',
      opportunityId: 'o4',
      status: ApplicationStatus.rejected,
      title: 'Junior Android Developer',
      organization: 'LocalTech BD',
      deadline: '',
      deadlineUrgent: false,
    ),
  ];

  @override
  Future<List<Application>> getApplications() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _applications;
  }

  @override
  Future<Application?> getApplicationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _applications.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

class SupabaseApplicationRepository implements ApplicationRepository {
  final SupabaseClient _supabase;

  SupabaseApplicationRepository(this._supabase);

  @override
  Future<List<Application>> getApplications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // The applications table joins with opportunities. We need opportunity details.
    final response = await _supabase
        .from('applications')
        .select('''
          id,
          status,
          notes,
          next_action_at,
          opportunities!inner(id, title, organization)
        ''')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return (response as List).map((data) {
      final opp = data['opportunities'];

      final nextActionStr = data['next_action_at'] as String?;
      bool isUrgent = false;
      String deadlineStr = '';
      if (nextActionStr != null) {
        final nextAction = DateTime.parse(nextActionStr);
        final diff = nextAction.difference(DateTime.now());
        if (diff.inDays < 3 && diff.inDays >= 0) isUrgent = true;

        if (diff.inDays < 0) {
          deadlineStr = 'Overdue';
        } else if (diff.inDays == 0) {
          deadlineStr = 'Today';
        } else {
          deadlineStr = 'In ${diff.inDays} days';
        }
      }

      ApplicationStatus status = ApplicationStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            (data['status'] as String).toLowerCase(),
        orElse: () => ApplicationStatus.readyForReview,
      );

      return Application(
        id: data['id'],
        opportunityId: opp['id'],
        status: status,
        title: opp['title'],
        organization: opp['organization'],
        deadline: deadlineStr,
        deadlineUrgent: isUrgent,
      );
    }).toList();
  }

  @override
  Future<Application?> getApplicationById(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('applications')
        .select('''
          id,
          status,
          notes,
          next_action_at,
          opportunities!inner(id, title, organization)
        ''')
        .eq('user_id', userId)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    final opp = response['opportunities'];

    final nextActionStr = response['next_action_at'] as String?;
    bool isUrgent = false;
    String deadlineStr = '';
    if (nextActionStr != null) {
      final nextAction = DateTime.parse(nextActionStr);
      final diff = nextAction.difference(DateTime.now());
      if (diff.inDays < 3 && diff.inDays >= 0) isUrgent = true;

      if (diff.inDays < 0) {
        deadlineStr = 'Overdue';
      } else if (diff.inDays == 0) {
        deadlineStr = 'Today';
      } else {
        deadlineStr = 'In ${diff.inDays} days';
      }
    }

    ApplicationStatus status = ApplicationStatus.values.firstWhere(
      (e) =>
          e.toString().split('.').last.toLowerCase() ==
          (response['status'] as String).toLowerCase(),
      orElse: () => ApplicationStatus.readyForReview,
    );

    return Application(
      id: response['id'],
      opportunityId: opp['id'],
      status: status,
      title: opp['title'],
      organization: opp['organization'],
      deadline: deadlineStr,
      deadlineUrgent: isUrgent,
    );
  }
}
