import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Rest Timer Provider
final restTimerProvider = StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isCompleted;

  RestTimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.isCompleted,
  });

  RestTimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    bool? isCompleted,
  }) {
    return RestTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier() : super(RestTimerState(
    remainingSeconds: 0,
    totalSeconds: 0,
    isRunning: false,
    isCompleted: false,
  ));

  void startTimer(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: true,
      isCompleted: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        timer.cancel();
        state = state.copyWith(isRunning: false, isCompleted: true);
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resumeTimer() {
    if (state.remainingSeconds > 0) {
      startTimer(state.remainingSeconds);
    }
  }

  void stopTimer() {
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: 0,
      totalSeconds: 0,
      isRunning: false,
      isCompleted: false,
    );
  }

  void addTime(int seconds) {
    if (state.isRunning || state.remainingSeconds > 0) {
      final newTime = state.remainingSeconds + seconds;
      state = state.copyWith(
        remainingSeconds: newTime,
        totalSeconds: state.totalSeconds + seconds,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Plate Calculator
class PlateCalculator {
  static final Map<double, int> standardPlates = {
    45.0: 10, // 45 lb plates
    35.0: 4,  // 35 lb plates
    25.0: 4,  // 25 lb plates
    10.0: 4,  // 10 lb plates
    5.0: 4,   // 5 lb plates
    2.5: 4,   // 2.5 lb plates
  };

  static const double barWeight = 45.0; // Standard Olympic barbell

  static Map<double, int> calculatePlates(double targetWeight, {bool isKg = false}) {
    if (isKg) {
      targetWeight = targetWeight * 2.20462; // Convert kg to lbs
    }

    if (targetWeight <= barWeight) {
      return {};
    }

    double remainingWeight = (targetWeight - barWeight) / 2; // Weight per side
    Map<double, int> result = {};

    for (final entry in standardPlates.entries) {
      final plateWeight = entry.key;
      final availablePlates = entry.value;
      
      if (remainingWeight >= plateWeight) {
        final neededPlates = (remainingWeight / plateWeight).floor();
        final usePlates = neededPlates > availablePlates ? availablePlates : neededPlates;
        
        if (usePlates > 0) {
          result[plateWeight] = usePlates;
          remainingWeight -= plateWeight * usePlates;
        }
      }
    }

    return result;
  }

  static double getTotalWeight(Map<double, int> plates, {bool isKg = false}) {
    double total = barWeight;
    for (final entry in plates.entries) {
      total += entry.key * entry.value * 2; // Multiply by 2 for both sides
    }
    
    if (isKg) {
      total = total / 2.20462; // Convert lbs to kg
    }
    
    return total;
  }
}

// Progress Photos Provider
final progressPhotosProvider = StateNotifierProvider<ProgressPhotosNotifier, List<ProgressPhoto>>((ref) {
  return ProgressPhotosNotifier();
});

class ProgressPhoto {
  final String id;
  final String imagePath;
  final DateTime date;
  final double? weight;
  final String? notes;

  ProgressPhoto({
    required this.id,
    required this.imagePath,
    required this.date,
    this.weight,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'weight': weight,
      'notes': notes,
    };
  }

  factory ProgressPhoto.fromMap(Map<String, dynamic> map) {
    return ProgressPhoto(
      id: map['id'],
      imagePath: map['imagePath'],
      date: DateTime.parse(map['date']),
      weight: map['weight']?.toDouble(),
      notes: map['notes'],
    );
  }
}

class ProgressPhotosNotifier extends StateNotifier<List<ProgressPhoto>> {
  ProgressPhotosNotifier() : super([]) {
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final photosJson = prefs.getStringList('progress_photos') ?? [];
    
    state = photosJson.map((json) {
      final map = Map<String, dynamic>.from(Uri.splitQueryString(json));
      return ProgressPhoto.fromMap(map);
    }).toList();
  }

  Future<void> _savePhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final photosJson = state.map((photo) {
      return Uri(queryParameters: photo.toMap().map((k, v) => MapEntry(k, v.toString()))).query;
    }).toList();
    
    await prefs.setStringList('progress_photos', photosJson);
  }

  Future<void> addPhoto(String imagePath, {double? weight, String? notes}) async {
    final photo = ProgressPhoto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      date: DateTime.now(),
      weight: weight,
      notes: notes,
    );
    
    state = [...state, photo];
    await _savePhotos();
  }

  Future<void> deletePhoto(String id) async {
    state = state.where((photo) => photo.id != id).toList();
    await _savePhotos();
  }
}

class AdvancedFeaturesScreen extends ConsumerStatefulWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  ConsumerState<AdvancedFeaturesScreen> createState() => _AdvancedFeaturesScreenState();
}

class _AdvancedFeaturesScreenState extends ConsumerState<AdvancedFeaturesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          'Advanced Features',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00FF88),
          labelColor: const Color(0xFF00FF88),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Rest Timer'),
            Tab(text: 'Plate Calculator'),
            Tab(text: 'Progress Photos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRestTimer(),
          _buildPlateCalculator(),
          _buildProgressPhotos(),
        ],
      ),
    );
  }

  Widget _buildRestTimer() {
    final timerState = ref.watch(restTimerProvider);
    final timerNotifier = ref.read(restTimerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer Display
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: timerState.isCompleted ? Colors.green : const Color(0xFF00FF88),
                width: 4,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(timerState.remainingSeconds),
                    style: TextStyle(
                      color: timerState.isCompleted ? Colors.green : Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (timerState.totalSeconds > 0)
                    Text(
                      'of ${_formatTime(timerState.totalSeconds)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Progress Bar
          if (timerState.totalSeconds > 0)
            LinearProgressIndicator(
              value: (timerState.totalSeconds - timerState.remainingSeconds) / timerState.totalSeconds,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(
                timerState.isCompleted ? Colors.green : const Color(0xFF00FF88),
              ),
            ),
          const SizedBox(height: 32),
          
          // Quick Timer Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickTimerButton('30s', 30, timerNotifier),
              _buildQuickTimerButton('60s', 60, timerNotifier),
              _buildQuickTimerButton('90s', 90, timerNotifier),
              _buildQuickTimerButton('2m', 120, timerNotifier),
              _buildQuickTimerButton('3m', 180, timerNotifier),
            ],
          ),
          const SizedBox(height: 24),
          
          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (timerState.isRunning)
                ElevatedButton.icon(
                  onPressed: () => timerNotifier.pauseTimer(),
                  icon: const Icon(LucideIcons.pause),
                  label: const Text('Pause'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                )
              else if (timerState.remainingSeconds > 0)
                ElevatedButton.icon(
                  onPressed: () => timerNotifier.resumeTimer(),
                  icon: const Icon(LucideIcons.play),
                  label: const Text('Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF88),
                    foregroundColor: Colors.black,
                  ),
                ),
              
              if (timerState.remainingSeconds > 0)
                ElevatedButton.icon(
                  onPressed: () => timerNotifier.stopTimer(),
                  icon: const Icon(LucideIcons.square),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          
          // Add Time Buttons
          if (timerState.remainingSeconds > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => timerNotifier.addTime(15),
                  child: const Text('+15s', style: TextStyle(color: Color(0xFF00FF88))),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => timerNotifier.addTime(30),
                  child: const Text('+30s', style: TextStyle(color: Color(0xFF00FF88))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickTimerButton(String label, int seconds, RestTimerNotifier notifier) {
    return ElevatedButton(
      onPressed: () => notifier.startTimer(seconds),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPlateCalculator() {
    return _PlateCalculatorWidget();
  }

  Widget _buildProgressPhotos() {
    return _ProgressPhotosWidget();
  }
}

class _PlateCalculatorWidget extends StatefulWidget {
  @override
  State<_PlateCalculatorWidget> createState() => _PlateCalculatorWidgetState();
}

class _PlateCalculatorWidgetState extends State<_PlateCalculatorWidget> {
  final _weightController = TextEditingController();
  bool _isKg = false;
  Map<double, int> _plates = {};
  double _totalWeight = 0;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculatePlates() {
    final weight = double.tryParse(_weightController.text);
    if (weight != null && weight > 0) {
      setState(() {
        _plates = PlateCalculator.calculatePlates(weight, isKg: _isKg);
        _totalWeight = PlateCalculator.getTotalWeight(_plates, isKg: _isKg);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Target Weight',
                    labelStyle: const TextStyle(color: Colors.grey),
                    suffixText: _isKg ? 'kg' : 'lbs',
                    suffixStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => _calculatePlates(),
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: _isKg,
                onChanged: (value) {
                  setState(() {
                    _isKg = value;
                    _calculatePlates();
                  });
                },
                activeColor: const Color(0xFF00FF88),
              ),
              Text(
                _isKg ? 'KG' : 'LBS',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Barbell Visualization
          if (_plates.isNotEmpty) ...[
            const Text(
              'Plate Configuration (per side):',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Plates List
            ..._plates.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPlateColor(entry.key),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${entry.key} ${_isKg ? 'kg' : 'lbs'} × ${entry.value}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 24),
            
            // Total Weight
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Weight:',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    '${_totalWeight.toStringAsFixed(1)} ${_isKg ? 'kg' : 'lbs'}',
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Instructions
          const Text(
            'Instructions:',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Enter your target weight\n• The calculator assumes a 45 lb (20 kg) Olympic barbell\n• Plates are calculated per side of the barbell\n• Standard plate availability is assumed',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getPlateColor(double weight) {
    switch (weight.toInt()) {
      case 45: return Colors.black;
      case 35: return Colors.yellow;
      case 25: return Colors.green;
      case 10: return Colors.white;
      case 5: return Colors.red;
      default: return Colors.blue;
    }
  }
}

class _ProgressPhotosWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(progressPhotosProvider);
    final photosNotifier = ref.read(progressPhotosProvider.notifier);

    return Column(
      children: [
        // Add Photo Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddPhotoDialog(context, photosNotifier),
            icon: const Icon(LucideIcons.camera),
            label: const Text('Add Progress Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: Colors.black,
            ),
          ),
        ),
        
        // Photos Grid
        Expanded(
          child: photos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.camera, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Progress Photos',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Take your first progress photo to track your transformation!',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return _buildPhotoCard(context, photo, photosNotifier);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(BuildContext context, ProgressPhoto photo, ProgressPhotosNotifier notifier) {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                image: DecorationImage(
                  image: FileImage(File(photo.imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${photo.date.day}/${photo.date.month}/${photo.date.year}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (photo.weight != null)
                  Text(
                    '${photo.weight!.toStringAsFixed(1)} lbs',
                    style: const TextStyle(color: Color(0xFF00FF88)),
                  ),
                if (photo.notes != null && photo.notes!.isNotEmpty)
                  Text(
                    photo.notes!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(context, photo, notifier),
                      icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPhotoDialog(BuildContext context, ProgressPhotosNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => _AddPhotoDialog(notifier: notifier),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProgressPhoto photo, ProgressPhotosNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Photo', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this progress photo?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notifier.deletePhoto(photo.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoDialog extends StatefulWidget {
  final ProgressPhotosNotifier notifier;
  
  const _AddPhotoDialog({required this.notifier});

  @override
  State<_AddPhotoDialog> createState() => _AddPhotoDialogState();
}

class _AddPhotoDialogState extends State<_AddPhotoDialog> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('Add Progress Photo', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image Selection
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: _selectedImage != null
                  ? Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Tap to select photo', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Weight Input
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Weight (optional)',
              labelStyle: TextStyle(color: Colors.grey),
              suffixText: 'lbs',
              suffixStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00FF88)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Notes Input
          TextField(
            controller: _notesController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00FF88)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _isLoading ? null : _savePhoto,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save', style: TextStyle(color: Color(0xFF00FF88))),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _savePhoto() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final weight = double.tryParse(_weightController.text);
      final notes = _notesController.text.trim();
      
      await widget.notifier.addPhoto(
        _selectedImage!.path,
        weight: weight,
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress photo added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}