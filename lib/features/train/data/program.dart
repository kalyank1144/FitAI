class Program {
  const Program({required this.id, required this.name, this.description, this.difficulty, this.coverUrl, this.isFeatured = false});
  factory Program.fromMap(Map<String, dynamic> m) => Program(
    id: m['id'].toString(), name: (m['name'] ?? '').toString(), description: m['description']?.toString(), difficulty: m['difficulty']?.toString(), coverUrl: m['cover_url']?.toString(), isFeatured: (m['is_featured'] ?? false) as bool,
  );
  final String id;
  final String name;
  final String? description;
  final String? difficulty;
  final String? coverUrl;
  final bool isFeatured;
}