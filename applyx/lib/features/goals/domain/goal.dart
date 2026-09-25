import 'package:equatable/equatable.dart';

class Goal extends Equatable {
  final String id;
  final String title;
  final String rawGoal;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.title,
    required this.rawGoal,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, rawGoal, createdAt];
}
