import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise.dart';

class ExerciseRepository {
  final _client = Supabase.instance.client;

  Stream<List<Exercise>> watchExercises() {
    try {
      final stream = _client
          .from('exercises')
          .stream(primaryKey: ['id'])
          .order('name')
          .map((rows) => rows.map((e) => Exercise.fromMap(e)).toList());
      return stream;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Exercises stream error: $e');
      }
      return const Stream<List<Exercise>>.empty();
    }
  }
}

final exerciseRepoProvider = Provider<ExerciseRepository>((ref) => ExerciseRepository());
final exerciseStreamProvider = StreamProvider<List<Exercise>>((ref) => ref.read(exerciseRepoProvider).watchExercises());