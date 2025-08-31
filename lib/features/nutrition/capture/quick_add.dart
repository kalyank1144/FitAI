import 'package:flutter/material.dart';
import '../../../core/storage/local_db.dart';

class QuickAddMacrosSheet extends StatefulWidget {
  const QuickAddMacrosSheet({super.key});
  @override
  State<QuickAddMacrosSheet> createState() => _QuickAddMacrosSheetState();
}

class _QuickAddMacrosSheetState extends State<QuickAddMacrosSheet> {
  final cals = TextEditingController();
  final protein = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: cals, decoration: const InputDecoration(labelText: 'Calories')), 
        TextField(controller: protein, decoration: const InputDecoration(labelText: 'Protein (g)')),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            await LocalDb.instance.put('last_quick_add', '${cals.text}|${protein.text}');
            if (!mounted) return; Navigator.pop(context);
          },
          child: const Text('Save'),
        )
      ]),
    );
  }
}