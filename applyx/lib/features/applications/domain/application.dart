import 'package:equatable/equatable.dart';

enum ApplicationStatus {
  saved,
  preparing,
  readyForReview,
  submitted,
  underReview,
  interview,
  rejected,
  offer,
  withdrawn,
}

class Application extends Equatable {
  final String id;
  final String opportunityId;
  final ApplicationStatus status;
  final String title;
  final String organization;
  final String deadline;
  final bool deadlineUrgent;

  const Application({
    required this.id,
    required this.opportunityId,
    required this.status,
    required this.title,
    required this.organization,
    required this.deadline,
    required this.deadlineUrgent,
  });

  @override
  List<Object?> get props => [
        id,
        opportunityId,
        status,
        title,
        organization,
        deadline,
        deadlineUrgent,
      ];
}
