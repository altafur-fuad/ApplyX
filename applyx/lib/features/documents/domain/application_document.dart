class ApplicationDocument {
  final String id;
  final String? applicationId;
  final String kind;
  final String title;
  final String content;
  final int version;
  final bool isDraft;
  final DateTime updatedAt;

  const ApplicationDocument({
    required this.id,
    this.applicationId,
    required this.kind,
    required this.title,
    required this.content,
    required this.version,
    required this.isDraft,
    required this.updatedAt,
  });

  factory ApplicationDocument.fromJson(Map<String, dynamic> json) {
    return ApplicationDocument(
      id: json['id'],
      applicationId: json['application_id'],
      kind: json['kind'],
      title: json['title'],
      content: json['content'],
      version: json['version'],
      isDraft: json['is_draft'] ?? true,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
