import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import 'package:cunning_document_scanner/cunning_document_scanner.dart'
    show CunningDocumentScanner;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'service/orc_service.dart';

class ExtractOcrScreen extends StatefulWidget {
  const ExtractOcrScreen({super.key});

  @override
  State<ExtractOcrScreen> createState() => _ExtractOcrScreenState();
}

class _ExtractOcrScreenState extends State<ExtractOcrScreen> {
  final AiOcrService _aiOcrService = AiOcrService();

  final List<String> selectedFilePaths = [];
  final List<String> selectedFileNames = [];
  final List<bool> selectedFileIsImages = [];

  bool get hasSelection => selectedFilePaths.isNotEmpty;
  bool get firstIsImage =>
      selectedFileIsImages.isNotEmpty && selectedFileIsImages.first;
  bool isProcessing = false;

  static const Color primaryBlue = Color(0xFF397EF5);
  ////////////////////////////////////////////////////////////
  // Open scanner and retain every captured page.
  Future<void> openDocumentScanner() async {
    try {
      final images = await CunningDocumentScanner.getPictures();
      if (!mounted || images == null || images.isEmpty) return;
      setState(() {
        selectedFilePaths
          ..clear()
          ..addAll(images);
        selectedFileNames
          ..clear()
          ..addAll(
              List.generate(images.length, (i) => 'Scanned page ${i + 1}'));
        selectedFileIsImages
          ..clear()
          ..addAll(List.filled(images.length, true));
      });
    } catch (e, stackTrace) {
      debugPrint('Scanner error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to scan document. Please try again.')),
      );
    }
  }

//////////////////////////////////////////////////////////////
  // Convert every selected PDF page to an image, OCR all pages, then ask Gemini once.
  Future<void> extractTextWithAI() async {
    if (!hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select or scan a document first.')),
      );
      return;
    }

    setState(() => isProcessing = true);
    try {
      final List<String> imagePaths = [];
      for (var i = 0; i < selectedFilePaths.length; i++) {
        final path = selectedFilePaths[i];
        if (selectedFileIsImages[i]) {
          imagePaths.add(path);
        } else {
          imagePaths.addAll(await _convertPdfToImages(path, i));
        }
      }
      if (imagePaths.isEmpty) throw Exception('No readable pages found.');

      final result = await _aiOcrService.extractTextAndAnalyze(imagePaths);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            constraints: const BoxConstraints(maxWidth: 600),
            backgroundColor: const Color(0xFFF4EEF8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: const Text(
              'Document Analysis',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(dialogContext).size.height * 0.65,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Extracted OCR text heading.
                    const Text(
                      'EXTRACTED TEXT',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 10),

                    //Original OCR output.
                    SelectableText(
                      result.extractedText,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),

                    // AI summary heading.
                    const Text(
                      'AI SUMMARY',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Render Markdown instead of showing raw symbols.
                    MarkdownBody(
                      data: result.aiResponse,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        h1: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.4,
                        ),
                        h2: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.4,
                        ),
                        h3: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.4,
                        ),
                        p: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        listBullet: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        blockSpacing: 12,
                        listIndent: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6550A4),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Document processing failed: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      final errorText = e.toString().toLowerCase();
      final message = errorText.contains('quota') ||
              errorText.contains('resource_exhausted') ||
              errorText.contains('429')
          ? 'Daily AI limit reached. Please try again later.'
          : 'Failed to process document. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  // Select multiple images and/or PDFs from storage.
  Future<void> selectFromStorage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
        withData: false,
      );
      if (result == null || result.files.isEmpty || !mounted) return;

      final paths = <String>[];
      final names = <String>[];
      final imageFlags = <bool>[];
      for (final file in result.files) {
        if (file.path == null) continue;
        final ext = file.extension?.toLowerCase() ?? '';
        if (!['jpg', 'jpeg', 'png', 'pdf'].contains(ext)) continue;
        paths.add(file.path!);
        names.add(file.name);
        imageFlags.add(ext != 'pdf');
      }
      if (paths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to access the selected files.')),
        );
        return;
      }
      setState(() {
        selectedFilePaths
          ..clear()
          ..addAll(paths);
        selectedFileNames
          ..clear()
          ..addAll(names);
        selectedFileIsImages
          ..clear()
          ..addAll(imageFlags);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to select files: $e')),
      );
    }
  }

  // Render every PDF page to a temporary PNG so ML Kit can read it.
  Future<List<String>> _convertPdfToImages(
      String pdfPath, int fileIndex) async {
    final document = await PdfDocument.openFile(pdfPath);
    final output = <String>[];
    try {
      final tempDir = await getTemporaryDirectory();
      for (var pageNumber = 1;
          pageNumber <= document.pagesCount;
          pageNumber++) {
        final page = await document.getPage(pageNumber);
        try {
          final rendered = await page.render(
            width: (page.width * 2),
            height: (page.height * 2),
            format: PdfPageImageFormat.png,
          );
          if (rendered == null) continue;
          final imageFile = File(
            '${tempDir.path}/ocr_pdf_${DateTime.now().microsecondsSinceEpoch}_${fileIndex}_$pageNumber.png',
          );
          await imageFile.writeAsBytes(rendered.bytes, flush: true);
          output.add(imageFile.path);
        } finally {
          await page.close();
        }
      }
    } finally {
      await document.close();
    }
    return output;
  }

  @override
  Widget build(BuildContext context) {
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

              // Header icon.
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
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 18),

              // Camera option.
              _buildOptionCard(
                icon: Icons.camera_alt_rounded,
                title: 'Open Camera',
                subtitle: 'Capture a document using your camera',
                color: primaryBlue,
                onTap: openDocumentScanner,
              ),

              const SizedBox(height: 18),

              // Storage option.
              _buildOptionCard(
                icon: Icons.folder_open_rounded,
                title: 'Select from Storage',
                subtitle: 'Choose an image or PDF from your phone',
                color: const Color(0xFFE34BCF),
                onTap: selectFromStorage,
              ),

              const SizedBox(height: 30),

              // Selected document preview.
              if (hasSelection) ...[
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show all selected images and PDFs in a grid.
                        Text(
                          '${selectedFilePaths.length} selected files/pages',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 15),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: selectedFilePaths.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) {
                            final path = selectedFilePaths[index];
                            final name = selectedFileNames[index];
                            final isImage = selectedFileIsImages[index];

                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F8FC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          primaryBlue.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          child: isImage
                                              ? Image.file(
                                                  File(path),
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) {
                                                    return const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 45,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons
                                                        .picture_as_pdf_rounded,
                                                    size: 65,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Cross button to remove this selected file.
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    elevation: 3,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () {
                                        setState(() {
                                          selectedFilePaths.removeAt(index);
                                          selectedFileNames.removeAt(index);
                                          selectedFileIsImages.removeAt(index);
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(5),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
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
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Reusable source option card.
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
