import '../domain/application.dart';

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
