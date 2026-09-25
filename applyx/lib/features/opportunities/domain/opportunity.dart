import 'package:equatable/equatable.dart';

enum MatchLevel { strong, review, unknown }

class Opportunity extends Equatable {
  final String id;
  final String title;
  final String organization;
  final String location;
  final String? deadline;
  final String reason;
  final MatchLevel matchLevel;
  final String sourceUrl;
  final DateTime fetchedAt;

  const Opportunity({
    required this.id,
    required this.title,
    required this.organization,
    required this.location,
    this.deadline,
    required this.reason,
    required this.matchLevel,
    required this.sourceUrl,
    required this.fetchedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    organization,
    location,
    deadline,
    reason,
    matchLevel,
    sourceUrl,
    fetchedAt,
  ];
}
