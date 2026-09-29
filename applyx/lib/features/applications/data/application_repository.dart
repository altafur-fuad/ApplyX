import '../domain/application.dart';
import '../../../../core/network/api_client.dart';

abstract class ApplicationRepository {
  Future<List<Application>> getApplications();
  Future<Application?> getApplicationById(String id);
  Future<Application?> createApplication(String opportunityId, String status);
  Future<List<Map<String, dynamic>>> getChecklist(String applicationId);
}

class ApiApplicationRepository implements ApplicationRepository {
  final ApiClient _apiClient;

  ApiApplicationRepository(this._apiClient);

  @override
  Future<List<Application>> getApplications() async {
    try {
      final response = await _apiClient.get('/applications');
      final data = response as List;
      
      return data.map((json) {
        return _mapJsonToApplication(json);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Application?> getApplicationById(String id) async {
    try {
      final response = await _apiClient.get('/applications/$id');
      return _mapJsonToApplication(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Application?> createApplication(String opportunityId, String status) async {
    try {
      final response = await _apiClient.post(
        '/applications',
        body: {
          'opportunity_id': opportunityId,
          'status': status,
        },
      );
      return _mapJsonToApplication(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChecklist(String applicationId) async {
    try {
      final response = await _apiClient.get('/applications/$applicationId/checklist');
      final data = response['checklist'] as List;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Application _mapJsonToApplication(Map<String, dynamic> json) {
    final nextActionStr = json['next_action_at'] as String?;
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
          (json['status'] as String).toLowerCase(),
      orElse: () => ApplicationStatus.saved,
    );

    return Application(
      id: json['id'],
      opportunityId: json['opportunity_id'],
      status: status,
      title: json['opportunity_title'] ?? 'Unknown Title',
      organization: json['opportunity_organization'] ?? 'Unknown Org',
      deadline: deadlineStr,
      deadlineUrgent: isUrgent,
    );
  }
}
