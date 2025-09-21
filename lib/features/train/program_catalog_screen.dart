import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/components/neon_focus.dart';
import 'data/program_repository.dart';
import 'data/program.dart';

/// Program catalog screen showing all available workout programs
class ProgramCatalogScreen extends ConsumerStatefulWidget {
  const ProgramCatalogScreen({super.key});

  @override
  ConsumerState<ProgramCatalogScreen> createState() => _ProgramCatalogScreenState();
}

class _ProgramCatalogScreenState extends ConsumerState<ProgramCatalogScreen> {
  String _searchQuery = '';
  String _selectedDifficulty = 'All';
  String _selectedCategory = 'All';
  
  final List<String> _difficulties = ['All', 'Beginner', 'Intermediate', 'Advanced'];
  final List<String> _categories = ['All', 'Strength', 'Cardio', 'Flexibility', 'HIIT', 'Bodyweight'];

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(allProgramsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Catalog'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          if (_searchQuery.isNotEmpty || _selectedDifficulty != 'All' || _selectedCategory != 'All')
            Container(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_searchQuery.isNotEmpty)
                    _buildFilterChip(
                      'Search: $_searchQuery',
                      () => setState(() => _searchQuery = ''),
                    ),
                  if (_selectedDifficulty != 'All')
                    _buildFilterChip(
                      'Difficulty: $_selectedDifficulty',
                      () => setState(() => _selectedDifficulty = 'All'),
                    ),
                  if (_selectedCategory != 'All')
                    _buildFilterChip(
                      'Category: $_selectedCategory',
                      () => setState(() => _selectedCategory = 'All'),
                    ),
                ],
              ),
            ),
          
          // Programs List
          Expanded(
            child: programsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load programs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(allProgramsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (programs) {
                final filteredPrograms = _filterPrograms(programs);
                
                if (filteredPrograms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.search,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          programs.isEmpty 
                              ? 'No programs available'
                              : 'No programs match your filters',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          programs.isEmpty
                              ? 'Add programs to Supabase to see them here'
                              : 'Try adjusting your search or filters',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        if (programs.isNotEmpty) ...[                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _clearAllFilters,
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPrograms.length,
                  itemBuilder: (context, index) {
                    final program = filteredPrograms[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ProgramCard(program: program),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Program> _filterPrograms(List<Program> programs) {
    return programs.where((program) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = program.name.toLowerCase().contains(query);
        final matchesDescription = program.description?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesDescription) return false;
      }
      
      // Difficulty filter
      if (_selectedDifficulty != 'All') {
        if (program.difficulty != _selectedDifficulty) return false;
      }
      
      // Category filter (assuming we add category to Program model later)
      if (_selectedCategory != 'All') {
        // For now, we'll skip category filtering since it's not in the current model
        // This can be implemented when category field is added to Program
      }
      
      return true;
    }).toList();
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: const Icon(LucideIcons.x, size: 16),
      backgroundColor: Colors.blue.withOpacity(0.1),
      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Programs'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter program name or description...',
            prefixIcon: Icon(LucideIcons.search),
          ),
          onSubmitted: (value) {
            setState(() => _searchQuery = value.trim());
            Navigator.of(context).pop();
          },
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Programs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Difficulty Level'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              items: _difficulties.map((difficulty) {
                return DropdownMenuItem(
                  value: difficulty,
                  child: Text(difficulty),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDifficulty = value);
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Category'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedDifficulty = 'All';
      _selectedCategory = 'All';
    });
    Navigator.of(context).pop();
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program});
  
  final Program program;

  @override
  Widget build(BuildContext context) {
    return NeonFocus(
      child: GestureDetector(
        onTap: () {
          // Navigate to program details or start program
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected program: ${program.name}'),
              action: SnackBarAction(
                label: 'Start',
                onPressed: () {
                  // TODO: Implement program start functionality
                  context.push('/train/session');
                },
              ),
            ),
          );
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: program.coverUrl != null
                ? DecorationImage(
                    image: NetworkImage(program.coverUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.4),
                      BlendMode.darken,
                    ),
                  )
                : null,
            gradient: program.coverUrl == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.8),
                      Colors.purple.withOpacity(0.8),
                    ],
                  )
                : null,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        program.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (program.difficulty != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(program.difficulty!).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          program.difficulty!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (program.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    program.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.play,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Start Program',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (program.isFeatured) ...[
                      const Icon(
                        LucideIcons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}