import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class NutritionTotals {
  const NutritionTotals({this.calories = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0});
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
}

class NutritionEntry {
  const NutritionEntry({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.time,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String foodName;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final DateTime time;
  final DateTime? createdAt;

  factory NutritionEntry.fromMap(Map<String, dynamic> map) {
    return NutritionEntry(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      foodName: map['food_name']?.toString() ?? 'Unknown food',
      calories: (map['calories'] ?? 0) as int,
      proteinG: (map['protein_g'] ?? 0) as int,
      carbsG: (map['carbs_g'] ?? 0) as int,
      fatG: (map['fat_g'] ?? 0) as int,
      time: DateTime.parse(map['time'] ?? DateTime.now().toIso8601String()),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'food_name': foodName,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'time': time.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  NutritionEntry copyWith({
    String? id,
    String? userId,
    String? foodName,
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatG,
    DateTime? time,
    DateTime? createdAt,
  }) {
    return NutritionEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NutritionRepositoryException implements Exception {
  const NutritionRepositoryException(this.message, [this.code]);
  final String message;
  final String? code;

  @override
  String toString() => 'NutritionRepositoryException: $message${code != null ? ' (Code: $code)' : ''}';
}

class ValidationException extends NutritionRepositoryException {
  const ValidationException(String message) : super(message, 'VALIDATION_ERROR');
}

class NetworkException extends NutritionRepositoryException {
  const NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class AuthenticationException extends NutritionRepositoryException {
  const AuthenticationException(String message) : super(message, 'AUTH_ERROR');
}

class DatabaseException extends NutritionRepositoryException {
  const DatabaseException(String message, [String? code]) : super(message, code ?? 'DATABASE_ERROR');
}

class RateLimitException extends NutritionRepositoryException {
  const RateLimitException(String message) : super(message, 'RATE_LIMIT_ERROR');
}

class NutritionRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Check connection status and attempt to reconnect if needed
  Future<bool> checkConnection() async {
    try {
      // Simple ping to check if Supabase is reachable
      await _client.from('nutrition_entries').select('id').limit(1);
      return true;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }

  /// Force refresh all active streams
  Future<void> refreshStreams() async {
    try {
      // This would trigger a refresh of all active streams
      // In practice, Supabase streams auto-refresh, but this can be used
      // to manually trigger updates after connection recovery
      await _client.removeAllChannels();
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('Error refreshing streams: $e');
    }
  }

  /// Get connection status stream
  Stream<bool> watchConnectionStatus() {
    return Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => checkConnection())
        .distinct()
        .handleError((error) {
      print('Connection status error: $error');
      return false;
    });
  }

  // Validation methods
  void _validateEntry({
    required String foodName,
    required int calories,
    required int proteinG,
    required int carbsG,
    required int fatG,
  }) {
    if (foodName.trim().isEmpty) {
      throw const ValidationException('Food name cannot be empty');
    }
    if (foodName.length > 100) {
      throw const ValidationException('Food name cannot exceed 100 characters');
    }
    if (calories < 0 || calories > 10000) {
      throw const ValidationException('Calories must be between 0 and 10,000');
    }
    if (proteinG < 0 || proteinG > 1000) {
      throw const ValidationException('Protein must be between 0 and 1,000g');
    }
    if (carbsG < 0 || carbsG > 1000) {
      throw const ValidationException('Carbs must be between 0 and 1,000g');
    }
    if (fatG < 0 || fatG > 1000) {
      throw const ValidationException('Fat must be between 0 and 1,000g');
    }
  }

  /// Get current user ID from Supabase Auth
  Future<String> _getCurrentUserId() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('User not authenticated. Please log in again.');
    }
    return user.id;
  }

  /// Enhanced database operation handler with retry logic and specific error handling
  Future<T> _handleDatabaseOperation<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } on PostgrestException catch (e) {
        attempts++;
        
        // Handle specific PostgreSQL error codes
        switch (e.code) {
          case '23505': // Unique constraint violation
            throw const DatabaseException('This entry already exists');
          case '23503': // Foreign key constraint violation
            throw const DatabaseException('Invalid reference data');
          case '42501': // Insufficient privilege
            throw const AuthenticationException('Insufficient permissions to perform this operation');
          case 'PGRST301': // Row Level Security violation
            throw const AuthenticationException('Access denied. Please check your permissions.');
          case 'PGRST116': // Multiple/ambiguous resource
            throw const DatabaseException('Multiple records found when expecting one');
          case 'PGRST106': // Resource not found
            throw const DatabaseException('Requested data not found');
          default:
            if (attempts >= maxRetries) {
              throw DatabaseException('Database operation failed: ${e.message}', e.code);
            }
        }
        
        // Wait before retry with exponential backoff
        if (attempts < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        }
      } on SocketException catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw NetworkException('Network connection failed: ${e.message}');
        }
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 1000 * attempts));
      } on HttpException catch (e) {
        attempts++;
        if (e.message.contains('429')) {
          throw const RateLimitException('Too many requests. Please try again later.');
        }
        if (attempts >= maxRetries) {
          throw NetworkException('HTTP error: ${e.message}');
        }
        await Future.delayed(Duration(milliseconds: 1000 * attempts));
      } on FormatException catch (e) {
        throw DatabaseException('Data format error: ${e.message}');
      } on AuthException catch (e) {
        throw AuthenticationException('Authentication failed: ${e.message}');
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw NutritionRepositoryException('Unexpected error: $e', 'UNKNOWN_ERROR');
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
    
    throw const NutritionRepositoryException('Operation failed after maximum retries', 'MAX_RETRIES_EXCEEDED');
  }

  /// Enhanced stream with connection handling and retry mechanisms
  Stream<T> _createResilientStream<T>(
    Stream<T> Function() streamFactory,
    T fallbackValue, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    return Stream.fromFuture(_createStreamWithRetry(
      streamFactory,
      fallbackValue,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
    )).asyncExpand((stream) => stream);
  }

  Future<Stream<T>> _createStreamWithRetry<T>(
    Stream<T> Function() streamFactory,
    T fallbackValue, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        final stream = streamFactory();
        
        // Add connection monitoring and auto-retry on errors
        return stream
            .timeout(
              const Duration(seconds: 30),
              onTimeout: (sink) {
                sink.add(fallbackValue);
                sink.close();
              },
            )
            .handleError((error) {
              print('Stream error (attempt ${attempts + 1}): $error');
              // For connection errors, we'll retry
              if (error.toString().contains('connection') ||
                  error.toString().contains('network') ||
                  error.toString().contains('timeout')) {
                throw error; // This will trigger retry
              }
              // For other errors, return fallback
              return fallbackValue;
            })
            .handleError((error) {
              print('Stream error: $error');
              if (attempts < maxRetries - 1) {
                attempts++;
                // For retry logic, we'll handle this in the outer try-catch
                throw error;
              }
              // Return fallback value for final failure
              return fallbackValue;
            });
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          print('Max retries exceeded for stream creation: $e');
          return Stream.value(fallbackValue);
        }
        await Future.delayed(retryDelay * attempts);
      }
    }
    
    return Stream.value(fallbackValue);
  }

  Stream<NutritionTotals> watchToday() {
    return _createResilientStream(
      () {
        final user = _client.auth.currentUser;
        if (user == null) throw const AuthenticationException('User not authenticated');
        final userId = user.id;
        final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
        
        return _client
            .from('nutrition_daily_totals')
            .stream(primaryKey: ['user_id','date'])
            .map((rows) {
          try {
            // Filter for current user and today's date
            final filteredRows = rows.where((row) => 
              row['user_id'] == userId && row['date'] == today
            ).toList();
            
            if (filteredRows.isEmpty) return const NutritionTotals();
            final r = filteredRows.first;
            return NutritionTotals(
              calories: (r['calories'] ?? 0) as int,
              proteinG: (r['protein_g'] ?? 0) as int,
              carbsG: (r['carbs_g'] ?? 0) as int,
              fatG: (r['fat_g'] ?? 0) as int,
            );
          } catch (e) {
            print('Error parsing nutrition totals: $e');
            return const NutritionTotals();
          }
        });
      },
      const NutritionTotals(),
    );
  }
  
  Stream<List<NutritionEntry>> watchEntries({DateTime? date}) {
    return _createResilientStream(
      () {
        final user = _client.auth.currentUser;
        if (user == null) throw const AuthenticationException('User not authenticated');
        final userId = user.id;
        final targetDate = date ?? DateTime.now();
        final dateStr = targetDate.toUtc().toIso8601String().substring(0, 10);
        final dayStart = '${dateStr}T00:00:00Z';
        final dayEnd = '${DateTime(targetDate.year, targetDate.month, targetDate.day + 1).toUtc().toIso8601String().substring(0, 10)}T00:00:00Z';
        
        return _client
            .from('nutrition_entries')
            .stream(primaryKey: ['id'])
            .map((rows) {
          try {
            // Filter for current user and specified date's entries
            final filteredRows = rows.where((row) {
              final rowUserId = row['user_id'];
              final rowTime = row['time'];
              return rowUserId == userId && 
                     rowTime != null && 
                     rowTime.compareTo(dayStart) >= 0 && 
                     rowTime.compareTo(dayEnd) < 0;
            }).toList();
            
            // Sort by time descending and convert to NutritionEntry objects
            filteredRows.sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));
            return filteredRows.map((row) => NutritionEntry.fromMap(row)).toList();
          } catch (e) {
            print('Error parsing nutrition entries: $e');
            return <NutritionEntry>[];
          }
        });
      },
      <NutritionEntry>[],
    );
  }

  // Legacy method for backward compatibility
  Stream<List<Map<String, dynamic>>> watchEntriesRaw() {
    return watchEntries().map((entries) => entries.map((e) => e.toMap()).toList());
  }

  // CREATE operations
  Future<NutritionEntry> createEntry({
    required String foodName,
    required int calories,
    int proteinG = 0,
    int carbsG = 0,
    int fatG = 0,
    DateTime? time,
  }) async {
    return _handleDatabaseOperation(() async {
      final userId = await _getCurrentUserId();
      _validateEntry(
        foodName: foodName,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
      );

      final entryTime = time ?? DateTime.now();
      final response = await _client.from('nutrition_entries').insert({
        'user_id': userId,
        'food_name': foodName.trim(),
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'time': entryTime.toIso8601String(),
      }).select().single();

      return NutritionEntry.fromMap(response);
    });
  }

  Future<void> quickAdd({required int calories, int proteinG = 0, int carbsG = 0, int fatG = 0}) async {
    final entry = NutritionEntry(
      id: '', // Will be generated by the server
      userId: await _getCurrentUserId(),
      foodName: 'Quick Add',
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      time: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await createEntryWithOfflineSupport(entry);
  }

  // READ operations
  Future<NutritionEntry?> getEntryById(String id) async {
    return _handleDatabaseOperation(() async {
      final userId = await _getCurrentUserId();
      final response = await _client
          .from('nutrition_entries')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? NutritionEntry.fromMap(response) : null;
    });
  }

  Future<List<NutritionEntry>> getEntriesByDateRange(DateTime startDate, DateTime endDate) async {
    return _handleDatabaseOperation(() async {
      final userId = await _getCurrentUserId();
      final response = await _client
          .from('nutrition_entries')
          .select()
          .eq('user_id', userId)
          .gte('time', startDate.toIso8601String())
          .lt('time', endDate.toIso8601String())
          .order('time', ascending: false);

      return response.map((row) => NutritionEntry.fromMap(row)).toList();
    });
  }



  // UPDATE operations with optimistic updates
  Future<NutritionEntry> updateEntry(String id, {
    String? foodName,
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatG,
    DateTime? time,
  }) async {
    return _handleDatabaseOperation(() async {
      final userId = await _getCurrentUserId();
      
      // Get current entry to validate ownership
      final currentEntry = await getEntryById(id);
      if (currentEntry == null) {
        throw const NutritionRepositoryException('Entry not found', 'NOT_FOUND');
      }

      // Prepare update data
      final updateData = <String, dynamic>{};
      if (foodName != null) {
        updateData['food_name'] = foodName.trim();
      }
      if (calories != null) updateData['calories'] = calories;
      if (proteinG != null) updateData['protein_g'] = proteinG;
      if (carbsG != null) updateData['carbs_g'] = carbsG;
      if (fatG != null) updateData['fat_g'] = fatG;
      if (time != null) updateData['time'] = time.toIso8601String();

      // Validate the updated entry
      _validateEntry(
        foodName: foodName ?? currentEntry.foodName,
        calories: calories ?? currentEntry.calories,
        proteinG: proteinG ?? currentEntry.proteinG,
        carbsG: carbsG ?? currentEntry.carbsG,
        fatG: fatG ?? currentEntry.fatG,
      );

      final response = await _client
          .from('nutrition_entries')
          .update(updateData)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return NutritionEntry.fromMap(response);
    });
  }

  /// Optimistic update - immediately returns updated entry, then syncs with server
  Future<NutritionEntry> updateEntryOptimistic(String id, {
    String? foodName,
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatG,
    DateTime? time,
    Function(NutritionEntry)? onOptimisticUpdate,
    Function(Exception)? onError,
  }) async {
    try {
      // Get current entry
      final currentEntry = await getEntryById(id);
      if (currentEntry == null) {
        throw const NutritionRepositoryException('Entry not found', 'NOT_FOUND');
      }

      // Create optimistic update
      final optimisticEntry = currentEntry.copyWith(
        foodName: foodName,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        time: time,
      );

      // Immediately notify UI with optimistic update
      onOptimisticUpdate?.call(optimisticEntry);

      // Perform actual update in background
      final updatedEntry = await updateEntry(
        id,
        foodName: foodName,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        time: time,
      );

      return updatedEntry;
    } catch (e) {
      onError?.call(e is Exception ? e : Exception(e.toString()));
      rethrow;
    }
  }

  // DELETE operations with optimistic updates
  Future<void> deleteEntry(String id) async {
    return _handleDatabaseOperation(() async {
      final userId = await _getCurrentUserId();
      await _client
          .from('nutrition_entries')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    });
  }

  /// Optimistic delete - immediately removes from UI, then syncs with server
  Future<void> deleteEntryOptimistic(String id, {
    Function()? onOptimisticDelete,
    Function(Exception)? onError,
    Function()? onUndo,
  }) async {
    NutritionEntry? deletedEntry;
    
    try {
      // Get entry before deletion for potential undo
      deletedEntry = await getEntryById(id);
      
      // Immediately notify UI of deletion
      onOptimisticDelete?.call();

      // Perform actual deletion
      await deleteEntry(id);
    } catch (e) {
      // If deletion fails, restore the entry in UI
      if (deletedEntry != null && onUndo != null) {
        onUndo();
      }
      onError?.call(e is Exception ? e : Exception(e.toString()));
      rethrow;
    }
  }

  /// Undo delete operation by recreating the entry
  Future<NutritionEntry> undoDelete(NutritionEntry deletedEntry) async {
    return createEntry(
      foodName: deletedEntry.foodName,
      calories: deletedEntry.calories,
      proteinG: deletedEntry.proteinG,
      carbsG: deletedEntry.carbsG,
      fatG: deletedEntry.fatG,
      time: deletedEntry.time,
    );
  }

  Future<int> deleteEntriesByIds(List<String> ids) async {
    return _handleDatabaseOperation(() async {
      final userId = await _getCurrentUserId();
      final response = await _client
          .from('nutrition_entries')
          .delete()
          .eq('user_id', userId)
          .inFilter('id', ids)
          .select('id');
      
      return response.length;
    });
  }

  Future<int> deleteEntriesByDateRange(DateTime startDate, DateTime endDate) async {
    return _handleDatabaseOperation(() async {
      final userId = await _getCurrentUserId();
      final response = await _client
          .from('nutrition_entries')
          .delete()
          .eq('user_id', userId)
          .gte('time', startDate.toIso8601String())
          .lt('time', endDate.toIso8601String())
          .select('id');
      
      return response.length;
    });
  }

  // BULK operations
  Future<List<NutritionEntry>> createBulkEntries(List<Map<String, dynamic>> entries) async {
    return _handleDatabaseOperation(() async {
      final userId = await _getCurrentUserId();
      
      // Validate all entries first
      for (final entry in entries) {
        _validateEntry(
          foodName: entry['food_name'] ?? '',
          calories: entry['calories'] ?? 0,
          proteinG: entry['protein_g'] ?? 0,
          carbsG: entry['carbs_g'] ?? 0,
          fatG: entry['fat_g'] ?? 0,
        );
      }

      // Add user_id and timestamp to all entries
      final entriesWithUserId = entries.map((entry) => {
        ...entry,
        'user_id': userId,
        'time': entry['time'] ?? DateTime.now().toIso8601String(),
        'food_name': (entry['food_name'] as String?)?.trim() ?? '',
      }).toList();

      final response = await _client
          .from('nutrition_entries')
          .insert(entriesWithUserId)
          .select();

      return response.map((row) => NutritionEntry.fromMap(row)).toList();
    });
  }

  // DATA EXPORT functionality
  Future<String> exportToJson({DateTime? startDate, DateTime? endDate}) async {
    return _handleDatabaseOperation(() async {
      final entries = await getEntriesByDateRange(
        startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate ?? DateTime.now().add(const Duration(days: 1)),
      );

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'date_range': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
        'total_entries': entries.length,
        'entries': entries.map((entry) => entry.toMap()).toList(),
      };

      return jsonEncode(exportData);
    });
  }

  Future<String> exportToCsv({DateTime? startDate, DateTime? endDate}) async {
    return _handleDatabaseOperation(() async {
      final entries = await getEntriesByDateRange(
        startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate ?? DateTime.now().add(const Duration(days: 1)),
      );

      final csvBuffer = StringBuffer();
      // CSV Header
      csvBuffer.writeln('Date,Time,Food Name,Calories,Protein (g),Carbs (g),Fat (g)');
      
      // CSV Data
      for (final entry in entries) {
        final time = entry.time;
        csvBuffer.writeln(
          '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')},' +
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')},' +
          '"${entry.foodName.replaceAll('"', '""')}",' +
          '${entry.calories},' +
          '${entry.proteinG},' +
          '${entry.carbsG},' +
          '${entry.fatG}'
        );
      }

      return csvBuffer.toString();
    });
  }

  Future<File> saveExportToFile(String data, String filename) async {
    return _handleDatabaseOperation(() async {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(data);
      return file;
    });
  }

  // OFFLINE SYNC functionality
  // Offline storage and sync functionality
  static const String _offlineEntriesKey = 'offline_nutrition_entries';
  static const String _pendingOperationsKey = 'pending_operations';
  
  /// Save entry to offline storage
  Future<void> _saveOfflineEntry(NutritionEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineEntries = await _getOfflineEntries();
      
      // Add or update entry in offline storage
      final existingIndex = offlineEntries.indexWhere((e) => e.id == entry.id);
      if (existingIndex >= 0) {
        offlineEntries[existingIndex] = entry;
      } else {
        offlineEntries.add(entry);
      }
      
      final entriesJson = offlineEntries.map((e) => e.toMap()).toList();
      await prefs.setString(_offlineEntriesKey, jsonEncode(entriesJson));
    } catch (e) {
      print('Error saving offline entry: $e');
    }
  }
  
  /// Get offline entries from local storage
  Future<List<NutritionEntry>> _getOfflineEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_offlineEntriesKey);
      
      if (entriesJson == null) return [];
      
      final List<dynamic> entriesList = jsonDecode(entriesJson);
      return entriesList.map((json) => NutritionEntry.fromMap(json)).toList();
    } catch (e) {
      print('Error getting offline entries: $e');
      return [];
    }
  }
  
  /// Save pending operation for later sync
  Future<void> _savePendingOperation(Map<String, dynamic> operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOps = await _getPendingOperations();
      
      pendingOps.add({
        ...operation,
        'timestamp': DateTime.now().toIso8601String(),
        'id': const Uuid().v4(),
      });
      
      await prefs.setString(_pendingOperationsKey, jsonEncode(pendingOps));
    } catch (e) {
      print('Error saving pending operation: $e');
    }
  }
  
  /// Get pending operations from local storage
  Future<List<Map<String, dynamic>>> _getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final opsJson = prefs.getString(_pendingOperationsKey);
      
      if (opsJson == null) return [];
      
      final List<dynamic> opsList = jsonDecode(opsJson);
      return opsList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting pending operations: $e');
      return [];
    }
  }
  
  /// Clear pending operations after successful sync
  Future<void> _clearPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingOperationsKey);
    } catch (e) {
      print('Error clearing pending operations: $e');
    }
  }
  
  /// Enhanced create entry with offline support
  Future<NutritionEntry> createEntryWithOfflineSupport(NutritionEntry entry) async {
    final isOnline = await checkConnection();
    
    if (isOnline) {
      try {
        // Try online creation first
        return await createEntry(
          foodName: entry.foodName,
          calories: entry.calories,
          proteinG: entry.proteinG,
          carbsG: entry.carbsG,
          fatG: entry.fatG,
          time: entry.time,
        );
      } catch (e) {
        print('Online creation failed, falling back to offline: $e');
        // Fall back to offline storage
        await _saveOfflineEntry(entry);
        await _savePendingOperation({
          'type': 'create',
          'entry': entry.toMap(),
        });
        return entry;
      }
    } else {
      // Save to offline storage
      await _saveOfflineEntry(entry);
      await _savePendingOperation({
        'type': 'create',
        'entry': entry.toMap(),
      });
      return entry;
    }
  }
  
  /// Enhanced update entry with offline support
  Future<NutritionEntry> updateEntryWithOfflineSupport(NutritionEntry entry) async {
    final isOnline = await checkConnection();
    
    if (isOnline) {
      try {
        // Try online update first
        return await updateEntry(
          entry.id,
          foodName: entry.foodName,
          calories: entry.calories,
          proteinG: entry.proteinG,
          carbsG: entry.carbsG,
          fatG: entry.fatG,
          time: entry.time,
        );
      } catch (e) {
        print('Online update failed, falling back to offline: $e');
        // Fall back to offline storage
        await _saveOfflineEntry(entry);
        await _savePendingOperation({
          'type': 'update',
          'entry': entry.toMap(),
        });
        return entry;
      }
    } else {
      // Save to offline storage
      await _saveOfflineEntry(entry);
      await _savePendingOperation({
        'type': 'update',
        'entry': entry.toMap(),
      });
      return entry;
    }
  }
  
  /// Enhanced delete entry with offline support
  Future<void> deleteEntryWithOfflineSupport(String entryId) async {
    final isOnline = await checkConnection();
    
    if (isOnline) {
      try {
        // Try online deletion first
        await deleteEntry(entryId);
        return;
      } catch (e) {
        print('Online deletion failed, falling back to offline: $e');
        // Fall back to offline storage
        await _savePendingOperation({
          'type': 'delete',
          'entryId': entryId,
        });
      }
    } else {
      // Save delete operation for later sync
      await _savePendingOperation({
        'type': 'delete',
        'entryId': entryId,
      });
    }
  }
  
  /// Get entries with offline fallback
  Future<List<NutritionEntry>> getEntriesWithOfflineSupport({DateTime? date}) async {
    final isOnline = await checkConnection();
    
    if (isOnline) {
      try {
        // Try to get online data first
        final onlineEntries = await getTodayEntries();
        
        // Merge with offline entries (offline takes precedence for conflicts)
        final offlineEntries = await _getOfflineEntries();
        final mergedEntries = <String, NutritionEntry>{};
        
        // Add online entries first
        for (final entry in onlineEntries) {
          mergedEntries[entry.id] = entry;
        }
        
        // Override with offline entries (more recent)
        for (final entry in offlineEntries) {
          mergedEntries[entry.id] = entry;
        }
        
        return mergedEntries.values.toList();
      } catch (e) {
        print('Failed to get online entries, using offline: $e');
        return await _getOfflineEntries();
      }
    } else {
      // Return offline entries only
      return await _getOfflineEntries();
    }
  }
  
  Future<void> syncOfflineData() async {
    try {
      final isOnline = await checkConnection();
      if (!isOnline) {
        print('Cannot sync: device is offline');
        return;
      }
      
      final pendingOps = await _getPendingOperations();
      if (pendingOps.isEmpty) {
        print('No pending operations to sync');
        return;
      }
      
      print('Syncing ${pendingOps.length} pending operations...');
      
      // Process pending operations in chronological order
      pendingOps.sort((a, b) => 
        (a['timestamp'] as String).compareTo(b['timestamp'] as String));
      
      for (final op in pendingOps) {
        try {
          switch (op['type']) {
            case 'create':
              final entry = NutritionEntry.fromMap(op['entry']);
              await createEntry(
                foodName: entry.foodName,
                calories: entry.calories,
                proteinG: entry.proteinG,
                carbsG: entry.carbsG,
                fatG: entry.fatG,
                time: entry.time,
              );
              break;
            case 'update':
              final entry = NutritionEntry.fromMap(op['entry']);
              await updateEntry(
                entry.id,
                foodName: entry.foodName,
                calories: entry.calories,
                proteinG: entry.proteinG,
                carbsG: entry.carbsG,
                fatG: entry.fatG,
                time: entry.time,
              );
              break;
            case 'delete':
              await deleteEntry(op['entryId']);
              break;
          }
        } catch (e) {
          print('Failed to sync operation ${op['type']}: $e');
          // Continue with other operations even if one fails
        }
      }
      
      // Clear pending operations after successful sync
      await _clearPendingOperations();
      
      // Clear offline entries as they're now synced
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineEntriesKey);
      
      print('Offline sync completed successfully');
    } catch (e) {
      print('Error during offline sync: $e');
    }
  }
  
  /// Auto-sync when connection is restored
  void startAutoSync() {
    watchConnectionStatus().listen((isConnected) {
      if (isConnected) {
        // Delay sync to ensure connection is stable
        Future.delayed(const Duration(seconds: 2), () {
          syncOfflineData();
        });
      }
    });
  }
  
  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final pendingOps = await _getPendingOperations();
    final offlineEntries = await _getOfflineEntries();
    final isOnline = await checkConnection();
    
    return {
      'isOnline': isOnline,
      'pendingOperations': pendingOps.length,
      'offlineEntries': offlineEntries.length,
      'lastSyncAttempt': DateTime.now().toIso8601String(),
    };
  }

  // STATISTICS and ANALYTICS
  Future<Map<String, dynamic>> getNutritionStats({DateTime? startDate, DateTime? endDate}) async {
    return _handleDatabaseOperation(() async {
      final entries = await getEntriesByDateRange(
        startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        endDate ?? DateTime.now().add(const Duration(days: 1)),
      );

      if (entries.isEmpty) {
        return {
          'total_entries': 0,
          'total_calories': 0,
          'total_protein': 0,
          'total_carbs': 0,
          'total_fat': 0,
          'average_calories_per_day': 0.0,
          'days_tracked': 0,
        };
      }

      final totalCalories = entries.fold<int>(0, (sum, entry) => sum + entry.calories);
      final totalProtein = entries.fold<int>(0, (sum, entry) => sum + entry.proteinG);
      final totalCarbs = entries.fold<int>(0, (sum, entry) => sum + entry.carbsG);
      final totalFat = entries.fold<int>(0, (sum, entry) => sum + entry.fatG);

      // Calculate unique days
      final uniqueDays = entries
          .map((entry) => DateTime(entry.time.year, entry.time.month, entry.time.day))
          .toSet()
          .length;

      return {
        'total_entries': entries.length,
        'total_calories': totalCalories,
        'total_protein': totalProtein,
        'total_carbs': totalCarbs,
        'total_fat': totalFat,
        'average_calories_per_day': uniqueDays > 0 ? totalCalories / uniqueDays : 0.0,
        'days_tracked': uniqueDays,
      };
    });
  }

  /// Search nutrition entries by food name
  Future<List<NutritionEntry>> searchEntries(String query, {int limit = 50}) async {
    return _handleDatabaseOperation(() async {
      final userId = await _getCurrentUserId();
      final response = await _client
          .from('nutrition_entries')
          .select()
          .eq('user_id', userId)
          .ilike('food_name', '%$query%')
          .order('time', ascending: false)
          .limit(limit);

      return response.map((row) => NutritionEntry.fromMap(row)).toList();
    });
  }

  Future<List<NutritionEntry>> getTodayEntries() async {
    return _handleDatabaseOperation(() async {
      final userId = await _getCurrentUserId();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('nutrition_entries')
          .select()
          .eq('user_id', userId)
          .gte('time', startOfDay.toIso8601String())
          .lt('time', endOfDay.toIso8601String())
          .order('time', ascending: false);

      return response.map((row) => NutritionEntry.fromMap(row)).toList();
    });
  }

// Stream extensions removed to fix compilation issues

}

// Providers with enhanced error handling - moved outside class
final nutritionRepoProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository();
});

final nutritionEntriesProvider = StreamProvider<List<NutritionEntry>>((ref) {
  final repo = ref.read(nutritionRepoProvider);
  return repo.watchEntries().handleError((error, stackTrace) {
    print('Nutrition entries stream error: $error');
    // Return empty list on error to prevent UI crashes
    return <NutritionEntry>[];
  });
});

final nutritionTodayProvider = FutureProvider<List<NutritionEntry>>((ref) {
  final repo = ref.read(nutritionRepoProvider);
  return repo.getTodayEntries().catchError((error) {
    print('Today entries error: $error');
    return <NutritionEntry>[];
  });
});

final nutritionTotalsProvider = StreamProvider<NutritionTotals>((ref) {
  final repo = ref.read(nutritionRepoProvider);
  return repo.watchToday().handleError((error, stackTrace) {
    print('Nutrition totals stream error: $error');
    return const NutritionTotals();
  });
});

final connectionStatusProvider = StreamProvider<bool>((ref) {
  final repo = ref.read(nutritionRepoProvider);
  return repo.watchConnectionStatus();
});

final syncStatusProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repo = ref.read(nutritionRepoProvider);
  return repo.getSyncStatus().catchError((error) {
    print('Sync status error: $error');
    return {
      'isOnline': false,
      'pendingOperations': 0,
      'offlineEntries': 0,
      'lastSyncAttempt': DateTime.now().toIso8601String(),
    };
  });
});
