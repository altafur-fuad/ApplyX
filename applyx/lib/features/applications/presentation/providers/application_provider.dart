import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/application.dart';
import '../../data/application_repository.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return MockApplicationRepository();
});

final applicationsProvider = FutureProvider<List<Application>>((ref) {
  final repository = ref.watch(applicationRepositoryProvider);
  return repository.getApplications();
});
