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

class ApplicationDocumentVersion {
  final String id;
  final String documentId;
  final String content;
  final int version;
  final DateTime createdAt;

  const ApplicationDocumentVersion({
    required this.id,
    required this.documentId,
    required this.content,
    required this.version,
    required this.createdAt,
  });

  factory ApplicationDocumentVersion.fromJson(Map<String, dynamic> json) {
    return ApplicationDocumentVersion(
      id: json['id'],
      documentId: json['document_id'],
      content: json['content'],
      version: json['version'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
