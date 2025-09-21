import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'workout_session.dart';
import 'workout_set.dart';

// Offline Workout Manager Provider
final offlineWorkoutManagerProvider = Provider<OfflineWorkoutManager>((ref) {
  return OfflineWorkoutManager();
});

// Connectivity Provider
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Sync Status Provider
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier(ref.read(offlineWorkoutManagerProvider));
});

class SyncStatus {
  final bool isSyncing;
  final int pendingWorkouts;
  final int pendingSets;
  final DateTime? lastSyncTime;
  final String? error;

  SyncStatus({
    required this.isSyncing,
    required this.pendingWorkouts,
    required this.pendingSets,
    this.lastSyncTime,
    this.error,
  });

  SyncStatus copyWith({
    bool? isSyncing,
    int? pendingWorkouts,
    int? pendingSets,
    DateTime? lastSyncTime,
    String? error,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingWorkouts: pendingWorkouts ?? this.pendingWorkouts,
      pendingSets: pendingSets ?? this.pendingSets,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error,
    );
  }
}

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  final OfflineWorkoutManager _offlineManager;
  Timer? _syncTimer;

  SyncStatusNotifier(this._offlineManager) : super(SyncStatus(
    isSyncing: false,
    pendingWorkouts: 0,
    pendingSets: 0,
  )) {
    _initializeSync();
  }

  void _initializeSync() {
    _updatePendingCounts();
    
    // Auto-sync every 30 seconds when connected
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoSync();
    });
  }

  Future<void> _updatePendingCounts() async {
    final pendingWorkouts = await _offlineManager.getPendingWorkoutsCount();
    final pendingSets = await _offlineManager.getPendingSetsCount();
    
    state = state.copyWith(
      pendingWorkouts: pendingWorkouts,
      pendingSets: pendingSets,
    );
  }

  Future<void> _autoSync() async {
    if (state.isSyncing) return;
    
    final connectivityList = await Connectivity().checkConnectivity();
    if (connectivityList.contains(ConnectivityResult.none)) return;
    
    await syncPendingData();
  }

  Future<void> syncPendingData() async {
    if (state.isSyncing) return;
    
    state = state.copyWith(isSyncing: true, error: null);
    
    try {
      await _offlineManager.syncPendingData();
      await _updatePendingCounts();
      
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

class OfflineWorkoutManager {
  static const String _workoutsKey = 'offline_workouts';
  static const String _setsKey = 'offline_sets';
  static const String _lastSyncKey = 'last_sync_time';
  
  final SupabaseClient _supabase = Supabase.instance.client;

  // Save workout session offline
  Future<void> saveWorkoutOffline(WorkoutSession workout) async {
    final prefs = await SharedPreferences.getInstance();
    final workouts = await _getOfflineWorkouts();
    
    // Add or update workout
    final existingIndex = workouts.indexWhere((w) => w.id == workout.id);
    if (existingIndex >= 0) {
      workouts[existingIndex] = workout;
    } else {
      workouts.add(workout);
    }
    
    await _saveOfflineWorkouts(workouts);
  }

  // Save workout set offline
  Future<void> saveSetOffline(WorkoutSet set) async {
    final prefs = await SharedPreferences.getInstance();
    final sets = await _getOfflineSets();
    
    // Add or update set
    final existingIndex = sets.indexWhere((s) => s.id == set.id);
    if (existingIndex >= 0) {
      sets[existingIndex] = set;
    } else {
      sets.add(set);
    }
    
    await _saveOfflineSets(sets);
  }

  // Get offline workouts
  Future<List<WorkoutSession>> getOfflineWorkouts() async {
    return await _getOfflineWorkouts();
  }

  // Get offline sets for a workout
  Future<List<WorkoutSet>> getOfflineSets(String workoutId) async {
    final allSets = await _getOfflineSets();
    return allSets.where((set) => set.sessionId == workoutId).toList();
  }

  // Sync pending data to Supabase
  Future<void> syncPendingData() async {
    final connectivityList = await Connectivity().checkConnectivity();
    if (connectivityList.contains(ConnectivityResult.none)) {
      throw Exception('No internet connection');
    }

    // Sync workouts first
    await _syncWorkouts();
    
    // Then sync sets
    await _syncSets();
    
    // Update last sync time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  Future<void> _syncWorkouts() async {
    final workouts = await _getOfflineWorkouts();
    final syncedWorkouts = <WorkoutSession>[];
    
    for (final workout in workouts) {
      try {
        // Check if workout exists in Supabase
        final existingWorkout = await _supabase
            .from('workout_sessions')
            .select()
            .eq('id', workout.id)
            .maybeSingle();
        
        if (existingWorkout == null) {
          // Insert new workout
          await _supabase
              .from('workout_sessions')
              .insert(workout.toMap());
        } else {
          // Update existing workout
          await _supabase
              .from('workout_sessions')
              .update(workout.toMap())
              .eq('id', workout.id);
        }
        
        syncedWorkouts.add(workout);
      } catch (e) {
        print('Error syncing workout ${workout.id}: $e');
        // Continue with other workouts
      }
    }
    
    // Remove synced workouts from offline storage
    final remainingWorkouts = workouts
        .where((w) => !syncedWorkouts.any((s) => s.id == w.id))
        .toList();
    await _saveOfflineWorkouts(remainingWorkouts);
  }

  Future<void> _syncSets() async {
    final sets = await _getOfflineSets();
    final syncedSets = <WorkoutSet>[];
    
    for (final set in sets) {
      try {
        // Check if set exists in Supabase
        final existingSet = await _supabase
            .from('workout_sets')
            .select()
            .eq('id', set.id)
            .maybeSingle();
        
        if (existingSet == null) {
          // Insert new set
          await _supabase
              .from('workout_sets')
              .insert(set.toMap());
        } else {
          // Update existing set
          await _supabase
              .from('workout_sets')
              .update(set.toMap())
              .eq('id', set.id);
        }
        
        syncedSets.add(set);
      } catch (e) {
        print('Error syncing set ${set.id}: $e');
        // Continue with other sets
      }
    }
    
    // Remove synced sets from offline storage
    final remainingSets = sets
        .where((s) => !syncedSets.any((synced) => synced.id == s.id))
        .toList();
    await _saveOfflineSets(remainingSets);
  }

  // Get pending counts
  Future<int> getPendingWorkoutsCount() async {
    final workouts = await _getOfflineWorkouts();
    return workouts.length;
  }

  Future<int> getPendingSetsCount() async {
    final sets = await _getOfflineSets();
    return sets.length;
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final syncTimeString = prefs.getString(_lastSyncKey);
    if (syncTimeString != null) {
      return DateTime.parse(syncTimeString);
    }
    return null;
  }

  // Export workout data
  Future<Map<String, dynamic>> exportWorkoutData() async {
    final workouts = await _getOfflineWorkouts();
    final sets = await _getOfflineSets();
    
    return {
      'workouts': workouts.map((w) => w.toMap()).toList(),
      'sets': sets.map((s) => s.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  // Import workout data
  Future<void> importWorkoutData(Map<String, dynamic> data) async {
    try {
      final workoutsData = data['workouts'] as List<dynamic>;
      final setsData = data['sets'] as List<dynamic>;
      
      final workouts = workoutsData
          .map((w) => WorkoutSession.fromMap(Map<String, dynamic>.from(w)))
          .toList();
      
      final sets = setsData
          .map((s) => WorkoutSet.fromMap(Map<String, dynamic>.from(s)))
          .toList();
      
      // Save imported data
      await _saveOfflineWorkouts(workouts);
      await _saveOfflineSets(sets);
      
    } catch (e) {
      throw Exception('Failed to import workout data: $e');
    }
  }

  // Clear all offline data
  Future<void> clearOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workoutsKey);
    await prefs.remove(_setsKey);
    await prefs.remove(_lastSyncKey);
  }

  // Private helper methods
  Future<List<WorkoutSession>> _getOfflineWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = prefs.getStringList(_workoutsKey) ?? [];
    
    return workoutsJson.map((json) {
      final map = Map<String, dynamic>.from(jsonDecode(json));
      return WorkoutSession.fromMap(map);
    }).toList();
  }

  Future<void> _saveOfflineWorkouts(List<WorkoutSession> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = workouts.map((w) => jsonEncode(w.toMap())).toList();
    await prefs.setStringList(_workoutsKey, workoutsJson);
  }

  Future<List<WorkoutSet>> _getOfflineSets() async {
    final prefs = await SharedPreferences.getInstance();
    final setsJson = prefs.getStringList(_setsKey) ?? [];
    
    return setsJson.map((json) {
      final map = Map<String, dynamic>.from(jsonDecode(json));
      return WorkoutSet.fromMap(map);
    }).toList();
  }

  Future<void> _saveOfflineSets(List<WorkoutSet> sets) async {
    final prefs = await SharedPreferences.getInstance();
    final setsJson = sets.map((s) => jsonEncode(s.toMap())).toList();
    await prefs.setStringList(_setsKey, setsJson);
  }

  // Check if device is online
  Future<bool> isOnline() async {
    final connectivityList = await Connectivity().checkConnectivity();
    return !connectivityList.contains(ConnectivityResult.none);
  }

  // Force sync (manual)
  Future<void> forceSync() async {
    await syncPendingData();
  }

  // Backup data to file
  Future<String> createBackup() async {
    final data = await exportWorkoutData();
    return jsonEncode(data);
  }

  // Restore from backup
  Future<void> restoreFromBackup(String backupJson) async {
    final data = jsonDecode(backupJson) as Map<String, dynamic>;
    await importWorkoutData(data);
  }

  // Get storage usage info
  Future<Map<String, int>> getStorageInfo() async {
    final workouts = await _getOfflineWorkouts();
    final sets = await _getOfflineSets();
    
    return {
      'workouts': workouts.length,
      'sets': sets.length,
      'totalItems': workouts.length + sets.length,
    };
  }
}

// Offline-first workout repository extension
class OfflineWorkoutRepository {
  final OfflineWorkoutManager _offlineManager;
  final SupabaseClient _supabase = Supabase.instance.client;

  OfflineWorkoutRepository(this._offlineManager);

  // Save workout (offline-first)
  Future<void> saveWorkout(WorkoutSession workout) async {
    // Always save offline first
    await _offlineManager.saveWorkoutOffline(workout);
    
    // Try to sync immediately if online
    if (await _offlineManager.isOnline()) {
      try {
        await _supabase
            .from('workout_sessions')
            .upsert(workout.toMap());
        
        // Remove from offline storage after successful sync
        final offlineWorkouts = await _offlineManager.getOfflineWorkouts();
        final updatedWorkouts = offlineWorkouts
            .where((w) => w.id != workout.id)
            .toList();
        await _offlineManager._saveOfflineWorkouts(updatedWorkouts);
      } catch (e) {
        // Keep in offline storage for later sync
        print('Failed to sync workout immediately: $e');
      }
    }
  }

  // Save set (offline-first)
  Future<void> saveSet(WorkoutSet set) async {
    // Always save offline first
    await _offlineManager.saveSetOffline(set);
    
    // Try to sync immediately if online
    if (await _offlineManager.isOnline()) {
      try {
        await _supabase
            .from('workout_sets')
            .upsert(set.toMap());
        
        // Remove from offline storage after successful sync
        final offlineSets = await _offlineManager._getOfflineSets();
        final updatedSets = offlineSets
            .where((s) => s.id != set.id)
            .toList();
        await _offlineManager._saveOfflineSets(updatedSets);
      } catch (e) {
        // Keep in offline storage for later sync
        print('Failed to sync set immediately: $e');
      }
    }
  }

  // Get workouts (offline-first)
  Future<List<WorkoutSession>> getWorkouts() async {
    final offlineWorkouts = await _offlineManager.getOfflineWorkouts();
    
    if (await _offlineManager.isOnline()) {
      try {
        final onlineWorkouts = await _supabase
            .from('workout_sessions')
            .select()
            .order('created_at', ascending: false);
        
        final workouts = onlineWorkouts
            .map((w) => WorkoutSession.fromMap(w))
            .toList();
        
        // Merge with offline workouts (offline takes precedence)
        final mergedWorkouts = <String, WorkoutSession>{};
        
        // Add online workouts first
        for (final workout in workouts) {
          mergedWorkouts[workout.id] = workout;
        }
        
        // Override with offline workouts
        for (final workout in offlineWorkouts) {
          mergedWorkouts[workout.id] = workout;
        }
        
        return mergedWorkouts.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        print('Failed to fetch online workouts: $e');
      }
    }
    
    return offlineWorkouts;
  }

  // Get sets for workout (offline-first)
  Future<List<WorkoutSet>> getSetsForWorkout(String workoutId) async {
    final offlineSets = await _offlineManager.getOfflineSets(workoutId);
    
    if (await _offlineManager.isOnline()) {
      try {
        final onlineSets = await _supabase
            .from('workout_sets')
            .select()
            .eq('workout_session_id', workoutId)
            .order('set_number');
        
        final sets = onlineSets
            .map((s) => WorkoutSet.fromMap(s))
            .toList();
        
        // Merge with offline sets (offline takes precedence)
        final mergedSets = <String, WorkoutSet>{};
        
        // Add online sets first
        for (final set in sets) {
          mergedSets[set.id] = set;
        }
        
        // Override with offline sets
        for (final set in offlineSets) {
          mergedSets[set.id] = set;
        }
        
        return mergedSets.values.toList()
          ..sort((a, b) => a.position.compareTo(b.position));
      } catch (e) {
        print('Failed to fetch online sets: $e');
      }
    }
    
    return offlineSets;
  }
}

// Provider for offline-first repository
final offlineWorkoutRepositoryProvider = Provider<OfflineWorkoutRepository>((ref) {
  final offlineManager = ref.read(offlineWorkoutManagerProvider);
  return OfflineWorkoutRepository(offlineManager);
});