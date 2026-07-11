class KnowledgeBase {
  final String id;
  final String userId;
  final String name;
  final String text;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  KnowledgeBase({
    required this.id,
    required this.userId,
    required this.name,
    required this.text,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  KnowledgeBase copyWith({
    String? id,
    String? userId,
    String? name,
    String? text,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return KnowledgeBase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      text: text ?? this.text,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    return KnowledgeBase(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      text: json['text'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'text': text,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
