import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'gps_repository.dart';

class StartOutdoorSessionScreen extends StatefulWidget {
  const StartOutdoorSessionScreen({super.key});
  @override
  State<StartOutdoorSessionScreen> createState() => _StartOutdoorSessionScreenState();
}

class _StartOutdoorSessionScreenState extends State<StartOutdoorSessionScreen> {
  final repo = GpsRepository();
  Position? position;
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await repo.ensurePermissions();
    if (!ok) return;
    repo.watch().listen((p) => setState(() => position = p));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outdoor Session')),
      body: Center(child: Text(position == null ? 'Waiting for GPS…' : '${position!.latitude}, ${position!.longitude}')),
    );
  }
}