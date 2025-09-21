import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'data/profile_repository.dart';

class ProgressTrackingScreen extends ConsumerStatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  ConsumerState<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends ConsumerState<ProgressTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _armsController = TextEditingController();
  final _thighsController = TextEditingController();
  final _hipsController = TextEditingController();
  
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _armsController.dispose();
    _thighsController.dispose();
    _hipsController.dispose();
    super.dispose();
  }

  Future<void> _addBodyMeasurement() async {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least your weight'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(profileRepositoryProvider).addBodyMeasurement(
        weight: _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        bodyFat: _bodyFatController.text.isNotEmpty ? double.parse(_bodyFatController.text) : null,
        muscleMass: _muscleMassController.text.isNotEmpty ? double.parse(_muscleMassController.text) : null,
        waist: _waistController.text.isNotEmpty ? double.parse(_waistController.text) : null,
        chest: _chestController.text.isNotEmpty ? double.parse(_chestController.text) : null,
        biceps: _armsController.text.isNotEmpty ? double.parse(_armsController.text) : null,
        thighs: _thighsController.text.isNotEmpty ? double.parse(_thighsController.text) : null,
        hips: _hipsController.text.isNotEmpty ? double.parse(_hipsController.text) : null,
        recordedAt: DateTime.now(),
      );
      
      // Clear form
      _weightController.clear();
      _bodyFatController.clear();
      _muscleMassController.clear();
      _waistController.clear();
      _chestController.clear();
      _armsController.clear();
      _thighsController.clear();
      _hipsController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add measurement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addProgressPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await image.readAsBytes();
      
      await ref.read(profileRepositoryProvider).addProgressPhoto(
        imageBytes: bytes,
        fileName: image.name,
        category: 'front', // Default category
        description: 'Progress photo',
        takenAt: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress photo added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.scale), text: 'Measurements'),
            Tab(icon: Icon(LucideIcons.camera), text: 'Photos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeasurementsTab(),
          _buildPhotosTab(),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);
    
    return Column(
      children: [
        // Add Measurement Form
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Measurement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          prefixIcon: Icon(LucideIcons.scale),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _bodyFatController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Body Fat (%)',
                          prefixIcon: Icon(LucideIcons.percent),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _muscleMassController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Muscle Mass (kg)',
                          prefixIcon: Icon(LucideIcons.zap),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _waistController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Waist (cm)',
                          prefixIcon: Icon(LucideIcons.ruler),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _chestController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Chest (cm)',
                          prefixIcon: Icon(LucideIcons.ruler),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _armsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Arms (cm)',
                          prefixIcon: Icon(LucideIcons.ruler),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _thighsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thighs (cm)',
                          prefixIcon: Icon(LucideIcons.ruler),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _hipsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hips (cm)',
                          prefixIcon: Icon(LucideIcons.ruler),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addBodyMeasurement,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Measurement'),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Measurements History
        Expanded(
          child: measurementsAsync.when(
            data: (measurements) {
              if (measurements.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.scale, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No measurements yet'),
                      Text('Add your first measurement above'),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: measurements.length,
                itemBuilder: (context, index) {
                  final measurement = measurements[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(LucideIcons.scale),
                      title: Text('${measurement.weight?.toStringAsFixed(1) ?? 'N/A'} kg'),
                      subtitle: Text(
                        '${measurement.createdAt.day}/${measurement.createdAt.month}/${measurement.createdAt.year}',
                      ),
                      trailing: measurement.bodyFat != null
                          ? Text('${measurement.bodyFat!.toStringAsFixed(1)}%')
                          : null,
                      onTap: () => _showMeasurementDetails(measurement),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${error.toString()}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosTab() {
    final photosAsync = ref.watch(progressPhotosProvider);
    
    return Column(
      children: [
        // Add Photo Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _addProgressPhoto,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.camera),
              label: const Text('Take Progress Photo'),
            ),
          ),
        ),
        
        // Photos Grid
        Expanded(
          child: photosAsync.when(
            data: (photos) {
              if (photos.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.camera, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No progress photos yet'),
                      Text('Take your first photo above'),
                    ],
                  ),
                );
              }
              
              return GridView.builder(
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
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: photo.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(LucideIcons.imageOff),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${photo.createdAt.day}/${photo.createdAt.month}/${photo.createdAt.year}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${error.toString()}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMeasurementDetails(BodyMeasurement measurement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Measurement Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (measurement.weight != null)
              _buildDetailRow('Weight', '${measurement.weight!.toStringAsFixed(1)} kg'),
            if (measurement.bodyFat != null)
              _buildDetailRow('Body Fat', '${measurement.bodyFat!.toStringAsFixed(1)}%'),
            if (measurement.muscleMass != null)
              _buildDetailRow('Muscle Mass', '${measurement.muscleMass!.toStringAsFixed(1)} kg'),
            if (measurement.chest != null)
              _buildDetailRow('Chest', '${measurement.chest!.toStringAsFixed(1)} cm'),
            if (measurement.waist != null)
              _buildDetailRow('Waist', '${measurement.waist!.toStringAsFixed(1)} cm'),
            if (measurement.hips != null)
              _buildDetailRow('Hips', '${measurement.hips!.toStringAsFixed(1)} cm'),
            if (measurement.biceps != null)
              _buildDetailRow('Biceps', '${measurement.biceps!.toStringAsFixed(1)} cm'),
            if (measurement.thighs != null)
              _buildDetailRow('Thighs', '${measurement.thighs!.toStringAsFixed(1)} cm'),
            const SizedBox(height: 8),
            Text(
              'Recorded on ${measurement.createdAt.day}/${measurement.createdAt.month}/${measurement.createdAt.year}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}