import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitai/features/train/data/program.dart';

class ProgramRepository {
  final _client = Supabase.instance.client;
  Stream<List<Program>> watchFeatured() => _client
      .from('programs')
      .stream(primaryKey: ['id'])
      .eq('is_featured', true)
      .order('name')
      .map((rows) => rows.map(Program.fromMap).toList());
}

final programRepoProvider = Provider((_) => ProgramRepository());
final featuredProgramsProvider = StreamProvider<List<Program>>((ref) => ref.read(programRepoProvider).watchFeatured());