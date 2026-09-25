import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile.dart';
import '../../data/profile_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(Supabase.instance.client);
});

final profileProvider = FutureProvider<UserProfile>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile();
});
