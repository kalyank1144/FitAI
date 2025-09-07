import 'dart:typed_data';

import 'package:fitai/services/photo_meal_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoMealAssistPage extends StatefulWidget {
  const PhotoMealAssistPage({super.key});
  @override
  State<PhotoMealAssistPage> createState() => _PhotoMealAssistPageState();
}

class _PhotoMealAssistPageState extends State<PhotoMealAssistPage> {
  Uint8List? bytes;
  Map<String, dynamic>? result;
  final _picker = ImagePicker();
  final _ai = PhotoMealAiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Photo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Row(children: [
            FilledButton.icon(onPressed: _pick, icon: const Icon(Icons.photo_camera_rounded), label: const Text('Pick photo')),
            const SizedBox(width: 12),
            if (bytes != null) FilledButton(onPressed: _analyze, child: const Text('Analyze')),
          ]),
          const SizedBox(height: 16),
          if (bytes != null) Image.memory(bytes!, height: 180),
          if (result != null) Text('AI: ${result!}'),
        ]),
      ),
    );
  }

  Future<void> _pick() async {
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x == null) return;
    setState(() => bytes = x.readAsBytesSync());
  }

  Future<void> _analyze() async {
    if (bytes == null) return;
    final out = await _ai.analyze(bytes!);
    setState(() => result = out);
    final fileName = 'meal_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await Supabase.instance.client.storage.from('meal-photos').uploadBinary(fileName, bytes!);
    } catch (_) {}
  }
}