import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool flashOn = false;

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.first;
    final String? value = barcode.rawValue;

    if (value != null) {
      Navigator.pop(context, value); // return scanned URL
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // NOTE: mobile_scanner auto-handles gallery scanning internally later
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gallery scan coming next phase")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        actions: [
          IconButton(
            icon: Icon(flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              controller.toggleTorch();
              setState(() => flashOn = !flashOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: _onDetect,
      ),
    );
  }
}
