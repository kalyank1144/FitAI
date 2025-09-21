import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'workout_session.dart';
import 'workout_set.dart';
import '../analytics_screen.dart';
import 'exercise.dart';
import 'program.dart';

class WorkoutRepositoryException implements Exception {
  const WorkoutRepositoryException(this.message, [this.details]);
  final String message;
  final String? details;

  @override
  String toString() => details != null 
      ? 'WorkoutRepositoryException: $message - $details'
      : 'WorkoutRepositoryException: $message';
}

class WorkoutRepository {
  WorkoutRepository(this._supabase);
  final SupabaseClient _supabase;
  WorkoutSession? _currentSession;

  String? _getCurrentUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const WorkoutRepositoryException('User not authenticated');
    }
    return user.id;
  }

  Future<T> _handleDatabaseOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PostgrestException catch (e) {
      throw WorkoutRepositoryException('Database error: ${e.message}');
    } on AuthException catch (e) {
      throw WorkoutRepositoryException('Authentication error: ${e.message}');
    } catch (e) {
      throw WorkoutRepositoryException('Unexpected error: $e');
    }
  }

  // Workout Session Operations
  Future<WorkoutSession> createWorkoutSession({
    String? programId,
    String? notes,
  }) async {
    return _handleDatabaseOperation(() async {
      final userId = _getCurrentUserId();
      final now = DateTime.now();
      
      final response = await _supabase
          .from('workout_sessions')
          .insert({
            'user_id': userId,
            'program_id': programId,
            'started_at': now.toIso8601String(),
            'status': 'in_progress',
            'notes': notes,
          })
          .select()
          .single();

      return WorkoutSession.fromMap(response);
    });
  }

  Future<WorkoutSession> updateWorkoutSession(WorkoutSession session) async {
    return _handleDatabaseOperation(() async {
      final response = await _supabase
          .from('workout_sessions')
          .update(session.toMap())
          .eq('id', session.id)
          .select()
          .single();

      return WorkoutSession.fromMap(response);
    });
  }

  Future<WorkoutSession> completeWorkoutSession(String sessionId) async {
    return _handleDatabaseOperation(() async {
      final now = DateTime.now();
      
      // Get session start time to calculate duration
      final sessionData = await _supabase
          .from('workout_sessions')
          .select('started_at')
          .eq('id', sessionId)
          .single();
      
      final startTime = DateTime.parse(sessionData['started_at']);
      final duration = now.difference(startTime);
      
      // Calculate total volume from sets
      final setsData = await _supabase
          .from('workout_sets')
          .select('weight_kg, reps')
          .eq('session_id', sessionId);
      
      double totalVolume = 0;
      for (final set in setsData) {
        final weight = set['weight_kg']?.toDouble() ?? 0;
        final reps = set['reps']?.toInt() ?? 0;
        totalVolume += weight * reps;
      }
      
      final response = await _supabase
          .from('workout_sessions')
          .update({
            'ended_at': now.toIso8601String(),
            'status': 'completed',
            'total_duration': duration.inSeconds,
            'total_volume': totalVolume,
          })
          .eq('id', sessionId)
          .select()
          .single();

      return WorkoutSession.fromMap(response);
    });
  }

  Future<WorkoutSession> pauseWorkout(String sessionId) async {
    return _handleDatabaseOperation(() async {
      final response = await _supabase
          .from('workout_sessions')
          .update({
            'status': 'paused',
          })
          .eq('id', sessionId)
          .select()
          .single();

      return WorkoutSession.fromMap(response);
    });
  }

  Future<void> finishWorkout() async {
    try {
      if (_currentSession == null) {
        throw WorkoutRepositoryException(
          'No active session',
          'No workout session to finish',
        );
      }

      await _supabase
          .from('workout_sessions')
          .update({
            'status': 'completed',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentSession!.id);

      _currentSession = null;
    } on PostgrestException catch (e) {
      throw WorkoutRepositoryException(
        'Database error',
        'Failed to finish workout: ${e.message}',
      );
    } catch (e) {
      if (e is WorkoutRepositoryException) rethrow;
      throw WorkoutRepositoryException(
        'Unexpected error',
        'Failed to finish workout: $e',
      );
    }
  }

  Future<void> deleteWorkoutSession(String sessionId) async {
    return _handleDatabaseOperation(() async {
      await _supabase
          .from('workout_sessions')
          .delete()
          .eq('id', sessionId);
    });
  }

  Stream<List<WorkoutSession>> watchWorkoutSessions({
    int limit = 50,
    WorkoutStatus? status,
  }) {
    final userId = _getCurrentUserId();
    
    var query = _supabase
        .from('workout_sessions')
        .stream(primaryKey: ['id'])
        .order('started_at', ascending: false);
    
    // Note: Filtering will be done client-side for stream
    return query.map((data) {
      var sessions = data.map((item) => WorkoutSession.fromMap(item)).toList();
      
      // Filter by user_id
      sessions = sessions.where((session) => session.userId == userId).toList();
      
      // Filter by status if specified
      if (status != null) {
        sessions = sessions.where((session) => session.status == status).toList();
      }
      
      // Apply limit
      if (sessions.length > limit) {
        sessions = sessions.take(limit).toList();
      }
      
      return sessions;
    });
  }

  Future<WorkoutSession?> getCurrentWorkoutSession() async {
    return _handleDatabaseOperation(() async {
      final userId = _getCurrentUserId();
      
      final response = await _supabase
          .from('workout_sessions')
          .select()
          .eq('user_id', userId!)
          .eq('status', 'in_progress')
          .order('started_at', ascending: false)
          .limit(1);
      
      if (response.isEmpty) return null;
      return WorkoutSession.fromMap(response.first);
    });
  }

  Future<WorkoutSession?> getWorkoutSession(String sessionId) async {
    return _handleDatabaseOperation(() async {
      final response = await _supabase
          .from('workout_sessions')
          .select()
          .eq('id', sessionId)
          .maybeSingle();
      
      return response != null ? WorkoutSession.fromMap(response) : null;
    });
  }

  // Workout Set Operations
  Future<WorkoutSet> createWorkoutSet({
    required String sessionId,
    required String exerciseId,
    required int position,
    int? targetReps,
    double? targetWeight,
  }) async {
    return _handleDatabaseOperation(() async {
      final response = await _supabase
          .from('workout_sets')
          .insert({
            'session_id': sessionId,
            'exercise_id': exerciseId,
            'position': position,
            'target_reps': targetReps,
            'target_weight': targetWeight,
            'is_completed': false,
          })
          .select()
          .single();

      return WorkoutSet.fromMap(response);
    });
  }

  Future<WorkoutSet> updateWorkoutSet(WorkoutSet set) async {
    return _handleDatabaseOperation(() async {
      final response = await _supabase
          .from('workout_sets')
          .update(set.toMap())
          .eq('id', set.id)
          .select()
          .single();

      return WorkoutSet.fromMap(response);
    });
  }

  Future<WorkoutSet> completeWorkoutSet({
    required String setId,
    required int reps,
    required double weightKg,
    double? rpe,
    String? notes,
  }) async {
    return _handleDatabaseOperation(() async {
      if (reps <= 0) {
        throw WorkoutRepositoryException(
          'Invalid input',
          'Reps must be greater than 0',
        );
      }

      if (weightKg < 0) {
        throw WorkoutRepositoryException(
          'Invalid input',
          'Weight cannot be negative',
        );
      }

      final now = DateTime.now();
      
      final response = await _supabase
          .from('workout_sets')
          .update({
            'reps': reps,
            'weight_kg': weightKg,
            'rpe': rpe,
            'notes': notes,
            'is_completed': true,
            'completed_at': now.toIso8601String(),
          })
          .eq('id', setId)
          .select()
          .single();

      return WorkoutSet.fromMap(response);
    });
  }

  Future<void> deleteWorkoutSet(String setId) async {
    return _handleDatabaseOperation(() async {
      await _supabase
          .from('workout_sets')
          .delete()
          .eq('id', setId);
    });
  }

  Stream<List<WorkoutSet>> watchWorkoutSets(String sessionId) {
    var query = _supabase
        .from('workout_sets')
        .stream(primaryKey: ['id'])
        .order('position');
    
    // Note: Filtering will be done client-side for stream
    return query.map((data) {
      var sets = data.map((item) => WorkoutSet.fromMap(item)).toList();
      
      // Filter by session_id
      sets = sets.where((set) => set.sessionId == sessionId).toList();
      
      return sets;
    });
  }

  Future<List<WorkoutSet>> getWorkoutSets(String sessionId) async {
    try {
      final data = await _supabase
          .from('workout_sets')
          .select()
          .eq('session_id', sessionId)
          .order('position');
      
      return data.map((item) => WorkoutSet.fromMap(item)).toList();
    } catch (e) {
      throw WorkoutRepositoryException('Failed to get workout sets: $e');
    }
  }

  // Analytics and History
  Future<List<WorkoutSession>> getWorkoutHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('workout_sessions')
          .select('*, workout_sets(*)')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('started_at', ascending: false);

      final data = await query;
      var sessions = data.map((json) => WorkoutSession.fromMap(json)).toList();
      
      // Filter by date range if specified
      if (startDate != null) {
        sessions = sessions.where((session) => 
          session.startedAt.isAfter(startDate) || 
          session.startedAt.isAtSameMomentAs(startDate)
        ).toList();
      }
      if (endDate != null) {
        sessions = sessions.where((session) => 
          session.startedAt.isBefore(endDate) || 
          session.startedAt.isAtSameMomentAs(endDate)
        ).toList();
      }
      
      // Apply limit if specified
      if (limit != null && sessions.length > limit) {
        sessions = sessions.take(limit).toList();
      }
      
      return sessions;
    } catch (e) {
      throw WorkoutRepositoryException('Failed to get workout history: $e');
    }
  }

  Future<Map<String, dynamic>> getWorkoutStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final sessions = await getWorkoutHistory(
        startDate: startDate,
        endDate: endDate,
      );

      final totalWorkouts = sessions.length;
      final totalDuration = sessions.fold<Duration>(
        Duration.zero,
        (sum, session) => sum + (session.totalDuration ?? Duration.zero),
      );

      double totalVolume = 0;
      int totalSets = 0;
      int totalReps = 0;

      for (final session in sessions) {
        // Get sets for this session
        final sets = await getWorkoutSets(session.id);
        for (final set in sets) {
          totalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
          totalSets++;
          totalReps += set.reps ?? 0;
        }
      }

      return {
        'totalWorkouts': totalWorkouts,
        'totalDuration': totalDuration,
        'totalVolume': totalVolume,
        'totalSets': totalSets,
        'totalReps': totalReps,
        'averageWorkoutDuration': totalWorkouts > 0
            ? Duration(milliseconds: totalDuration.inMilliseconds ~/ totalWorkouts)
            : Duration.zero,
        'averageVolumePerWorkout': totalWorkouts > 0 ? totalVolume / totalWorkouts : 0,
      };
    } catch (e) {
      throw WorkoutRepositoryException('Failed to get workout stats: $e');
    }
  }

  // Advanced Analytics
  Future<AnalyticsData> getAnalyticsData({TimeRange? timeRange}) async {
    try {
      final range = timeRange ?? TimeRange.month;
      final startDate = DateTime.now().subtract(Duration(days: range.days));
      
      final sessions = await getWorkoutHistory(
        startDate: startDate,
        endDate: DateTime.now(),
      );

      // Calculate basic metrics
      final totalWorkouts = sessions.length;
      double totalVolume = 0;
      Duration totalTime = Duration.zero;
      int totalSets = 0;
      int totalReps = 0;
      double totalRPE = 0;
      int rpeCount = 0;

      final exerciseFrequency = <String, int>{};
      final muscleGroupVolume = <String, double>{};
      final volumeHistory = <VolumeDataPoint>[];
      final workoutFrequency = <WorkoutFrequencyPoint>[];
      final strengthProgress = <String, double>{};

      // Process sessions
      for (final session in sessions) {
        totalTime += session.totalDuration ?? Duration.zero;
        
        double sessionVolume = 0;
        // Get sets for this session
        final sets = await getWorkoutSets(session.id);
        for (final set in sets) {
          final volume = (set.weightKg ?? 0) * (set.reps ?? 0);
          totalVolume += volume;
          sessionVolume += volume;
          totalSets++;
          totalReps += set.reps ?? 0;
          
          if (set.rpe != null) {
            totalRPE += set.rpe!;
            rpeCount++;
          }

          // Exercise frequency (using exercise ID)
          final exerciseId = set.exerciseId;
          exerciseFrequency[exerciseId] = (exerciseFrequency[exerciseId] ?? 0) + 1;

          // Muscle group volume (simplified mapping using exercise ID)
          final muscleGroup = _getMuscleGroupForExercise(exerciseId);
          muscleGroupVolume[muscleGroup] = (muscleGroupVolume[muscleGroup] ?? 0) + volume;
        }

        // Volume history
        if (session.startedAt != null) {
          volumeHistory.add(VolumeDataPoint(
            date: session.startedAt!,
            volume: sessionVolume,
          ));
        }
      }

      // Generate workout frequency data
      final now = DateTime.now();
      for (int i = range.days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final workoutsOnDate = sessions.where((s) => 
          s.startedAt != null &&
          s.startedAt!.year == date.year &&
          s.startedAt!.month == date.month &&
          s.startedAt!.day == date.day
        ).length;
        
        workoutFrequency.add(WorkoutFrequencyPoint(
          date: date,
          count: workoutsOnDate,
        ));
      }

      // Calculate strength progress (simplified)
      final uniqueExercises = exerciseFrequency.keys.take(5);
      for (final exercise in uniqueExercises) {
        // Collect all sets for this exercise from all sessions
        final List<WorkoutSet> exerciseSets = [];
        for (final session in sessions) {
          final sets = await getWorkoutSets(session.id);
          exerciseSets.addAll(sets.where((set) => set.exerciseId == exercise));
        }
        
        if (exerciseSets.length >= 2) {
          exerciseSets.sort((a, b) => (a.completedAt ?? DateTime.now())
              .compareTo(b.completedAt ?? DateTime.now()));
          
          final firstWeight = exerciseSets.first.weightKg ?? 0;
          final lastWeight = exerciseSets.last.weightKg ?? 0;
          
          if (firstWeight > 0) {
            final progress = ((lastWeight - firstWeight) / firstWeight) * 100;
            strengthProgress[exercise] = progress;
          }
        }
      }

      final averageRPE = rpeCount > 0 ? totalRPE / rpeCount : 0.0;

      return AnalyticsData(
        totalWorkouts: totalWorkouts,
        totalVolume: totalVolume,
        totalTime: totalTime,
        totalSets: totalSets,
        totalReps: totalReps,
        averageRPE: averageRPE,
        recentWorkouts: sessions.take(10).toList(),
        exerciseFrequency: Map.fromEntries(
          exerciseFrequency.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))
        ),
        muscleGroupVolume: muscleGroupVolume,
        volumeHistory: volumeHistory..sort((a, b) => a.date.compareTo(b.date)),
        workoutFrequency: workoutFrequency,
        strengthProgress: strengthProgress,
      );
    } catch (e) {
      throw WorkoutRepositoryException('Failed to get analytics data: $e');
    }
  }

  String _getMuscleGroupForExercise(String exerciseId) {
    // For now, return a generic muscle group since we don't have exercise names
    // In a real app, you'd look up the exercise by ID to get its muscle group
    return 'General';
  }
}

// Providers
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(Supabase.instance.client);
});

final currentWorkoutSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return Stream.fromFuture(repository.getCurrentWorkoutSession());
});

final workoutHistoryProvider = StreamProvider<List<WorkoutSession>>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.watchWorkoutSessions(limit: 20);
});

final workoutSetsProvider = StreamProvider.family<List<WorkoutSet>, String>((ref, sessionId) {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.watchWorkoutSets(sessionId);
});

final workoutSessionProvider = FutureProvider.family<WorkoutSession?, String>((ref, sessionId) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getWorkoutSession(sessionId);
});