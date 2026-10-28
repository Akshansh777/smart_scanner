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

Future<void> openDocumentScanner() async {
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
      appBar: AppBar(
        title: const Text('Scan Document'),
        backgroundColor: const Color.fromARGB(255, 248, 249, 250),
        foregroundColor: const Color.fromARGB(255, 12, 11, 11),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dotted image preview area
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: selectedImage == null
                      ? const Center(
                          child: Text(
                            'No image selected',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ClipRect(
                          child: Image.file(
                            File(selectedImage!.path),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // Gallery and Camera buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button
                  ElevatedButton(
                    onPressed: GalleryDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7F1FC),
                      foregroundColor: const Color(0xFF7050A0),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 35,
                        vertical: 18,
                      ),
                    ),
                    child: const Icon(
                      Icons.photo,
                      size: 28,
                    ),
                  ),

                  // Camera button
                  ElevatedButton(
                    onPressed: openDocumentScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7F1FC),
                      foregroundColor: const Color(0xFF7050A0),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 35,
                        vertical: 18,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),
              const SizedBox(height: 10),
//////////////////////////////////////////////// scan button
              ElevatedButton.icon(
                onPressed: () {
                  scanDocument();
                },
                icon: const Icon(Icons.document_scanner),
                label: const Text('Scan Document'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
