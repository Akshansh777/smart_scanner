import 'dart:io';
import 'orc_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ExtractOcrScreen extends StatefulWidget {
  const ExtractOcrScreen({super.key});

  @override
  State<ExtractOcrScreen> createState() => _ExtractOcrScreenState();
}

class _ExtractOcrScreenState extends State<ExtractOcrScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  String? selectedFileName;
  String? selectedFilePath;
  bool isImage = false;
  //////////////////////////////////////////////////////
  final AiOcrService _aiOcrService = AiOcrService();

  bool isProcessing = false;

  Future<void> extractTextWithAI() async {
    if (selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first.'),
        ),
      );
      return;
    }

    // Your current OCR service accepts images, not PDFs.
    if (!isImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image for now.'),
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final result = await _aiOcrService.extractTextAndAnalyze(
        selectedFilePath!,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Document Analysis'),
          content: SingleChildScrollView(
            child: SelectableText(
              'EXTRACTED TEXT\n\n'
              '${result.extractedText}\n\n'
              'AI SUMMARY\n\n'
              '${result.aiResponse}',
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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process document: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }
/////////////////////////////////////////////////////////////

  // Open camera
  Future<void> openCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image == null || !mounted) return;

      setState(() {
        selectedFileName = 'Camera Image';
        selectedFilePath = image.path;
        isImage = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open camera: $e')),
      );
    }
  }

  // Select image or PDF from phone storage
  Future<void> selectFromStorage() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'pdf',
        ],
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile file = result.files.first;

      if (file.path == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access the selected file.'),
          ),
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        selectedFileName = file.name;
        selectedFilePath = file.path;
        isImage = [
          'jpg',
          'jpeg',
          'png',
        ].contains(file.extension?.toLowerCase());
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to select file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF397EF5);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Extract Text (OCR)',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),

              // Header
              const Center(
                child: Icon(
                  Icons.document_scanner_outlined,
                  size: 75,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 18),

              const Center(
                child: Text(
                  'Turn Documents into Insights',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'Extract text, discover important points, '
                  'and understand your documents with AI.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'Choose your document source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(244, 0, 0, 0),
                ),
              ),

              const SizedBox(height: 18),

              // Camera option
              _buildOptionCard(
                icon: Icons.camera_alt_rounded,
                title: 'Open Camera',
                subtitle: 'Capture a document using your camera',
                color: primaryBlue,
                onTap: openCamera,
              ),

              const SizedBox(height: 18),

              // Storage option
              _buildOptionCard(
                icon: Icons.folder_open_rounded,
                title: 'Select from Storage',
                subtitle: 'Choose an image or PDF from your phone',
                color: const Color(0xFFE34BCF),
                onTap: selectFromStorage,
              ),

              const SizedBox(height: 30),

              // Selected file preview
              if (selectedFilePath != null) ...[
                const Text(
                  'Selected Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (isImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(selectedFilePath!),
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                size: 60,
                              );
                            },
                          ),
                        )
                      else
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 65,
                          color: Colors.redAccent,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        selectedFileName ?? 'Selected file',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : extractTextWithAI,
                          icon: isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            isProcessing
                                ? 'Analyzing Document...'
                                : 'Extract Text with AI',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                primaryBlue.withValues(alpha: 0.5),
                            disabledForegroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  //cards
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: 31,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
////////////////////////////////////// if this erase back off
