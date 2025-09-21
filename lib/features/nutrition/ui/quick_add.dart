import 'package:fitai/features/nutrition/data/nutrition_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickAddMacrosSheet extends ConsumerStatefulWidget {
  const QuickAddMacrosSheet({super.key});
  @override
  ConsumerState<QuickAddMacrosSheet> createState() => _QuickAddMacrosSheetState();
}

class _QuickAddMacrosSheetState extends ConsumerState<QuickAddMacrosSheet> {
  final cals = TextEditingController();
  final protein = TextEditingController();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: cals, 
          decoration: const InputDecoration(
            labelText: 'Calories',
            border: OutlineInputBorder(),
          ), 
          keyboardType: TextInputType.number,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: protein, 
          decoration: const InputDecoration(
            labelText: 'Protein (g)',
            border: OutlineInputBorder(),
          ), 
          keyboardType: TextInputType.number,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isLoading ? null : _saveEntry,
              child: _isLoading 
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
      ]),
    );
  }
  
  Future<void> _saveEntry() async {
    final cal = int.tryParse(cals.text) ?? 0;
    final prot = int.tryParse(protein.text) ?? 0;
    
    if (cal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid calories'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(nutritionRepoProvider);
      await repo.quickAdd(calories: cal, proteinG: prot);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add entry: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _saveEntry,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
