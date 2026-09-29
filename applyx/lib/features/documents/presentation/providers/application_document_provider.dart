import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/application_document.dart';
import '../../data/application_document_repository.dart';
import '../../../../core/network/api_client.dart';

final applicationDocumentRepositoryProvider = Provider<ApplicationDocumentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiApplicationDocumentRepository(apiClient);
});

final applicationDocumentsProvider = FutureProvider.family<List<ApplicationDocument>, String>((ref, applicationId) {
  final repository = ref.watch(applicationDocumentRepositoryProvider);
  return repository.getApplicationDocuments(applicationId);
});
