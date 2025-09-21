import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'data/profile_repository.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  bool _isExporting = false;
  bool _isClearing = false;
  
  final Map<String, bool> _selectedDataTypes = {
    'profile': true,
    'measurements': true,
    'photos': true,
    'workouts': true,
    'nutrition': true,
    'goals': true,
    'preferences': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Management'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExportSection(),
          const SizedBox(height: 24),
          _buildImportSection(),
          const SizedBox(height: 24),
          _buildBackupSection(),
          const SizedBox(height: 24),
          _buildClearDataSection(),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.download, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Export Data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Export your data to share with other apps or create backups.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select data to export:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._selectedDataTypes.entries.map(
              (entry) => CheckboxListTile(
                title: Text(_getDataTypeDisplayName(entry.key)),
                subtitle: Text(_getDataTypeDescription(entry.key)),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    _selectedDataTypes[entry.key] = value ?? false;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : () => _exportData('json'),
                    icon: _isExporting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.fileText),
                    label: const Text('Export as JSON'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : () => _exportData('csv'),
                    icon: _isExporting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.table),
                    label: const Text('Export as CSV'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.upload, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Import Data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Import data from other fitness apps or restore from backups.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _importData,
                icon: const Icon(LucideIcons.folderOpen),
                label: const Text('Select File to Import'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showImportFromAppDialog(),
                    icon: const Icon(LucideIcons.smartphone),
                    label: const Text('From Health App'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showImportFromAppDialog(),
                    icon: const Icon(LucideIcons.activity),
                    label: const Text('From Fitness App'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.shield, color: Colors.purple),
                const SizedBox(width: 12),
                Text(
                  'Backup & Restore',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Create automatic backups and restore your data when needed.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createBackup,
                    icon: const Icon(LucideIcons.save),
                    label: const Text('Create Backup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _restoreBackup,
                    icon: const Icon(LucideIcons.rotateCcw),
                    label: const Text('Restore Backup'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto Backup'),
              subtitle: const Text('Automatically backup data weekly'),
              value: true, // This would come from preferences
              onChanged: (value) {
                // Handle auto backup toggle
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.trash2, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'Clear Data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Permanently delete specific categories of your data.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showClearDataDialog('workouts'),
                    icon: const Icon(LucideIcons.dumbbell, color: Colors.orange),
                    label: const Text('Clear Workouts'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showClearDataDialog('nutrition'),
                    icon: const Icon(LucideIcons.apple, color: Colors.orange),
                    label: const Text('Clear Nutrition'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showClearDataDialog('measurements'),
                    icon: const Icon(LucideIcons.scale, color: Colors.orange),
                    label: const Text('Clear Measurements'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showClearDataDialog('photos'),
                    icon: const Icon(LucideIcons.camera, color: Colors.orange),
                    label: const Text('Clear Photos'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isClearing ? null : () => _showClearAllDataDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: _isClearing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(LucideIcons.alertTriangle),
                label: const Text('Clear All Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDataTypeDisplayName(String key) {
    switch (key) {
      case 'profile':
        return 'Profile Information';
      case 'measurements':
        return 'Body Measurements';
      case 'photos':
        return 'Progress Photos';
      case 'workouts':
        return 'Workout History';
      case 'nutrition':
        return 'Nutrition Data';
      case 'goals':
        return 'Goals & Targets';
      case 'preferences':
        return 'App Preferences';
      default:
        return key;
    }
  }

  String _getDataTypeDescription(String key) {
    switch (key) {
      case 'profile':
        return 'Name, bio, avatar, and basic info';
      case 'measurements':
        return 'Weight, body fat, measurements';
      case 'photos':
        return 'Progress and comparison photos';
      case 'workouts':
        return 'Exercise logs and performance';
      case 'nutrition':
        return 'Meal logs and calorie tracking';
      case 'goals':
        return 'Fitness goals and achievements';
      case 'preferences':
        return 'App settings and preferences';
      default:
        return '';
    }
  }

  Future<void> _exportData(String format) async {
    setState(() => _isExporting = true);

    try {
      final selectedTypes = _selectedDataTypes.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (selectedTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one data type to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final exportData = await ref.read(profileRepositoryProvider).exportUserData();
      
      String content;
      String fileName;
      
      if (format == 'json') {
        content = jsonEncode(exportData);
        fileName = 'fitai_export_${DateTime.now().millisecondsSinceEpoch}.json';
      } else {
        content = _convertToCSV(exportData);
        fileName = 'fitai_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      }

      await Share.shareXFiles(
        [XFile.fromData(
          Uint8List.fromList(content.codeUnits),
          name: fileName,
          mimeType: format == 'json' ? 'application/json' : 'text/csv',
        )],
        text: 'FitAI Data Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
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
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _convertToCSV(Map<String, dynamic> data) {
    // Simple CSV conversion - in a real app, this would be more sophisticated
    final buffer = StringBuffer();
    
    data.forEach((key, value) {
      buffer.writeln('$key,$value');
    });
    
    return buffer.toString();
  }

  Future<void> _importData() async {
    // In a real app, this would use file_picker to select and import files
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showImportFromAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from App'),
        content: const Text(
          'This feature will allow you to import data from popular fitness apps like Apple Health, Google Fit, MyFitnessPal, and more.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    try {
      await ref.read(profileRepositoryProvider).createBackup();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    // Show backup selection dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restore functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showClearDataDialog(String dataType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear ${_getDataTypeDisplayName(dataType)}?'),
        content: Text(
          'This will permanently delete all ${_getDataTypeDisplayName(dataType).toLowerCase()}. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearSpecificData(dataType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete ALL your data including profile, workouts, nutrition, measurements, and photos. This action cannot be undone.\n\nAre you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearSpecificData(String dataType) async {
    setState(() => _isClearing = true);

    try {
      await ref.read(profileRepositoryProvider).clearSpecificData(dataType);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getDataTypeDisplayName(dataType)} cleared successfully'),
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
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  Future<void> _clearAllData() async {
    setState(() => _isClearing = true);

    try {
      await ref.read(profileRepositoryProvider).clearAllUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to avoid staying on empty screen
        Navigator.of(context).pop();
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
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }
}