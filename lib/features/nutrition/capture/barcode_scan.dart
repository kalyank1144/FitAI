import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key});
  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  String? code;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(children: [
        MobileScanner(onDetect: (capture) {
          final raw = capture.barcodes.first.rawValue;
          if (raw != null) {
            setState(() => code = raw);
          }
        }),
        if (code != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Scanned: $code'))),
            ),
          ),
      ]),
    );
  }
}
