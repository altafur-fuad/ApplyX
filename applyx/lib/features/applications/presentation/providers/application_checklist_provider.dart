import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application_provider.dart';

final applicationChecklistProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, applicationId) {
  final repository = ref.watch(applicationRepositoryProvider);
  return repository.getChecklist(applicationId);
});
