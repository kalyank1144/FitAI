import 'dart:typed_data';

class PhotoMealAiService {
  Future<Map<String, dynamic>> analyze(Uint8List bytes) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return {'calories': 420, 'protein_g': 25};
  }
}