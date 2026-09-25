import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/application.dart';
import '../../data/application_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return SupabaseApplicationRepository(Supabase.instance.client);
});

final applicationsProvider = FutureProvider<List<Application>>((ref) {
  final repository = ref.watch(applicationRepositoryProvider);
  return repository.getApplications();
});
