import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../core/components/neon_focus.dart';
import 'data/workout_session.dart';
import 'data/workout_set.dart';
import 'data/workout_repository.dart';
import 'data/exercise.dart';
import 'data/exercise_repository.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String? programId;
  
  const WorkoutSessionScreen({
    super.key,
    this.sessionId,
    this.programId,
  });

  @override
  ConsumerState<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  Timer? _restTimer;
  int _restTimeRemaining = 0;
  bool _isResting = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    setState(() {
      _restTimeRemaining = seconds;
      _isResting = true;
    });
    
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restTimeRemaining--;
      });
      
      if (_restTimeRemaining <= 0) {
        timer.cancel();
        setState(() {
          _isResting = false;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = widget.sessionId != null
        ? ref.watch(workoutSessionProvider(widget.sessionId!))
        : null;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.sessionId != null ? 'Active Workout' : 'Start Workout',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.sessionId != null)
            IconButton(
              icon: const Icon(Icons.pause, color: Colors.white),
              onPressed: () => _pauseWorkout(),
            ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: () => _finishWorkout(),
          ),
        ],
      ),
      body: Stack(
        children: [
          widget.sessionId != null
              ? _buildActiveWorkout(sessionAsync)
              : _buildStartWorkout(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.cyan),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isResting ? _buildRestTimer() : null,
    );
  }

  Widget _buildActiveWorkout(AsyncValue<WorkoutSession?>? sessionAsync) {
    return sessionAsync?.when(
      data: (session) {
        if (session == null) {
          return const Center(
            child: Text(
              'Workout session not found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        return _buildWorkoutContent(session);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.cyan),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading workout: $error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    ) ?? const SizedBox();
  }

  Widget _buildStartWorkout() {
    final exercisesAsync = ref.watch(exerciseStreamProvider);
    
    return exercisesAsync.when(
      data: (exercises) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Quick Start Workout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select exercises to start your workout',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 20),
                NeonFocus(
                  child: ElevatedButton(
                    onPressed: () => _startQuickWorkout(exercises),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Start Empty Workout',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return _buildExerciseSelectionTile(exercise);
              },
            ),
          ),
        ],
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.cyan),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading exercises: $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildExerciseSelectionTile(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeonFocus(
        child: ListTile(
          tileColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.cyan.withOpacity(0.2),
            child: const Icon(Icons.fitness_center, color: Colors.cyan),
          ),
          title: Text(
            exercise.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${exercise.primaryMuscle} • ${exercise.equipment}',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.add, color: Colors.cyan),
          onTap: () => _startWorkoutWithExercise(exercise),
        ),
      ),
    );
  }

  Widget _buildWorkoutContent(WorkoutSession session) {
    final setsAsync = ref.watch(workoutSetsProvider(session.id));
    
    return Column(
      children: [
        setsAsync.when(
          data: (sets) => _buildWorkoutHeader(session, sets),
          loading: () => _buildWorkoutHeader(session, []),
          error: (error, stack) => _buildWorkoutHeader(session, []),
        ),
        Expanded(
          child: setsAsync.when(
            data: (sets) => _buildSetsList(sets, session),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading sets: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        _buildAddExerciseButton(session),
      ],
    );
  }

  Widget _buildWorkoutHeader(WorkoutSession session, List<WorkoutSet> sets) {
    final duration = session.startedAt != null
        ? DateTime.now().difference(session.startedAt!)
        : Duration.zero;
    
    // Calculate completed sets
    final completedSets = sets.where((set) => set.isCompleted).length;
    final totalSets = sets.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.withOpacity(0.2), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Duration', _formatTime(duration.inSeconds)),
              _buildStatCard('Volume', '${session.totalVolume?.toStringAsFixed(1) ?? '0'} kg'),
              _buildStatCard('Sets', '$completedSets/$totalSets'),
            ],
          ),
          if (session.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.notes!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.cyan,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSetsList(List<WorkoutSet> sets, WorkoutSession session) {
    if (sets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'No exercises added yet',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add exercises',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group sets by exercise
    final groupedSets = <String, List<WorkoutSet>>{};
    for (final set in sets) {
      groupedSets.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedSets.length,
      itemBuilder: (context, index) {
        final exerciseId = groupedSets.keys.elementAt(index);
        final exerciseSets = groupedSets[exerciseId]!;
        return _buildExerciseGroup(exerciseId, exerciseSets, session);
      },
    );
  }

  Widget _buildExerciseGroup(String exerciseId, List<WorkoutSet> sets, WorkoutSession session) {
    final exerciseAsync = ref.watch(exerciseProvider(exerciseId));
    
    return exerciseAsync.when(
      data: (exercise) {
        if (exercise == null) return const SizedBox();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            exercise.primaryMuscle ?? 'Unknown',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.cyan),
                      onPressed: () => _addSet(session.id, exerciseId),
                    ),
                  ],
                ),
              ),
              ...sets.asMap().entries.map((entry) {
                final setIndex = entry.key;
                final set = entry.value;
                return _buildSetTile(set, setIndex + 1, session);
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (error, stack) => const SizedBox(),
    );
  }

  Widget _buildSetTile(WorkoutSet set, int setNumber, WorkoutSession session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$setNumber',
              style: TextStyle(
                color: set.isCompleted ? Colors.cyan : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildSetInput(
                    'Weight',
                    set.weightKg?.toString() ?? '',
                    (value) => _updateSet(set, weightKg: double.tryParse(value)),
                    enabled: !set.isCompleted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSetInput(
                    'Reps',
                    set.reps?.toString() ?? '',
                    (value) => _updateSet(set, reps: int.tryParse(value)),
                    enabled: !set.isCompleted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NeonFocus(
            child: IconButton(
              icon: Icon(
                set.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: set.isCompleted ? Colors.cyan : Colors.grey,
              ),
              onPressed: () => _toggleSetCompletion(set, session),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetInput(
    String label,
    String value,
    Function(String) onChanged, {
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          enabled: enabled,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey[800] : Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          keyboardType: TextInputType.number,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildAddExerciseButton(WorkoutSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
          onPressed: () => _showAddExerciseDialog(session),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add),
              SizedBox(width: 8),
              Text(
                'Add Exercise',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildRestTimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.1),
        border: Border(top: BorderSide(color: Colors.cyan.withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Rest Timer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            _formatTime(_restTimeRemaining),
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              _restTimer?.cancel();
              setState(() {
                _isResting = false;
              });
            },
            child: const Text('Skip', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuickWorkout(List<Exercise> exercises) async {
    try {
      final session = await ref.read(workoutRepositoryProvider).createWorkoutSession(
        programId: widget.programId,
      );
      
      if (mounted) {
        context.pushReplacement('/train/session/${session.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startWorkoutWithExercise(Exercise exercise) async {
    try {
      final session = await ref.read(workoutRepositoryProvider).createWorkoutSession(
        programId: widget.programId,
      );
      
      // Add first set for the selected exercise
      await ref.read(workoutRepositoryProvider).createWorkoutSet(
        sessionId: session.id,
        exerciseId: exercise.id,
        position: 0,
      );
      
      if (mounted) {
        context.pushReplacement('/train/session/${session.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addSet(String sessionId, String exerciseId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current sets for this exercise to calculate position
      final allSets = await ref.read(workoutSetsProvider(sessionId).future);
      final exerciseSets = allSets.where((set) => set.exerciseId == exerciseId).toList();
      
      await ref.read(workoutRepositoryProvider).createWorkoutSet(
        sessionId: sessionId,
        exerciseId: exerciseId,
        position: exerciseSets.length,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSet(WorkoutSet set, {double? weightKg, int? reps}) async {
    try {
      final updatedSet = set.copyWith(
        weightKg: weightKg ?? set.weightKg,
        reps: reps ?? set.reps,
      );
      
      await ref.read(workoutRepositoryProvider).updateWorkoutSet(updatedSet);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleSetCompletion(WorkoutSet set, WorkoutSession session) async {
    try {
      final updatedSet = set.copyWith(
        isCompleted: !set.isCompleted,
        completedAt: !set.isCompleted ? DateTime.now() : null,
      );
      
      await ref.read(workoutRepositoryProvider).updateWorkoutSet(updatedSet);
      
      // Start rest timer if set was just completed
      if (updatedSet.isCompleted && set.restTime != null && set.restTime!.inSeconds > 0) {
        _startRestTimer(set.restTime!.inSeconds);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseWorkout() async {
    if (widget.sessionId == null) return;
    
    try {
      await ref.read(workoutRepositoryProvider).pauseWorkout(widget.sessionId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pause workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finishWorkout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout'),
        content: const Text('Are you sure you want to finish this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(workoutRepositoryProvider).finishWorkout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to finish workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddExerciseDialog(WorkoutSession session) async {
    final exercisesAsync = ref.read(exerciseStreamProvider);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Add Exercise',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: exercisesAsync.when(
            data: (exercises) => ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return ListTile(
                  title: Text(
                    exercise.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    exercise.primaryMuscle ?? 'Unknown',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _addSet(session.id, exercise.id);
                  },
                );
              },
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading exercises: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}