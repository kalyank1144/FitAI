import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/nutrition_repository.dart';

class QuickAddMacrosSheet extends ConsumerStatefulWidget {
  const QuickAddMacrosSheet({super.key});
  @override
  ConsumerState<QuickAddMacrosSheet> createState() => _QuickAddMacrosSheetState();
}

class _QuickAddMacrosSheetState extends ConsumerState<QuickAddMacrosSheet> {
  final cals = TextEditingController();
  final protein = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: cals, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number), 
        TextField(controller: protein, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            final repo = ref.read(nutritionRepoProvider);
            final cal = int.tryParse(cals.text) ?? 0;
            final prot = int.tryParse(protein.text) ?? 0;
            await repo.quickAdd(calories: cal, proteinG: prot);
            if (!mounted) return; Navigator.pop(context);
          },
          child: const Text('Save'),
        )
      ]),
    );
  }
}