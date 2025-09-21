class Program {
  final String id;
  final String name;
  final String description;
  final String difficulty;
  final String? coverUrl;
  final bool isFeatured;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Program({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    this.coverUrl,
    required this.isFeatured,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      difficulty: map['difficulty'],
      coverUrl: map['cover_url'],
      isFeatured: map['is_featured'] ?? false,
      createdBy: map['created_by'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'cover_url': coverUrl,
      'is_featured': isFeatured,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Program copyWith({
    String? id,
    String? name,
    String? description,
    String? difficulty,
    String? coverUrl,
    bool? isFeatured,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      coverUrl: coverUrl ?? this.coverUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Program && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Program(id: $id, name: $name, difficulty: $difficulty, isFeatured: $isFeatured)';
  }
}
