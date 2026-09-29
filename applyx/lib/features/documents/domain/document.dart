class Document {
  final String id;
  final String kind;
  final String title;
  final String content;
  final int version;
  final bool isDraft;
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.kind,
    required this.title,
    required this.content,
    required this.version,
    required this.isDraft,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      kind: json['kind'],
      title: json['title'],
      content: json['content'],
      version: json['version'],
      isDraft: json['is_draft'] ?? true,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
