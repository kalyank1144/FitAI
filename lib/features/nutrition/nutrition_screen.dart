import 'package:fitai/core/components/progress_ring.dart';
import 'package:fitai/features/nutrition/data/nutrition_repository.dart';
import 'package:fitai/features/nutrition/ui/quick_add.dart';
import 'package:fitai/features/train/data/offline_workout_manager.dart' as workout;
import 'package:fitai/features/nutrition/services/barcode_scanner_service.dart';
import 'package:fitai/features/nutrition/meal_photo_service.dart';
import 'package:fitai/features/auth/data/auth_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<NutritionEntry> _searchResults = [];
  bool _isLoadingSearch = false;
  String? _errorMessage;
  
  // Bulk operations state
  bool _isSelectionMode = false;
  final Set<String> _selectedEntryIds = {};
  bool _isPerformingBulkOperation = false;
  
  // Search and filter state
  bool _showSearchBar = false;
  String _currentSearchQuery = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  int? _minCalories;
  int? _maxCalories;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Bulk operations methods
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEntryIds.clear();
      }
    });
  }

  void _toggleEntrySelection(String entryId) {
    setState(() {
      if (_selectedEntryIds.contains(entryId)) {
        _selectedEntryIds.remove(entryId);
      } else {
        _selectedEntryIds.add(entryId);
      }
    });
  }

  void _selectAllEntries(List<NutritionEntry> entries) {
    setState(() {
      if (_selectedEntryIds.length == entries.length) {
        _selectedEntryIds.clear();
      } else {
        _selectedEntryIds.clear();
        _selectedEntryIds.addAll(entries.map((e) => e.id));
      }
    });
  }

  Future<void> _bulkDeleteEntries() async {
    if (_selectedEntryIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entries'),
        content: Text(
          'Are you sure you want to delete ${_selectedEntryIds.length} selected entries? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isPerformingBulkOperation = true);
      
      try {
        final repository = ref.read(nutritionRepoProvider);
        await repository.deleteEntriesByIds(_selectedEntryIds.toList());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedEntryIds.length} entries deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          setState(() {
            _selectedEntryIds.clear();
            _isSelectionMode = false;
            _isPerformingBulkOperation = false;
          });
        }
      } catch (e) {
        setState(() => _isPerformingBulkOperation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete entries: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _currentSearchQuery = '';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _currentSearchQuery = query;
    });
    
    try {
      final repository = ref.read(nutritionRepoProvider);
      final results = await repository.searchEntries(query);
      
      // Apply additional filters if set
      List<NutritionEntry> filteredResults = results;
      
      if (_filterStartDate != null || _filterEndDate != null) {
        filteredResults = filteredResults.where((entry) {
          final entryDate = DateTime(entry.time.year, entry.time.month, entry.time.day);
          if (_filterStartDate != null && entryDate.isBefore(_filterStartDate!)) {
            return false;
          }
          if (_filterEndDate != null && entryDate.isAfter(_filterEndDate!)) {
            return false;
          }
          return true;
        }).toList();
      }
      
      if (_minCalories != null || _maxCalories != null) {
        filteredResults = filteredResults.where((entry) {
          if (_minCalories != null && entry.calories < _minCalories!) {
            return false;
          }
          if (_maxCalories != null && entry.calories > _maxCalories!) {
            return false;
          }
          return true;
        }).toList();
      }
      
      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _currentSearchQuery = '';
    });
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        initialStartDate: _filterStartDate,
        initialEndDate: _filterEndDate,
        initialMinCalories: _minCalories,
        initialMaxCalories: _maxCalories,
        onApplyFilters: (startDate, endDate, minCalories, maxCalories) {
          setState(() {
            _filterStartDate = startDate;
            _filterEndDate = endDate;
            _minCalories = minCalories;
            _maxCalories = maxCalories;
          });
          
          // Re-run search with new filters if currently searching
          if (_currentSearchQuery.isNotEmpty) {
            _performSearch(_currentSearchQuery);
          }
        },
        onClearFilters: () {
          setState(() {
            _filterStartDate = null;
            _filterEndDate = null;
            _minCalories = null;
            _maxCalories = null;
          });
          
          // Re-run search without filters if currently searching
          if (_currentSearchQuery.isNotEmpty) {
            _performSearch(_currentSearchQuery);
          }
        },
      ),
    );
  }

  Future<void> _deleteEntry(String entryId) async {
    // Show confirmation dialog first
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    NutritionEntry? deletedEntry;
    ScaffoldMessengerState? scaffoldMessenger;
    
    if (mounted) {
      scaffoldMessenger = ScaffoldMessenger.of(context);
    }

    try {
      final repository = ref.read(nutritionRepoProvider);
      
      // Use offline-capable delete with undo functionality
      await repository.deleteEntryWithOfflineSupport(entryId);
      
      // Show success message with undo option
      if (mounted) {
        scaffoldMessenger?.showSnackBar(
          SnackBar(
            content: const Text('Entry deleted'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () async {
                if (deletedEntry != null) {
                  await _undoDelete(deletedEntry!);
                }
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Store deleted entry for potential undo
      deletedEntry = await repository.getEntryById(entryId);
      
      // Refresh search results if searching
      if (_isSearching && _searchQuery.isNotEmpty) {
        _performSearch(_searchQuery);
      }
      
    } catch (e) {
      if (mounted) {
        scaffoldMessenger?.showSnackBar(
          SnackBar(
            content: Text('Failed to delete entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this nutrition entry? This action can be undone for a short time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _undoDelete(NutritionEntry deletedEntry) async {
    try {
      final repository = ref.read(nutritionRepoProvider);
      await repository.undoDelete(deletedEntry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Scan barcode and add nutrition entry
  Future<void> _scanBarcode() async {
    try {
      final authState = ref.read(authStateProvider).value;
      final user = authState?.session?.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to scan barcodes'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final barcodeScannerService = BarcodeScannerService();
      final scannedEntry = await barcodeScannerService.scanBarcodeForNutrition(context, user.id);
      
      if (scannedEntry != null) {
        // Show confirmation dialog with nutrition info
        final confirmed = await _showNutritionConfirmationDialog(scannedEntry);
        
        if (confirmed == true) {
          final repository = ref.read(nutritionRepoProvider);
          await repository.createEntry(
            foodName: scannedEntry.foodName,
            calories: scannedEntry.calories,
            proteinG: scannedEntry.proteinG,
            carbsG: scannedEntry.carbsG,
            fatG: scannedEntry.fatG,
            time: scannedEntry.time,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${scannedEntry.foodName} to your nutrition log'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find nutrition information for this product'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barcode scanning failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show confirmation dialog with scanned nutrition information
  Future<bool?> _showNutritionConfirmationDialog(NutritionEntry entry) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.foodName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition information per 100g:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildNutritionRow('Calories', '${entry.calories} kcal'),
            _buildNutritionRow('Protein', '${entry.proteinG}g'),
            _buildNutritionRow('Carbs', '${entry.carbsG}g'),
            _buildNutritionRow('Fat', '${entry.fatG}g'),
            const SizedBox(height: 12),
            const Text(
              'Add this to your nutrition log?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build nutrition information rows
  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Analyze meal photo and add nutrition entries
  Future<void> _analyzeMealPhoto() async {
    try {
      final authState = ref.read(authStateProvider).value;
      final user = authState?.session?.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to analyze meal photos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final mealPhotoService = MealPhotoService();
      final imageFile = await mealPhotoService.capturePhoto(source: source);
      
      if (imageFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing your meal...'),
              ],
            ),
          ),
        );
      }

      try {
        final analysisResults = await mealPhotoService.analyzeMealPhoto(imageFile);
        
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          // Navigate to analysis results screen
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MealPhotoAnalysisScreen(
                imageFile: imageFile,
                analysisResults: analysisResults,
                onSaveEntries: (entries) async {
                  final repository = ref.read(nutritionRepoProvider);
                  
                  // Set user ID for each entry
                  final entriesWithUserId = entries.map((entry) => NutritionEntry(
                    id: entry.id,
                    userId: user.id,
                    foodName: entry.foodName,
                    calories: entry.calories,
                    proteinG: entry.proteinG,
                    carbsG: entry.carbsG,
                    fatG: entry.fatG,
                    time: entry.time,
                  )).toList();
                  
                  // Save entries to database
                  for (final entry in entriesWithUserId) {
                    await repository.createEntry(
                      foodName: entry.foodName,
                      calories: entry.calories,
                      proteinG: entry.proteinG,
                      carbsG: entry.carbsG,
                      fatG: entry.fatG,
                      time: entry.time,
                    );
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Analysis failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal photo analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(NutritionEntry entry) async {
    final foodNameController = TextEditingController(text: entry.foodName);
    final caloriesController = TextEditingController(text: entry.calories.toString());
    final proteinController = TextEditingController(text: entry.proteinG.toString());
    final carbsController = TextEditingController(text: entry.carbsG.toString());
    final fatController = TextEditingController(text: entry.fatG.toString());
    
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Entry'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: foodNameController,
                    decoration: const InputDecoration(
                      labelText: 'Food Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Food name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Food name must be at least 2 characters';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: caloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_fire_department),
                      suffixText: 'cal',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Calories is required';
                      }
                      final calories = int.tryParse(value);
                      if (calories == null || calories < 0) {
                        return 'Please enter a valid number';
                      }
                      if (calories > 10000) {
                        return 'Calories seems too high';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: proteinController,
                          decoration: const InputDecoration(
                            labelText: 'Protein',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final protein = int.tryParse(value);
                              if (protein == null || protein < 0) {
                                return 'Invalid';
                              }
                              if (protein > 1000) {
                                return 'Too high';
                              }
                            }
                            return null;
                          },
                          enabled: !isLoading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: carbsController,
                          decoration: const InputDecoration(
                            labelText: 'Carbs',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final carbs = int.tryParse(value);
                              if (carbs == null || carbs < 0) {
                                return 'Invalid';
                              }
                              if (carbs > 1000) {
                                return 'Too high';
                              }
                            }
                            return null;
                          },
                          enabled: !isLoading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: fatController,
                          decoration: const InputDecoration(
                            labelText: 'Fat',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final fat = int.tryParse(value);
                              if (fat == null || fat < 0) {
                                return 'Invalid';
                              }
                              if (fat > 1000) {
                                return 'Too high';
                              }
                            }
                            return null;
                          },
                          enabled: !isLoading,
                        ),
                      ),
                    ],
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Updating entry...'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading ? null : () async {
                if (formKey.currentState?.validate() ?? false) {
                  setState(() => isLoading = true);
                  
                  try {
                    final repository = ref.read(nutritionRepoProvider);
                    
                    final updatedEntry = entry.copyWith(
                      foodName: foodNameController.text.trim(),
                      calories: int.tryParse(caloriesController.text) ?? entry.calories,
                      proteinG: int.tryParse(proteinController.text) ?? entry.proteinG,
                      carbsG: int.tryParse(carbsController.text) ?? entry.carbsG,
                      fatG: int.tryParse(fatController.text) ?? entry.fatG,
                    );
                    
                    await repository.updateEntryWithOfflineSupport(updatedEntry);

                    if (mounted) {
                      Navigator.of(context).pop(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Entry updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    // Refresh search results if searching
                    if (_isSearching && _searchQuery.isNotEmpty) {
                      _performSearch(_searchQuery);
                    }
                  } catch (e) {
                    setState(() => isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update entry: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save'),
            ),
          ],
        ),
      ),
    );

    // Dispose controllers
    foodNameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(nutritionTodayProvider);
    final entries = ref.watch(nutritionEntriesProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final syncStatusAsync = ref.watch(syncStatusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search nutrition entries...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (query) {
                  if (query.isEmpty) {
                    _clearSearch();
                  } else {
                    _performSearch(query);
                  }
                },
              )
            : _isSelectionMode 
                ? Text('${_selectedEntryIds.length} selected')
                : const Text('Nutrition'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _showSearchBar
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showSearchBar = false;
                  });
                  _clearSearch();
                },
              )
            : _isSelectionMode 
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSelectionMode,
                  )
                : null,
        actions: _showSearchBar
            ? [
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: (_filterStartDate != null ||
                            _filterEndDate != null ||
                            _minCalories != null ||
                            _maxCalories != null)
                        ? Colors.orange
                        : null,
                  ),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter results',
                ),
                if (_currentSearchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                    tooltip: 'Clear search',
                  ),
              ]
            : _isSelectionMode 
                ? [
                    if (_selectedEntryIds.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _isPerformingBulkOperation ? null : _bulkDeleteEntries,
                      ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'select_all':
                            final entries = ref.read(nutritionEntriesProvider).value ?? [];
                            _selectAllEntries(entries);
                            break;
                          case 'deselect_all':
                            setState(() => _selectedEntryIds.clear());
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'select_all',
                          child: Text('Select All'),
                        ),
                        const PopupMenuItem(
                          value: 'deselect_all',
                          child: Text('Deselect All'),
                        ),
                      ],
                    ),
                  ]
                : [
                    // Connection status indicator
                    IconButton(
                      icon: Icon(
                        connectionStatus.when(
                          data: (isConnected) => isConnected ? Icons.cloud_done : Icons.cloud_off,
                          loading: () => Icons.cloud_queue,
                          error: (_, __) => Icons.cloud_off,
                        ),
                        color: connectionStatus.when(
                          data: (isConnected) => isConnected ? Colors.green : Colors.red,
                          loading: () => Colors.grey,
                          error: (_, __) => Colors.red,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              connectionStatus.when(
                                data: (isConnected) => isConnected 
                                    ? 'Connected to server' 
                                    : 'Offline mode - changes will sync when connected',
                                loading: () => 'Checking connection...',
                                error: (_, __) => 'Connection error',
                              ),
                            ),
                            backgroundColor: connectionStatus.when(
                              data: (isConnected) => isConnected ? Colors.green : Colors.orange,
                              loading: () => Colors.grey,
                              error: (_, __) => Colors.red,
                            ),
                          ),
                        );
                      },
                      tooltip: connectionStatus.when(
                        data: (isConnected) => isConnected ? 'Online' : 'Offline',
                        loading: () => 'Checking...',
                        error: (_, __) => 'Error',
                      ),
                    ),
                    // Sync status indicator
                      syncStatusAsync.when(
                        data: (syncStatus) {
                          final pendingOps = syncStatus['pendingOperations'] as int? ?? 0;
                          if (pendingOps > 0) {
                            return IconButton(
                              icon: Badge(
                                label: Text('$pendingOps'),
                                child: const Icon(Icons.sync_problem, color: Colors.orange),
                              ),
                              onPressed: () async {
                                final repository = ref.read(nutritionRepoProvider);
                                await repository.syncOfflineData();
                              },
                              tooltip: '$pendingOps pending changes - tap to sync',
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          _showSearchBar = true;
                        });
                      },
                      tooltip: 'Search entries',
                    ),
                    IconButton(
                      icon: const Icon(Icons.checklist),
                      onPressed: _toggleSelectionMode,
                      tooltip: 'Select multiple',
                    ),
                    IconButton(
                      onPressed: _exportData,
                      icon: const Icon(Icons.download),
                      tooltip: 'Export Data',
                    ),
                  ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search nutrition entries...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _isSearching = false;
                                _searchResults = [];
                              });
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    if (value.trim().isNotEmpty) {
                      _performSearch(value);
                    } else {
                      setState(() {
                        _isSearching = false;
                        _searchResults = [];
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Error message display
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),
            
            // Daily totals section
            totals.when(
              loading: () => _buildMacroSkeletonLoader(),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading daily totals: $error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () {
                          ref.invalidate(nutritionTodayProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Nutrition',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMacroInfo(
                            'Calories',
                            '${_calculateTotalCalories(data)}',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                          _buildMacroInfo(
                            'Protein',
                            '${_calculateTotalProtein(data)}g',
                            Icons.fitness_center,
                            Colors.red,
                          ),
                          _buildMacroInfo(
                            'Carbs',
                            '${_calculateTotalCarbs(data)}g',
                            Icons.grain,
                            Colors.amber,
                          ),
                          _buildMacroInfo(
                            'Fat',
                            '${_calculateTotalFat(data)}g',
                            Icons.opacity,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick actions section
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => const QuickAddMacrosSheet(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Quick add'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _scanBarcode();
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan barcode'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _analyzeMealPhoto();
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Photo meal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Entries section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isSearching ? 'Search Results' : 'Today\'s Entries',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isLoadingSearch)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _currentSearchQuery.isNotEmpty
                        ? _buildSearchResults()
                        : _buildTodaysEntries(entries),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode && _selectedEntryIds.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: _isPerformingBulkOperation ? null : _bulkDeleteEntries,
            backgroundColor: Colors.red,
            icon: _isPerformingBulkOperation 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.delete),
            label: Text(
              _isPerformingBulkOperation 
                ? 'Deleting...'
                : 'Delete ${_selectedEntryIds.length}',
            ),
          )
        : null,
    );
  }



  Widget _buildTodaysEntries(AsyncValue<List<NutritionEntry>> entries) {
    return entries.when(
      loading: () => _buildEntriesSkeletonLoader(),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load entries: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
      data: (entryList) {
        if (entryList.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No entries yet today',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start logging your meals!',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: entryList.map((entry) {
            final isSelected = _selectedEntryIds.contains(entry.id);
            
            return GestureDetector(
              onTap: _isSelectionMode 
                ? () => _toggleEntrySelection(entry.id)
                : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSelectionMode && isSelected 
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSelectionMode && isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    if (_isSelectionMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleEntrySelection(entry.id),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.foodName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${entry.calories} cal',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildMacroChip('P: ${entry.proteinG}g', Colors.blue),
                              const SizedBox(width: 8),
                              _buildMacroChip('C: ${entry.carbsG}g', Colors.orange),
                              const SizedBox(width: 8),
                              _buildMacroChip('F: ${entry.fatG}g', Colors.green),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!_isSelectionMode)
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: const Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDialog(entry);
                          } else if (value == 'delete') {
                            _deleteEntry(entry.id);
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMacroChip(String text, Color color) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
         color: color.withOpacity(0.2),
         borderRadius: BorderRadius.circular(12),
       ),
       child: Text(
         text,
         style: TextStyle(
           color: color,
           fontSize: 12,
           fontWeight: FontWeight.w500,
         ),
       ),
     );
   }

  /// Enhanced skeleton loader for macro information
  Widget _buildMacroSkeletonLoader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title skeleton
            Container(
              height: 24,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Macro info skeletons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) => _buildMacroInfoSkeleton()),
            ),
          ],
        ),
      ),
    );
  }

  /// Individual macro info skeleton
  Widget _buildMacroInfoSkeleton() {
    return Column(
      children: [
        // Icon skeleton
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        // Value skeleton
        Container(
          height: 16,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        // Label skeleton
        Container(
          height: 12,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// Enhanced skeleton loader for nutrition entries
  Widget _buildEntriesSkeletonLoader() {
    return Column(
      children: [
        // Loading indicator with text
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading your nutrition entries...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Entry skeletons
        ...List.generate(3, (index) => _buildEntrySkeletonItem()),
      ],
    );
  }

  /// Individual entry skeleton item
  Widget _buildEntrySkeletonItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food name skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Macro chips skeleton
                Row(
                  children: [
                    _buildMacroChipSkeleton(),
                    const SizedBox(width: 8),
                    _buildMacroChipSkeleton(),
                    const SizedBox(width: 8),
                    _buildMacroChipSkeleton(),
                  ],
                ),
              ],
            ),
          ),
          // Menu button skeleton
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  /// Macro chip skeleton
  Widget _buildMacroChipSkeleton() {
    return Container(
      height: 24,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }



  Future<void> _exportData() async {
    await showDialog(
      context: context,
      builder: (context) => _ExportDialog(
        onExport: (format, startDate, endDate) async {
          try {
            final repository = ref.read(nutritionRepoProvider);
            final String data;
            final String filename;
            
            if (format == 'JSON') {
              data = await repository.exportToJson(
                startDate: startDate,
                endDate: endDate,
              );
              filename = 'nutrition_export_${DateTime.now().millisecondsSinceEpoch}.json';
            } else {
              data = await repository.exportToCsv(
                startDate: startDate,
                endDate: endDate,
              );
              filename = 'nutrition_export_${DateTime.now().millisecondsSinceEpoch}.csv';
            }
            
            final file = await repository.saveExportToFile(data, filename);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data exported to ${file.path}'),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'Share',
                    onPressed: () {
                      // TODO: Implement share functionality
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Export failed: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
  
  Widget _buildMacroInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No entries found for "$_currentSearchQuery"',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final entry = _searchResults[index];
        final isSelected = _selectedEntryIds.contains(entry.id);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          child: ListTile(
            leading: _isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleEntrySelection(entry.id),
                  )
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
            title: Text(
              entry.foodName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${entry.calories} cal • ${entry.proteinG}g protein • ${entry.carbsG}g carbs • ${entry.fatG}g fat',
            ),
            trailing: _isSelectionMode
                ? null
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(entry);
                          break;
                        case 'delete':
                          _deleteEntry(entry.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
            onTap: _isSelectionMode
                ? () => _toggleEntrySelection(entry.id)
                : null,
          ),
        );
      },
    );
  }

  // Helper methods to calculate totals from List<NutritionEntry>
  int _calculateTotalCalories(List<NutritionEntry> entries) {
    return entries.fold(0, (sum, entry) => sum + entry.calories);
  }

  int _calculateTotalProtein(List<NutritionEntry> entries) {
    return entries.fold(0, (sum, entry) => sum + entry.proteinG);
  }

  int _calculateTotalCarbs(List<NutritionEntry> entries) {
    return entries.fold(0, (sum, entry) => sum + entry.carbsG);
  }

  int _calculateTotalFat(List<NutritionEntry> entries) {
    return entries.fold(0, (sum, entry) => sum + entry.fatG);
  }
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({
    required this.onApplyFilters,
    required this.onClearFilters,
    this.initialStartDate,
    this.initialEndDate,
    this.initialMinCalories,
    this.initialMaxCalories,
  });
  
  final Function(DateTime?, DateTime?, int?, int?) onApplyFilters;
  final VoidCallback onClearFilters;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final int? initialMinCalories;
  final int? initialMaxCalories;
  
  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _minCaloriesController = TextEditingController();
  final _maxCaloriesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    if (widget.initialMinCalories != null) {
      _minCaloriesController.text = widget.initialMinCalories.toString();
    }
    if (widget.initialMaxCalories != null) {
      _maxCaloriesController.text = widget.initialMaxCalories.toString();
    }
  }
  
  @override
  void dispose() {
    _minCaloriesController.dispose();
    _maxCaloriesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Results'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Start Date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('to'),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'End Date',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Calorie Range:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCaloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Min Calories',
                      border: OutlineInputBorder(),
                      suffixText: 'cal',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxCaloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Max Calories',
                      border: OutlineInputBorder(),
                      suffixText: 'cal',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onClearFilters();
            Navigator.of(context).pop();
          },
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final minCalories = _minCaloriesController.text.isNotEmpty
                ? int.tryParse(_minCaloriesController.text)
                : null;
            final maxCalories = _maxCaloriesController.text.isNotEmpty
                ? int.tryParse(_maxCaloriesController.text)
                : null;
            
            widget.onApplyFilters(_startDate, _endDate, minCalories, maxCalories);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.onExport});
  
  final Function(String format, DateTime? startDate, DateTime? endDate) onExport;
  
  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  String _selectedFormat = 'JSON';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;
  
  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Nutrition Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Format:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedFormat,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'JSON', child: Text('JSON')),
              DropdownMenuItem(value: 'CSV', child: Text('CSV')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFormat = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Start Date',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('to'),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'End Date',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _endDate = DateTime.now();
                    _startDate = _endDate!.subtract(const Duration(days: 7));
                  });
                },
                child: const Text('Last 7 days'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _endDate = DateTime.now();
                    _startDate = _endDate!.subtract(const Duration(days: 30));
                  });
                },
                child: const Text('Last 30 days'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : () async {
            setState(() {
              _isExporting = true;
            });
            
            await widget.onExport(_selectedFormat, _startDate, _endDate);
            
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }
}
