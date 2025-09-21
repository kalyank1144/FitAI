import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'program.dart';
import 'exercise.dart';

class ProgramRepositoryException implements Exception {
  final String message;
  ProgramRepositoryException(this.message);
  
  @override
  String toString() => 'ProgramRepositoryException: $message';
}

class ProgramRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<Program>> watchFeatured() {
    return _supabase
        .from('programs')
        .stream(primaryKey: ['id'])
        .eq('is_featured', true)
        .map((data) => data.map((json) => Program.fromMap(json)).toList());
  }

  Stream<List<Program>> watchUserPrograms() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw ProgramRepositoryException('User not authenticated');
    }

    return _supabase
        .from('programs')
        .stream(primaryKey: ['id'])
        .eq('created_by', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Program.fromMap(json)).toList());
  }

  Stream<List<Program>> watchAllPrograms() {
    return _supabase
        .from('programs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Program.fromMap(json)).toList());
  }

  Future<Program?> getProgram(String id) async {
    try {
      final response = await _supabase
          .from('programs')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      return response != null ? Program.fromMap(response) : null;
    } catch (e) {
      throw ProgramRepositoryException('Failed to get program: $e');
    }
  }

  Future<List<Exercise>> getProgramExercises(String programId) async {
    try {
      final response = await _supabase
          .from('program_exercises')
          .select('exercises(*)')
          .eq('program_id', programId)
          .order('order_index');
      
      return response
          .map((item) => Exercise.fromMap(item['exercises']))
          .toList();
    } catch (e) {
      throw ProgramRepositoryException('Failed to get program exercises: $e');
    }
  }

  Future<Program> createProgram({
    required String name,
    required String description,
    required String difficulty,
    String? coverUrl,
    bool isFeatured = false,
    List<String>? exerciseIds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw ProgramRepositoryException('User not authenticated');
    }

    try {
      final programData = {
        'name': name,
        'description': description,
        'difficulty': difficulty,
        'cover_url': coverUrl,
        'is_featured': isFeatured,
        'created_by': userId,
      };

      final response = await _supabase
          .from('programs')
          .insert(programData)
          .select()
          .single();

      final program = Program.fromMap(response);

      // Add exercises to program if provided
      if (exerciseIds != null && exerciseIds.isNotEmpty) {
        await _addExercisesToProgram(program.id, exerciseIds);
      }

      return program;
    } catch (e) {
      throw ProgramRepositoryException('Failed to create program: $e');
    }
  }

  Future<Program> updateProgram(Program program) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw ProgramRepositoryException('User not authenticated');
    }

    try {
      final response = await _supabase
          .from('programs')
          .update(program.toMap())
          .eq('id', program.id)
          .eq('created_by', userId)
          .select()
          .single();

      return Program.fromMap(response);
    } catch (e) {
      throw ProgramRepositoryException('Failed to update program: $e');
    }
  }

  Future<void> deleteProgram(String programId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw ProgramRepositoryException('User not authenticated');
    }

    try {
      await _supabase
          .from('programs')
          .delete()
          .eq('id', programId)
          .eq('created_by', userId);
    } catch (e) {
      throw ProgramRepositoryException('Failed to delete program: $e');
    }
  }

  Future<void> _addExercisesToProgram(String programId, List<String> exerciseIds) async {
    try {
      final programExercises = exerciseIds.asMap().entries.map((entry) => {
        'program_id': programId,
        'exercise_id': entry.value,
        'order_index': entry.key,
      }).toList();

      await _supabase
          .from('program_exercises')
          .insert(programExercises);
    } catch (e) {
      throw ProgramRepositoryException('Failed to add exercises to program: $e');
    }
  }

  Future<void> updateProgramExercises(String programId, List<String> exerciseIds) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw ProgramRepositoryException('User not authenticated');
    }

    try {
      // First, remove existing exercises
      await _supabase
          .from('program_exercises')
          .delete()
          .eq('program_id', programId);

      // Then add new exercises
      if (exerciseIds.isNotEmpty) {
        await _addExercisesToProgram(programId, exerciseIds);
      }
    } catch (e) {
      throw ProgramRepositoryException('Failed to update program exercises: $e');
    }
  }

  Future<Program> duplicateProgram(String programId, {String? newName}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw ProgramRepositoryException('User not authenticated');
    }

    try {
      // Get original program
      final originalProgram = await getProgram(programId);
      if (originalProgram == null) {
        throw ProgramRepositoryException('Program not found');
      }

      // Get program exercises
      final exercises = await getProgramExercises(programId);

      // Create new program
      final duplicatedProgram = await createProgram(
        name: newName ?? '${originalProgram.name} (Copy)',
        description: originalProgram.description,
        difficulty: originalProgram.difficulty,
        coverUrl: originalProgram.coverUrl,
        exerciseIds: exercises.map((e) => e.id).toList(),
      );

      return duplicatedProgram;
    } catch (e) {
      throw ProgramRepositoryException('Failed to duplicate program: $e');
    }
  }

  Future<List<Program>> searchPrograms(String query) async {
    try {
      final response = await _supabase
          .from('programs')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return response.map((json) => Program.fromMap(json)).toList();
    } catch (e) {
      throw ProgramRepositoryException('Failed to search programs: $e');
    }
  }

  Future<List<Program>> getProgramsByDifficulty(String difficulty) async {
    try {
      final response = await _supabase
          .from('programs')
          .select()
          .eq('difficulty', difficulty)
          .order('created_at', ascending: false);

      return response.map((json) => Program.fromMap(json)).toList();
    } catch (e) {
      throw ProgramRepositoryException('Failed to get programs by difficulty: $e');
    }
  }
}

final programRepositoryProvider = Provider((ref) => ProgramRepository());

final featuredProgramsProvider = StreamProvider((ref) {
  return ref.watch(programRepositoryProvider).watchFeatured();
});

final userProgramsProvider = StreamProvider((ref) {
  return ref.watch(programRepositoryProvider).watchUserPrograms();
});

final allProgramsProvider = StreamProvider((ref) {
  return ref.watch(programRepositoryProvider).watchAllPrograms();
});

final programProvider = FutureProvider.family<Program?, String>((ref, id) {
  return ref.watch(programRepositoryProvider).getProgram(id);
});

final programExercisesProvider = FutureProvider.family<List<Exercise>, String>((ref, programId) {
  return ref.watch(programRepositoryProvider).getProgramExercises(programId);
});

final programSearchProvider = FutureProvider.family<List<Program>, String>((ref, query) {
  if (query.isEmpty) return [];
  return ref.watch(programRepositoryProvider).searchPrograms(query);
});

final programsByDifficultyProvider = FutureProvider.family<List<Program>, String>((ref, difficulty) {
  return ref.watch(programRepositoryProvider).getProgramsByDifficulty(difficulty);
});
