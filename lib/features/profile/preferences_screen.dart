import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'data/profile_repository.dart';

enum ThemeMode { light, dark, system }
enum UnitSystem { metric, imperial }

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  ThemeMode _selectedTheme = ThemeMode.system;
  UnitSystem _selectedUnits = UnitSystem.metric;
  bool _workoutReminders = true;
  bool _mealReminders = true;
  bool _progressUpdates = true;
  bool _socialNotifications = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await ref.read(profileRepositoryProvider).getUserPreferences();
      if (prefs != null && mounted) {
        setState(() {
          _selectedTheme = _parseThemeMode(prefs['theme'] as String?);
          _selectedUnits = _parseUnitSystem(prefs['units'] as String?);
          _workoutReminders = prefs['workout_reminders'] as bool? ?? true;
          _mealReminders = prefs['meal_reminders'] as bool? ?? true;
          _progressUpdates = prefs['progress_updates'] as bool? ?? true;
          _socialNotifications = prefs['social_notifications'] as bool? ?? false;
          _emailNotifications = prefs['email_notifications'] as bool? ?? true;
          _pushNotifications = prefs['push_notifications'] as bool? ?? true;
        });
      }
    } catch (e) {
      // Handle error silently or show a snackbar
    }
  }

  ThemeMode _parseThemeMode(String? theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  UnitSystem _parseUnitSystem(String? units) {
    switch (units) {
      case 'imperial':
        return UnitSystem.imperial;
      default:
        return UnitSystem.metric;
    }
  }

  Future<void> _savePreferences() async {
    try {
      await ref.read(profileRepositoryProvider).updateUserPreferences({
        'theme': _selectedTheme.name,
        'units': _selectedUnits.name,
        'workout_reminders': _workoutReminders,
        'meal_reminders': _mealReminders,
        'progress_updates': _progressUpdates,
        'social_notifications': _socialNotifications,
        'email_notifications': _emailNotifications,
        'push_notifications': _pushNotifications,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _savePreferences,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.palette),
                      const SizedBox(width: 8),
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    subtitle: const Text('Always use light theme'),
                    value: ThemeMode.light,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      setState(() => _selectedTheme = value!);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    subtitle: const Text('Always use dark theme'),
                    value: ThemeMode.dark,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      setState(() => _selectedTheme = value!);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('System'),
                    subtitle: const Text('Follow system theme'),
                    value: ThemeMode.system,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      setState(() => _selectedTheme = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Units Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.ruler),
                      const SizedBox(width: 8),
                      Text(
                        'Units',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<UnitSystem>(
                    title: const Text('Metric'),
                    subtitle: const Text('kg, cm, km'),
                    value: UnitSystem.metric,
                    groupValue: _selectedUnits,
                    onChanged: (value) {
                      setState(() => _selectedUnits = value!);
                    },
                  ),
                  RadioListTile<UnitSystem>(
                    title: const Text('Imperial'),
                    subtitle: const Text('lbs, ft/in, miles'),
                    value: UnitSystem.imperial,
                    groupValue: _selectedUnits,
                    onChanged: (value) {
                      setState(() => _selectedUnits = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Notifications Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.bell),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive notifications on your device'),
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() => _pushNotifications = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive notifications via email'),
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() => _emailNotifications = value);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Workout Reminders'),
                    subtitle: const Text('Get reminded about your workouts'),
                    value: _workoutReminders,
                    onChanged: (value) {
                      setState(() => _workoutReminders = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Meal Reminders'),
                    subtitle: const Text('Get reminded to log your meals'),
                    value: _mealReminders,
                    onChanged: (value) {
                      setState(() => _mealReminders = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Progress Updates'),
                    subtitle: const Text('Weekly progress summaries'),
                    value: _progressUpdates,
                    onChanged: (value) {
                      setState(() => _progressUpdates = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Social Notifications'),
                    subtitle: const Text('Friend activities and achievements'),
                    value: _socialNotifications,
                    onChanged: (value) {
                      setState(() => _socialNotifications = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Privacy Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.shield),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy & Data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(LucideIcons.download),
                    title: const Text('Export Data'),
                    subtitle: const Text('Download all your data'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () async {
                      try {
                        await ref.read(profileRepositoryProvider).exportUserData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data export initiated. Check your email.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Export failed: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.trash2),
                    title: const Text('Clear Data'),
                    subtitle: const Text('Remove specific data categories'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      _showClearDataDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select data categories to clear:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LucideIcons.dumbbell),
              title: const Text('Workout Data'),
              onTap: () => _clearDataCategory('workouts'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.utensils),
              title: const Text('Nutrition Data'),
              onTap: () => _clearDataCategory('nutrition'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.trendingUp),
              title: const Text('Progress Data'),
              onTap: () => _clearDataCategory('progress'),
            ),
          ],
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

  Future<void> _clearDataCategory(String category) async {
    Navigator.of(context).pop(); // Close dialog
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear ${category.toUpperCase()} Data'),
        content: Text('Are you sure you want to clear all $category data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(profileRepositoryProvider).clearDataCategory(category);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${category.toUpperCase()} data cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear data: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}