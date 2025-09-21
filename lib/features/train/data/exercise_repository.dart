import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'exercise.dart';

class ExerciseRepositoryException implements Exception {
  const ExerciseRepositoryException(this.message);
  final String message;

  @override
  String toString() => 'ExerciseRepositoryException: $message';
}

class ExerciseRepository {
  ExerciseRepository(this._supabase);
  final SupabaseClient _supabase;

  String? _getCurrentUserId() {
    final user = _supabase.auth.currentUser;
    return user?.id;
  }

  Future<T> _handleDatabaseOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PostgrestException catch (e) {
      throw ExerciseRepositoryException('Database error: ${e.message}');
    } on AuthException catch (e) {
      throw ExerciseRepositoryException('Authentication error: ${e.message}');
    } catch (e) {
      throw ExerciseRepositoryException('Unexpected error: $e');
    }
  }

  Stream<List<Exercise>> watchExercises({
    String? searchQuery,
    String? muscleGroup,
    String? equipment,
  }) {
    var query = _supabase
        .from('exercises')
        .stream(primaryKey: ['id'])
        .order('name');
    
    // Note: Filtering will be done client-side for stream
    return query.map((data) {
      var exercises = data.map((item) => Exercise.fromMap(item)).toList();
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        exercises = exercises.where((exercise) => 
            exercise.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      }
      
      if (muscleGroup != null && muscleGroup.isNotEmpty) {
        exercises = exercises.where((exercise) => 
            exercise.primaryMuscle?.toLowerCase() == muscleGroup.toLowerCase()).toList();
      }
      
      if (equipment != null && equipment.isNotEmpty) {
        exercises = exercises.where((exercise) => 
            exercise.equipment?.toLowerCase() == equipment.toLowerCase()).toList();
      }
      
      return exercises;
    });
  }

  Future<List<Exercise>> searchExercises({
    String? query,
    String? muscleGroup,
    String? equipment,
    int limit = 50,
  }) async {
    return _handleDatabaseOperation(() async {
      var supabaseQuery = _supabase
          .from('exercises')
          .select();
      
      if (query != null && query.isNotEmpty) {
        supabaseQuery = supabaseQuery.ilike('name', '%$query%');
      }
      
      if (muscleGroup != null && muscleGroup.isNotEmpty) {
        supabaseQuery = supabaseQuery.eq('primary_muscle', muscleGroup);
      }
      
      if (equipment != null && equipment.isNotEmpty) {
        supabaseQuery = supabaseQuery.eq('equipment', equipment);
      }
      
      final response = await supabaseQuery
          .order('name')
          .limit(limit);
      return response.map((item) => Exercise.fromMap(item)).toList();
    });
  }

  Future<Exercise> createCustomExercise({
    required String name,
    String? primaryMuscle,
    String? equipment,
    String? mediaUrl,
  }) async {
    return _handleDatabaseOperation(() async {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw const ExerciseRepositoryException('User must be authenticated to create exercises');
      }
      
      final response = await _supabase
          .from('exercises')
          .insert({
            'name': name,
            'primary_muscle': primaryMuscle,
            'equipment': equipment,
            'media_url': mediaUrl,
            'created_by': userId,
          })
          .select()
          .single();

      return Exercise.fromMap(response);
    });
  }

  Future<Exercise> updateExercise(Exercise exercise) async {
    return _handleDatabaseOperation(() async {
      final response = await _supabase
          .from('exercises')
          .update({
            'name': exercise.name,
            'primary_muscle': exercise.primaryMuscle,
            'equipment': exercise.equipment,
            'media_url': exercise.mediaUrl,
          })
          .eq('id', exercise.id)
          .select()
          .single();

      return Exercise.fromMap(response);
    });
  }

  Future<Exercise?> getExerciseById(String exerciseId) async {
    return _handleDatabaseOperation(() async {
      final response = await _supabase
          .from('exercises')
          .select()
          .eq('id', exerciseId)
          .maybeSingle();
      
      if (response == null) return null;
      return Exercise.fromMap(response);
    });
  }

  Future<void> deleteExercise(String exerciseId) async {
    return _handleDatabaseOperation(() async {
      await _supabase
          .from('exercises')
          .delete()
          .eq('id', exerciseId);
    });
  }

  Future<List<String>> getMuscleGroups() async {
    return _handleDatabaseOperation(() async {
      final response = await _supabase
          .from('exercises')
          .select('primary_muscle')
          .not('primary_muscle', 'is', null);
      
      final muscleGroups = response
          .map((item) => item['primary_muscle'] as String)
          .toSet()
          .toList();
      
      muscleGroups.sort();
      return muscleGroups;
    });
  }

  Future<List<String>> getEquipmentTypes() async {
    return _handleDatabaseOperation(() async {
      final response = await _supabase
          .from('exercises')
          .select('equipment')
          .not('equipment', 'is', null);
      
      final equipmentTypes = response
          .map((item) => item['equipment'] as String)
          .toSet()
          .toList();
      
      equipmentTypes.sort();
      return equipmentTypes;
    });
  }

  // Favorites functionality
  Future<void> addToFavorites(String exerciseId) async {
    return _handleDatabaseOperation(() async {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw const ExerciseRepositoryException('User must be authenticated');
      }
      
      await _supabase
          .from('exercise_favorites')
          .insert({
            'user_id': userId,
            'exercise_id': exerciseId,
          });
    });
  }

  Future<void> removeFromFavorites(String exerciseId) async {
    return _handleDatabaseOperation(() async {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw const ExerciseRepositoryException('User must be authenticated');
      }
      
      await _supabase
          .from('exercise_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId);
    });
  }

  Stream<List<Exercise>> watchFavoriteExercises() {
    final userId = _getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }
    
    return _supabase
        .from('exercise_favorites')
        .stream(primaryKey: ['user_id', 'exercise_id'])
        .eq('user_id', userId)
        .asyncMap((data) async {
          if (data.isEmpty) return <Exercise>[];
          
          final exerciseIds = data.map((item) => item['exercise_id'] as String).toList();
          final exercises = <Exercise>[];
          
          // Fetch exercises one by one since 'in' method might not be available
          for (final exerciseId in exerciseIds) {
            try {
              final exerciseData = await _supabase
                  .from('exercises')
                  .select()
                  .eq('id', exerciseId)
                  .maybeSingle();
              
              if (exerciseData != null) {
                exercises.add(Exercise.fromMap(exerciseData));
              }
            } catch (e) {
              // Skip exercises that can't be fetched
              continue;
            }
          }
          
          return exercises;
        });
  }

  Future<List<Exercise>> getRecentExercises({int limit = 10}) async {
    return _handleDatabaseOperation(() async {
      final userId = _getCurrentUserId();
      if (userId == null) {
        return <Exercise>[];
      }
      
      final response = await _supabase
          .from('workout_sets')
          .select('exercise_id, exercises(*)')
          .eq('workout_sessions.user_id', userId)
          .order('completed_at', ascending: false)
          .limit(limit);
      
      final exerciseIds = <String>{};
      final exercises = <Exercise>[];
      
      for (final item in response) {
        final exerciseId = item['exercise_id'] as String;
        if (!exerciseIds.contains(exerciseId)) {
          exerciseIds.add(exerciseId);
          exercises.add(Exercise.fromMap(item['exercises']));
        }
      }
      
      return exercises;
    });
  }
}

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(Supabase.instance.client);
});

final exerciseStreamProvider = StreamProvider<List<Exercise>>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.watchExercises();
});

final exerciseSearchProvider = StreamProvider.family<List<Exercise>, Map<String, String?>>((ref, filters) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.watchExercises(
    searchQuery: filters['query'],
    muscleGroup: filters['muscle'],
    equipment: filters['equipment'],
  );
});

final favoriteExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.watchFavoriteExercises();
});

final recentExercisesProvider = FutureProvider<List<Exercise>>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getRecentExercises();
});

final muscleGroupsProvider = FutureProvider<List<String>>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getMuscleGroups();
});

final equipmentTypesProvider = FutureProvider<List<String>>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getEquipmentTypes();
});

final exerciseProvider = FutureProvider.family<Exercise?, String>((ref, exerciseId) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getExerciseById(exerciseId);
});
