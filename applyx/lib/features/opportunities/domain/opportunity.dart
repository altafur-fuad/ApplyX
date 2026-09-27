import 'package:equatable/equatable.dart';

class Opportunity extends Equatable {
  final String id;
  final String sourceName;
  final String sourceUrl;
  final String? externalId;
  final String title;
  final String organization;
  final String type;
  final String? location;
  final String? remoteStatus;
  final DateTime? deadline;
  final String? description;
  final List<dynamic> requirementsJson;
  final String? compensationText;
  final DateTime fetchedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Opportunity({
    required this.id,
    required this.sourceName,
    required this.sourceUrl,
    this.externalId,
    required this.title,
    required this.organization,
    required this.type,
    this.location,
    this.remoteStatus,
    this.deadline,
    this.description,
    required this.requirementsJson,
    this.compensationText,
    required this.fetchedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id'] as String,
      sourceName: json['source_name'] as String,
      sourceUrl: json['source_url'] as String,
      externalId: json['external_id'] as String?,
      title: json['title'] as String,
      organization: json['organization'] as String,
      type: json['type'] as String,
      location: json['location'] as String?,
      remoteStatus: json['remote_status'] as String?,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      description: json['description'] as String?,
      requirementsJson: json['requirements_json'] as List<dynamic>? ?? [],
      compensationText: json['compensation_text'] as String?,
      fetchedAt: DateTime.parse(json['fetched_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        sourceName,
        sourceUrl,
        externalId,
        title,
        organization,
        type,
        location,
        remoteStatus,
        deadline,
        description,
        requirementsJson,
        compensationText,
        fetchedAt,
        createdAt,
        updatedAt,
      ];
}

class Evidence extends Equatable {
  final String claim;
  final String? sourceUrl;

  const Evidence({required this.claim, this.sourceUrl});

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      claim: json['claim'] as String,
      sourceUrl: json['source_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [claim, sourceUrl];
}

class OpportunityMatch extends Equatable {
  final String eligibilityStatus;
  final List<String> fitReasons;
  final List<String> missingRequirements;
  final List<Evidence> evidence;

  const OpportunityMatch({
    required this.eligibilityStatus,
    required this.fitReasons,
    required this.missingRequirements,
    required this.evidence,
  });

  factory OpportunityMatch.fromJson(Map<String, dynamic> json) {
    return OpportunityMatch(
      eligibilityStatus: json['eligibility_status'] as String,
      fitReasons: List<String>.from(json['fit_reasons'] ?? []),
      missingRequirements: List<String>.from(json['missing_requirements'] ?? []),
      evidence: (json['evidence'] as List<dynamic>? ?? [])
          .map((e) => Evidence.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [eligibilityStatus, fitReasons, missingRequirements, evidence];
}
