import 'dart:io' show File;
import 'package:cunning_document_scanner/cunning_document_scanner.dart'
    show CunningDocumentScanner;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_scanner/features/home/screens/home_screen.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ScanDocs extends StatefulWidget {
  const ScanDocs({super.key});

  @override
  State<ScanDocs> createState() => _ScanDocsState();
}

class _ScanDocsState extends State<ScanDocs> {
  final ImagePicker picker = ImagePicker();
  XFile? selectedImage;

  Future<void> CameraDocument() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
      );

      if (image != null && mounted) {
        setState(() {
          selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  //////////////////////////////////////////////
  Future<void> GalleryDocument() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null && mounted) {
        setState(() {
          selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
    }
  }

//////////////// scan fnx

  Future<void> scanDocument() async {
    if (selectedImage == null) return;

    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final inputImage = InputImage.fromFilePath(
        selectedImage!.path,
      );

      final recognizedText = await textRecognizer.processImage(inputImage);

      if (!mounted) return;

      final extractedText =
          recognizedText.blocks.map((block) => block.text).join('\n\n');

      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Scanned Text'),
          content: SingleChildScrollView(
            child: SelectableText(
              extractedText.isEmpty
                  ? 'No text found in this image.'
                  : extractedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Scanning error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to scan the document.'),
        ),
      );
    } finally {
      await textRecognizer.close();
    }
  }

/////////////l

  Future<List<String>> saveScannedImages(List<String> images) async {
    final dir = await getApplicationDocumentsDirectory();
    final scansDir = Directory(p.join(dir.path, 'scans'));
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    final savedPaths = <String>[];
    for (final imagePath in images) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imagePath)}';
      final saved = await File(imagePath).copy(p.join(scansDir.path, fileName));
      savedPaths.add(saved.path);
    }
    return savedPaths;
  }

  Future<void> openDocumentScanner() async {///// crop,,filter,enchance,clean,rotate
    try {
      final images = await CunningDocumentScanner.getPictures();

      if (!mounted) return;
      if (images == null || images.isEmpty) return;

      final savedPaths = await saveScannedImages(images);
      debugPrint('Saved to: $savedPaths');

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('Scanner error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
///////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FC),
      appBar: AppBar(
        title: const Text(
          'Scan Document',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 21,
          ),
        ),
        backgroundColor: const Color(0xFFFAF9FC),
        foregroundColor: const Color(0xFF19171D),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              // Camera icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.camera_rounded,
                    size: 58,
                    color: Color(0xFF3984E8),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // Heading
              const Center(
                child: Text(
                  'Scan Document',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF24212B),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              const Center(
                child: Text(
                  'Capture documents and\n'
                  'turn your documents into digital files.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF77737F),
                  ),
                ),
              ),

              const SizedBox(height: 38),

              // Section title
              const Text(
                'Choose your document source',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF292631),
                ),
              ),

              const SizedBox(height: 20),

              // Open Camera card
              _buildSourceCard(
                icon: Icons.camera_alt_rounded,
                title: 'Open Camera',
                subtitle: 'Capture a document using your camera',
                iconBackground: const Color(0xFFEAF1FF),
                iconColor: const Color(0xFF3984E8),
                onTap: openDocumentScanner,
              ),

              const SizedBox(height: 16),

              // Select from Storage card
              _buildSourceCard(
                icon: Icons.folder_rounded,
                title: 'Select from Storage',
                subtitle: 'Choose an image or PDF from your phone',
                iconBackground: const Color(0xFFFBEAF0),
                iconColor: const Color(0xFFD47797),
                onTap: GalleryDocument,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackground,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFECE9F1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF292631),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF77737F),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 26,
                color: Color(0xFF77737F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
