import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanDocs extends StatefulWidget {
  const ScanDocs({super.key});

  @override
  State<ScanDocs> createState() => _ScanDocsState();
}

class _ScanDocsState extends State<ScanDocs> {
  final ImagePicker picker = ImagePicker();

  Future<void> scanDocument() async {
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        debugPrint('Image path: ${image.path}');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image captured successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Camera error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening camera: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
        backgroundColor: const Color.fromARGB(255, 248, 249, 250),
        foregroundColor: const Color.fromARGB(255, 12, 11, 11),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: scanDocument,
          icon: const Icon(Icons.camera_alt),
          label: const Text(
            'Scan Document',
            style: TextStyle(
              color: Color.fromARGB(245, 18, 17, 17),
              fontSize: 20,
            ),
          ),
          style: ElevatedButton.styleFrom(
            iconColor: const Color.fromARGB(255, 33, 71, 186),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
    );
  }
}
