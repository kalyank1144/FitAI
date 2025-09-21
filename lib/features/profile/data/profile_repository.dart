import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;

// Data Models
class UserProfile {
  final String id;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final String? fitnessGoal;
  final String? activityLevel;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.fullName,
    this.bio,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.fitnessGoal,
    this.activityLevel,
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth'] as String) 
          : null,
      gender: json['gender'] as String?,
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      fitnessGoal: json['fitness_goal'] as String?,
      activityLevel: json['activity_level'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'fitness_goal': fitnessGoal,
      'activity_level': activityLevel,
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? bio,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? fitnessGoal,
    String? activityLevel,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class BodyMeasurement {
  final String id;
  final String userId;
  final double? weight;
  final double? bodyFat;
  final double? muscleMass;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? biceps;
  final double? thighs;
  final String? notes;
  final DateTime recordedAt;
  final DateTime createdAt;

  const BodyMeasurement({
    required this.id,
    required this.userId,
    this.weight,
    this.bodyFat,
    this.muscleMass,
    this.chest,
    this.waist,
    this.hips,
    this.biceps,
    this.thighs,
    this.notes,
    required this.recordedAt,
    required this.createdAt,
  });

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weight: json['weight']?.toDouble(),
      bodyFat: json['body_fat']?.toDouble(),
      muscleMass: json['muscle_mass']?.toDouble(),
      chest: json['chest']?.toDouble(),
      waist: json['waist']?.toDouble(),
      hips: json['hips']?.toDouble(),
      biceps: json['biceps']?.toDouble(),
      thighs: json['thighs']?.toDouble(),
      notes: json['notes'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'weight': weight,
      'body_fat': bodyFat,
      'muscle_mass': muscleMass,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'biceps': biceps,
      'thighs': thighs,
      'notes': notes,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProgressPhoto {
  final String id;
  final String userId;
  final String imageUrl;
  final String? description;
  final String category; // 'front', 'side', 'back'
  final DateTime takenAt;
  final DateTime createdAt;

  const ProgressPhoto({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.description,
    required this.category,
    required this.takenAt,
    required this.createdAt,
  });

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    return ProgressPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      takenAt: DateTime.parse(json['taken_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'description': description,
      'category': category,
      'taken_at': takenAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Custom Exceptions
class ProfileException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const ProfileException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'ProfileException: $message';
}

// Profile Repository
class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  // Profile Management
  Stream<UserProfile?> watchProfile() {
    final userId = _currentUserId;
    if (userId == null) return const Stream.empty();
    
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .limit(1)
        .map((rows) => rows.isEmpty ? null : UserProfile.fromJson(rows.first))
        .handleError((error) {
      throw ProfileException('Failed to watch profile', originalError: error);
    });
  }

  Future<UserProfile?> getProfile() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response != null ? UserProfile.fromJson(response) : null;
    } catch (e) {
      throw ProfileException('Failed to get profile', originalError: e);
    }
  }

  Future<UserProfile> createProfile({
    required String fullName,
    String? bio,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? fitnessGoal,
    String? activityLevel,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      final now = DateTime.now();
      final profileData = {
        'id': userId,
        'full_name': fullName,
        'bio': bio,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'height': height,
        'weight': weight,
        'fitness_goal': fitnessGoal,
        'activity_level': activityLevel,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _client
          .from('profiles')
          .insert(profileData)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw ProfileException('Failed to create profile', originalError: e);
    }
  }

  Future<UserProfile> updateProfile({
    String? fullName,
    String? bio,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? fitnessGoal,
    String? activityLevel,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (bio != null) updateData['bio'] = bio;
      if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      if (gender != null) updateData['gender'] = gender;
      if (height != null) updateData['height'] = height;
      if (weight != null) updateData['weight'] = weight;
      if (fitnessGoal != null) updateData['fitness_goal'] = fitnessGoal;
      if (activityLevel != null) updateData['activity_level'] = activityLevel;
      if (preferences != null) updateData['preferences'] = preferences;

      final response = await _client
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw ProfileException('Failed to update profile', originalError: e);
    }
  }

  // Avatar Management
  Future<String> uploadAvatar(Uint8List imageBytes, String fileName) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      // Compress image
      final compressedBytes = await _compressImage(imageBytes);
      
      final path = 'avatars/$userId/$fileName';
      
      await _client.storage
          .from('profiles')
          .uploadBinary(path, compressedBytes, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ));

      final publicUrl = _client.storage
          .from('profiles')
          .getPublicUrl(path);

      // Update profile with new avatar URL
      await updateProfile();
      await _client
          .from('profiles')
          .update({'avatar_url': publicUrl, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      throw ProfileException('Failed to upload avatar', originalError: e);
    }
  }

  Future<void> deleteAvatar() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      // Remove avatar URL from profile
      await _client
          .from('profiles')
          .update({'avatar_url': null, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      // Delete from storage
      final files = await _client.storage
          .from('profiles')
          .list(path: 'avatars/$userId');
      
      if (files.isNotEmpty) {
        final filePaths = files.map((file) => 'avatars/$userId/${file.name}').toList();
        await _client.storage
            .from('profiles')
            .remove(filePaths);
      }
    } catch (e) {
      throw ProfileException('Failed to delete avatar', originalError: e);
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) throw const ProfileException('Invalid image format');

      // Resize to max 512x512 while maintaining aspect ratio
      final resized = img.copyResize(image, width: 512, height: 512, maintainAspect: true);
      
      // Compress as JPEG with 85% quality
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (e) {
      throw ProfileException('Failed to compress image', originalError: e);
    }
  }

  // Body Measurements
  Stream<List<BodyMeasurement>> watchBodyMeasurements() {
    final userId = _currentUserId;
    if (userId == null) return const Stream.empty();
    
    return _client
        .from('body_measurements')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('recorded_at', ascending: false)
        .map((rows) => rows.map((row) => BodyMeasurement.fromJson(row)).toList())
        .handleError((error) {
      throw ProfileException('Failed to watch body measurements', originalError: error);
    });
  }

  Future<BodyMeasurement> addBodyMeasurement({
    double? weight,
    double? bodyFat,
    double? muscleMass,
    double? chest,
    double? waist,
    double? hips,
    double? biceps,
    double? thighs,
    String? notes,
    DateTime? recordedAt,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      final measurementData = {
        'user_id': userId,
        'weight': weight,
        'body_fat': bodyFat,
        'muscle_mass': muscleMass,
        'chest': chest,
        'waist': waist,
        'hips': hips,
        'biceps': biceps,
        'thighs': thighs,
        'notes': notes,
        'recorded_at': (recordedAt ?? DateTime.now()).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('body_measurements')
          .insert(measurementData)
          .select()
          .single();

      return BodyMeasurement.fromJson(response);
    } catch (e) {
      throw ProfileException('Failed to add body measurement', originalError: e);
    }
  }

  Future<void> deleteBodyMeasurement(String measurementId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      await _client
          .from('body_measurements')
          .delete()
          .eq('id', measurementId)
          .eq('user_id', userId);
    } catch (e) {
      throw ProfileException('Failed to delete body measurement', originalError: e);
    }
  }

  // Progress Photos
  Stream<List<ProgressPhoto>> watchProgressPhotos() {
    final userId = _currentUserId;
    if (userId == null) return const Stream.empty();
    
    return _client
        .from('progress_photos')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('taken_at', ascending: false)
        .map((rows) => rows.map((row) => ProgressPhoto.fromJson(row)).toList())
        .handleError((error) {
      throw ProfileException('Failed to watch progress photos', originalError: error);
    });
  }

  Future<ProgressPhoto> addProgressPhoto({
    required Uint8List imageBytes,
    required String fileName,
    required String category,
    String? description,
    DateTime? takenAt,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      // Compress and upload image
      final compressedBytes = await _compressImage(imageBytes);
      final path = 'progress_photos/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await _client.storage
          .from('profiles')
          .uploadBinary(path, compressedBytes, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ));

      final publicUrl = _client.storage
          .from('profiles')
          .getPublicUrl(path);

      // Save photo record
      final photoData = {
        'user_id': userId,
        'image_url': publicUrl,
        'description': description,
        'category': category,
        'taken_at': (takenAt ?? DateTime.now()).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('progress_photos')
          .insert(photoData)
          .select()
          .single();

      return ProgressPhoto.fromJson(response);
    } catch (e) {
      throw ProfileException('Failed to add progress photo', originalError: e);
    }
  }

  Future<void> deleteProgressPhoto(String photoId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      // Get photo details first
      final photo = await _client
          .from('progress_photos')
          .select()
          .eq('id', photoId)
          .eq('user_id', userId)
          .single();

      // Delete from storage
      final imageUrl = photo['image_url'] as String;
      final path = imageUrl.split('/').last;
      await _client.storage
          .from('profiles')
          .remove(['progress_photos/$userId/$path']);

      // Delete record
      await _client
          .from('progress_photos')
          .delete()
          .eq('id', photoId)
          .eq('user_id', userId);
    } catch (e) {
      throw ProfileException('Failed to delete progress photo', originalError: e);
    }
  }

  // Account Management
  Future<void> updateEmail(String newEmail) async {
    try {
      await _client.auth.updateUser(UserAttributes(email: newEmail));
    } catch (e) {
      throw ProfileException('Failed to update email', originalError: e);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw ProfileException('Failed to update password', originalError: e);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      // First verify current password by attempting to sign in
      final email = _client.auth.currentUser?.email;
      if (email == null) throw const ProfileException('User not authenticated');
      
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      
      // If successful, update to new password
      await updatePassword(newPassword);
    } catch (e) {
      throw ProfileException('Failed to change password', originalError: e);
    }
  }

  Future<void> clearDataCategory(String category) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      switch (category.toLowerCase()) {
        case 'workouts':
          // Clear workout-related data
          await _client.from('workouts').delete().eq('user_id', userId);
          await _client.from('workout_sessions').delete().eq('user_id', userId);
          break;
        case 'nutrition':
          // Clear nutrition-related data
          await _client.from('nutrition_entries').delete().eq('user_id', userId);
          await _client.from('meal_plans').delete().eq('user_id', userId);
          break;
        case 'progress':
          // Clear progress-related data
          await _client.from('body_measurements').delete().eq('user_id', userId);
          await _client.from('progress_photos').delete().eq('user_id', userId);
          // Also delete progress photo files from storage
          try {
            await _client.storage.from('profiles').remove(['progress_photos/$userId']);
          } catch (e) {
            // Storage deletion errors are not critical
          }
          break;
        default:
          throw ProfileException('Unknown data category: $category');
      }
    } catch (e) {
      throw ProfileException('Failed to clear data category', originalError: e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      // Delete all user data
      await Future.wait([
        _client.from('profiles').delete().eq('id', userId).then((_) => null),
        _client.from('body_measurements').delete().eq('user_id', userId).then((_) => null),
        _client.from('progress_photos').delete().eq('user_id', userId).then((_) => null),
        _client.from('fcm_tokens').delete().eq('user_id', userId).then((_) => null),
      ]);

      // Delete storage files
      try {
        await _client.storage.from('profiles').remove(['avatars/$userId']);
        await _client.storage.from('profiles').remove(['progress_photos/$userId']);
      } catch (e) {
        // Storage deletion errors are not critical
      }

      // Delete auth user (this will sign out the user)
      await _client.auth.admin.deleteUser(userId);
    } catch (e) {
      throw ProfileException('Failed to delete account', originalError: e);
    }
  }

  // Data Export
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      final results = await Future.wait<dynamic>([
        _client.from('profiles').select().eq('id', userId).maybeSingle(),
        _client.from('body_measurements').select().eq('user_id', userId),
        _client.from('progress_photos').select().eq('user_id', userId),
      ]);

      return {
        'profile': results[0],
        'body_measurements': results[1],
        'progress_photos': results[2],
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw ProfileException('Failed to export user data', originalError: e);
    }
  }

  // FCM Token Management
  Future<void> saveFcmToken(String token) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      await _client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': _client.auth.currentSession?.user.userMetadata?['platform'] ?? 'unknown',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ProfileException('Failed to save FCM token', originalError: e);
    }
  }

  // User Preferences Management
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Return default preferences if none exist
        return {
          'theme': 'system',
          'units': 'metric',
          'notifications': {
            'workouts': true,
            'nutrition': true,
            'progress': true,
          },
          'privacy': {
            'profile_visibility': 'private',
            'workout_sharing': false,
          },
        };
      }

      return response['preferences'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      throw ProfileException('Failed to get user preferences', originalError: e);
    }
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      await _client.from('user_preferences').upsert({
        'user_id': userId,
        'preferences': preferences,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ProfileException('Failed to update user preferences', originalError: e);
    }
  }

  // Missing methods for data management
  Future<void> clearSpecificData(String dataType) async {
    await clearDataCategory(dataType);
  }

  Future<void> clearAllUserData() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw const ProfileException('User not authenticated');

      // Clear all data categories
      await Future.wait([
        clearDataCategory('workouts'),
        clearDataCategory('nutrition'),
        clearDataCategory('progress'),
      ]);

      // Clear profile data
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw ProfileException('Failed to clear all user data', originalError: e);
    }
  }

  Future<void> createBackup() async {
    try {
      final data = await exportUserData();
      // In a real implementation, this would save to cloud storage or local file
      // For now, we'll just simulate the backup creation
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw ProfileException('Failed to create backup', originalError: e);
    }
  }
}

// Providers
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.watchProfile();
});

final bodyMeasurementsProvider = StreamProvider<List<BodyMeasurement>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.watchBodyMeasurements();
});

final progressPhotosProvider = StreamProvider<List<ProgressPhoto>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.watchProgressPhotos();
});
