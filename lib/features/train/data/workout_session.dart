import 'package:equatable/equatable.dart';

class WorkoutSession extends Equatable {
  const WorkoutSession({
    required this.id,
    required this.userId,
    this.programId,
    required this.startedAt,
    this.endedAt,
    this.status = WorkoutStatus.inProgress,
    required this.createdAt,
    this.notes,
    this.totalDuration,
    this.totalVolume,
  });

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      programId: map['program_id']?.toString(),
      startedAt: DateTime.parse(map['started_at'] ?? DateTime.now().toIso8601String()),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at']) : null,
      status: WorkoutStatus.fromString(map['status'] ?? 'in_progress'),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      notes: map['notes']?.toString(),
      totalDuration: map['total_duration'] != null ? Duration(seconds: map['total_duration']) : null,
      totalVolume: map['total_volume']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'program_id': programId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'total_duration': totalDuration?.inSeconds,
      'total_volume': totalVolume,
    };
  }

  final String id;
  final String userId;
  final String? programId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final WorkoutStatus status;
  final DateTime createdAt;
  final String? notes;
  final Duration? totalDuration;
  final double? totalVolume;

  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? programId,
    DateTime? startedAt,
    DateTime? endedAt,
    WorkoutStatus? status,
    DateTime? createdAt,
    String? notes,
    Duration? totalDuration,
    double? totalVolume,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      programId: programId ?? this.programId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      totalDuration: totalDuration ?? this.totalDuration,
      totalVolume: totalVolume ?? this.totalVolume,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        programId,
        startedAt,
        endedAt,
        status,
        createdAt,
        notes,
        totalDuration,
        totalVolume,
      ];
}

enum WorkoutStatus {
  inProgress('in_progress'),
  completed('completed'),
  paused('paused'),
  cancelled('cancelled');

  const WorkoutStatus(this.value);
  final String value;

  static WorkoutStatus fromString(String value) {
    return WorkoutStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => WorkoutStatus.inProgress,
    );
  }
}