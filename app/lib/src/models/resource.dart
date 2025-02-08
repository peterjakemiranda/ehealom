class Resource {
  final String uuid;
  final String title;
  final String content;
  final String? imageUrl;
  final String? fileUrl;
  final List<Map<String, dynamic>> categories;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Resource({
    required this.uuid,
    required this.title,
    required this.content,
    this.imageUrl,
    this.fileUrl,
    this.categories = const [],
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      uuid: json['uuid'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['image_path'] ?? json['image_url'],
      fileUrl: json['file_url'],
      categories: List<Map<String, dynamic>>.from(json['categories'] ?? []),
      isPublished: json['is_published'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
} 