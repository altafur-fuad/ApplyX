import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String fullName;
  final String headline;
  final String bio;
  final List<String> skills;
  final String location;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.headline,
    required this.bio,
    required this.skills,
    required this.location,
  });

  @override
  List<Object?> get props => [id, fullName, headline, bio, skills, location];
}
