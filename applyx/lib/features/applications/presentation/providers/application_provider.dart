import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/application.dart';
import '../../data/application_repository.dart';
import '../../../../core/network/api_client.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiApplicationRepository(apiClient);
});

final applicationsProvider = FutureProvider<List<Application>>((ref) {
  final repository = ref.watch(applicationRepositoryProvider);
  return repository.getApplications();
});
