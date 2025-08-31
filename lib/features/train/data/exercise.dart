class Exercise {
  final String id;
  final String name;
  final String? primaryMuscle;
  final String? equipment;
  final String? mediaUrl;

  const Exercise({
    required this.id,
    required this.name,
    this.primaryMuscle,
    this.equipment,
    this.mediaUrl,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'].toString(),
        name: (map['name'] ?? '').toString(),
        primaryMuscle: map['primary_muscle']?.toString(),
        equipment: map['equipment']?.toString(),
        mediaUrl: map['media_url']?.toString(),
      );
}