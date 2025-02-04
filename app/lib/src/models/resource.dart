class Resource {
  final String id;
  final String uuid;
  final String title;
  final String content;
  final String type;
  final String category;
  final String? fileUrl;
  final bool isPublished;
  final Map<String, dynamic>? creator;
  final DateTime createdAt;
  final DateTime updatedAt;

  Resource({
    required this.id,
    required this.uuid,
    required this.title,
    required this.content,
    required this.type,
    required this.category,
    this.fileUrl,
    required this.isPublished,
    this.creator,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'].toString(),
      uuid: json['uuid'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      category: json['category'],
      fileUrl: json['file_url'],
      isPublished: json['is_published'] ?? false,
      creator: json['creator'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
} 