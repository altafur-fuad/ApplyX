import '../domain/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile();
  Future<void> updateProfile(UserProfile profile);
}

class MockProfileRepository implements ProfileRepository {
  final UserProfile _profile = const UserProfile(
    id: 'u1',
    fullName: 'Altafur Rahman',
    headline: 'CSE Student | Flutter | Python | ML',
    bio:
        'Passionate about building mobile applications and exploring agentic AI.',
    skills: ['Flutter', 'Dart', 'Python', 'Machine Learning'],
    location: 'Dhaka, Bangladesh',
  );

  @override
  Future<UserProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _profile;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    // Mock update
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _supabase;

  SupabaseProfileRepository(this._supabase);

  @override
  Future<UserProfile> getProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .single();

    return UserProfile(
      id: data['id'],
      fullName: data['full_name'] ?? 'Unknown',
      headline: data['headline'] ?? '',
      bio: data['bio'] ?? '',
      skills: List<String>.from(data['skills_json'] ?? []),
      location: data['location'] ?? '',
    );
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('profiles')
        .update({
          'full_name': profile.fullName,
          'headline': profile.headline,
          'bio': profile.bio,
          'skills_json': profile.skills,
          'location': profile.location,
        })
        .eq('user_id', userId);
  }
}
