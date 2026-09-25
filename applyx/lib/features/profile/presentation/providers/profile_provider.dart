import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile.dart';
import '../../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return MockProfileRepository();
});

final profileProvider = FutureProvider<UserProfile>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile();
});
