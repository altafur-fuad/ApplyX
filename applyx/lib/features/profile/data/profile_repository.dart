import '../domain/profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile();
}

class MockProfileRepository implements ProfileRepository {
  final UserProfile _profile = const UserProfile(
    id: 'u1',
    fullName: 'Altafur Rahman',
    headline: 'CSE Student | Flutter | Python | ML',
    bio: 'Passionate about building mobile applications and exploring agentic AI.',
    skills: ['Flutter', 'Dart', 'Python', 'Machine Learning'],
    location: 'Dhaka, Bangladesh',
  );

  @override
  Future<UserProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _profile;
  }
}
