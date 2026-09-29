import '../domain/application_document.dart';
import '../../../../core/network/api_client.dart';

abstract class ApplicationDocumentRepository {
  Future<List<ApplicationDocument>> getApplicationDocuments(String applicationId);
  Future<ApplicationDocument?> generateDocument(String applicationId, String kind, String instruction);
  Future<ApplicationDocument?> updateDocument(String documentId, String content);
}

class ApiApplicationDocumentRepository implements ApplicationDocumentRepository {
  final ApiClient _apiClient;

  ApiApplicationDocumentRepository(this._apiClient);

  @override
  Future<List<ApplicationDocument>> getApplicationDocuments(String applicationId) async {
    try {
      final response = await _apiClient.get('/documents/application/$applicationId');
      final data = response as List;
      return data.map((json) => ApplicationDocument.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ApplicationDocument?> generateDocument(String applicationId, String kind, String instruction) async {
    try {
      final response = await _apiClient.post(
        '/documents/draft',
        body: {
          'application_id': applicationId,
          'kind': kind,
          'instruction': instruction,
        },
      );
      return ApplicationDocument.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ApplicationDocument?> updateDocument(String documentId, String content) async {
    try {
      final response = await _apiClient.patch(
        '/documents/$documentId',
        body: {
          'content': content,
        },
      );
      return ApplicationDocument.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
