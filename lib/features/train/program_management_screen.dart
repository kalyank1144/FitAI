import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'data/program.dart';
import 'data/program_repository.dart';
import 'data/exercise.dart';
import 'data/exercise_repository.dart';

class ProgramManagementScreen extends ConsumerStatefulWidget {
  const ProgramManagementScreen({super.key});

  @override
  ConsumerState<ProgramManagementScreen> createState() => _ProgramManagementScreenState();
}

class _ProgramManagementScreenState extends ConsumerState<ProgramManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedDifficulty = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'Program Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00FF88),
          labelColor: const Color(0xFF00FF88),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'My Programs'),
            Tab(text: 'Templates'),
            Tab(text: 'All Programs'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyPrograms(),
                _buildTemplates(),
                _buildAllPrograms(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProgramDialog(),
        backgroundColor: const Color(0xFF00FF88),
        child: const Icon(LucideIcons.plus, color: Colors.black),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search programs...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Difficulty:', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedDifficulty,
                  onChanged: (value) => setState(() => _selectedDifficulty = value!),
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                    DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                    DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyPrograms() {
    final userProgramsAsync = ref.watch(userProgramsProvider);
    
    return userProgramsAsync.when(
      data: (programs) {
        final filteredPrograms = _filterPrograms(programs);
        
        if (filteredPrograms.isEmpty) {
          return _buildEmptyState(
            'No programs found',
            'Create your first custom program to get started!',
            LucideIcons.dumbbell,
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredPrograms.length,
          itemBuilder: (context, index) {
            final program = filteredPrograms[index];
            return _buildProgramCard(program, isUserProgram: true);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTemplates() {
    // For now, show featured programs as templates
    final featuredProgramsAsync = ref.watch(featuredProgramsProvider);
    
    return featuredProgramsAsync.when(
      data: (programs) {
        final filteredPrograms = _filterPrograms(programs);
        
        if (filteredPrograms.isEmpty) {
          return _buildEmptyState(
            'No templates found',
            'Check back later for new program templates!',
            LucideIcons.bookOpen,
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredPrograms.length,
          itemBuilder: (context, index) {
            final program = filteredPrograms[index];
            return _buildProgramCard(program, isTemplate: true);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildAllPrograms() {
    final allProgramsAsync = ref.watch(allProgramsProvider);
    
    return allProgramsAsync.when(
      data: (programs) {
        final filteredPrograms = _filterPrograms(programs);
        
        if (filteredPrograms.isEmpty) {
          return _buildEmptyState(
            'No programs found',
            'Try adjusting your search or filters.',
            LucideIcons.search,
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredPrograms.length,
          itemBuilder: (context, index) {
            final program = filteredPrograms[index];
            return _buildProgramCard(program);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  List<Program> _filterPrograms(List<Program> programs) {
    return programs.where((program) {
      final matchesSearch = _searchQuery.isEmpty ||
          program.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          program.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesDifficulty = _selectedDifficulty == 'all' ||
          program.difficulty == _selectedDifficulty;
      
      return matchesSearch && matchesDifficulty;
    }).toList();
  }

  Widget _buildProgramCard(Program program, {bool isUserProgram = false, bool isTemplate = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        program.description,
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isUserProgram) ...[
                  IconButton(
                    onPressed: () => _showEditProgramDialog(program),
                    icon: const Icon(LucideIcons.edit, color: Colors.grey),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(program),
                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                  ),
                ] else if (isTemplate) ...[
                  IconButton(
                    onPressed: () => _duplicateProgram(program),
                    icon: const Icon(LucideIcons.copy, color: Color(0xFF00FF88)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDifficultyChip(program.difficulty),
                const SizedBox(width: 8),
                if (program.isFeatured)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Featured',
                      style: TextStyle(color: Color(0xFF00FF88), fontSize: 12),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => _viewProgramDetails(program),
                  child: const Text(
                    'View Details',
                    style: TextStyle(color: Color(0xFF00FF88)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        color = Colors.green;
        break;
      case 'intermediate':
        color = Colors.orange;
        break;
      case 'advanced':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Programs',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreateProgramDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateProgramDialog(),
    );
  }

  void _showEditProgramDialog(Program program) {
    showDialog(
      context: context,
      builder: (context) => _CreateProgramDialog(program: program),
    );
  }

  void _showDeleteConfirmation(Program program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Program', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${program.name}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(programRepositoryProvider).deleteProgram(program.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Program deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting program: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _duplicateProgram(Program program) async {
    try {
      await ref.read(programRepositoryProvider).duplicateProgram(program.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program duplicated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicating program: $e')),
        );
      }
    }
  }

  void _viewProgramDetails(Program program) {
    // Navigate to program details screen
    context.push('/train/program/${program.id}');
  }
}

class _CreateProgramDialog extends ConsumerStatefulWidget {
  final Program? program;
  
  const _CreateProgramDialog({this.program});

  @override
  ConsumerState<_CreateProgramDialog> createState() => _CreateProgramDialogState();
}

class _CreateProgramDialogState extends ConsumerState<_CreateProgramDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedDifficulty;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.program?.name ?? '');
    _descriptionController = TextEditingController(text: widget.program?.description ?? '');
    _selectedDifficulty = widget.program?.difficulty ?? 'beginner';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text(
        widget.program == null ? 'Create Program' : 'Edit Program',
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Program Name',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00FF88)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a program name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00FF88)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              onChanged: (value) => setState(() => _selectedDifficulty = value!),
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00FF88)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _isLoading ? null : _saveProgram,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.program == null ? 'Create' : 'Update',
                  style: const TextStyle(color: Color(0xFF00FF88)),
                ),
        ),
      ],
    );
  }

  void _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(programRepositoryProvider);
      
      if (widget.program == null) {
        // Create new program
        await repository.createProgram(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          difficulty: _selectedDifficulty,
        );
      } else {
        // Update existing program
        final updatedProgram = widget.program!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          difficulty: _selectedDifficulty,
        );
        await repository.updateProgram(updatedProgram);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.program == null
                  ? 'Program created successfully'
                  : 'Program updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving program: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}