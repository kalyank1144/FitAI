import 'package:equatable/equatable.dart';

class WorkoutSet extends Equatable {
  const WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.position,
    this.reps,
    this.weightKg,
    this.rpe,
    this.notes,
    this.restTime,
    this.isCompleted = false,
    this.targetReps,
    this.targetWeight,
    this.completedAt,
  });

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id']?.toString() ?? '',
      sessionId: map['session_id']?.toString() ?? '',
      exerciseId: map['exercise_id']?.toString() ?? '',
      position: map['position']?.toInt() ?? 0,
      reps: map['reps']?.toInt(),
      weightKg: map['weight_kg']?.toDouble(),
      rpe: map['rpe']?.toDouble(),
      notes: map['notes']?.toString(),
      restTime: map['rest_time'] != null ? Duration(seconds: map['rest_time']) : null,
      isCompleted: map['is_completed'] ?? false,
      targetReps: map['target_reps']?.toInt(),
      targetWeight: map['target_weight']?.toDouble(),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'position': position,
      'reps': reps,
      'weight_kg': weightKg,
      'rpe': rpe,
      'notes': notes,
      'rest_time': restTime?.inSeconds,
      'is_completed': isCompleted,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  final String id;
  final String sessionId;
  final String exerciseId;
  final int position;
  final int? reps;
  final double? weightKg;
  final double? rpe;
  final String? notes;
  final Duration? restTime;
  final bool isCompleted;
  final int? targetReps;
  final double? targetWeight;
  final DateTime? completedAt;

  WorkoutSet copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    int? position,
    int? reps,
    double? weightKg,
    double? rpe,
    String? notes,
    Duration? restTime,
    bool? isCompleted,
    int? targetReps,
    double? targetWeight,
    DateTime? completedAt,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
      restTime: restTime ?? this.restTime,
      isCompleted: isCompleted ?? this.isCompleted,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Calculate volume (weight * reps)
  double get volume => (weightKg ?? 0) * (reps ?? 0);

  // Check if set meets target
  bool get meetsTarget {
    if (targetReps != null && reps != null && reps! < targetReps!) {
      return false;
    }
    if (targetWeight != null && weightKg != null && weightKg! < targetWeight!) {
      return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        exerciseId,
        position,
        reps,
        weightKg,
        rpe,
        notes,
        restTime,
        isCompleted,
        targetReps,
        targetWeight,
        completedAt,
      ];
}