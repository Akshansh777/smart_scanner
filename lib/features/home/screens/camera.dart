import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:smart_scanner/features/pdf_workspace/services/pdf_file_service.dart';
import 'package:smart_scanner/features/pdf_workspace/services/pdf_generation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/controllers/document_list_controller.dart';


class ScanDocs extends ConsumerStatefulWidget  {
  const ScanDocs({super.key});

  @override
  ConsumerState<ScanDocs> createState() => _ScanDocsState();
}

class _ScanDocsState extends ConsumerState<ScanDocs> {
  final ImagePicker picker = ImagePicker();

  final List<String> selectedImages = [];

  bool isCreatingPdf = false;

 

  Future<void> openDocumentScanner() async {
    try {
      final images = await CunningDocumentScanner.getPictures();

      if (!mounted) return;

      if (images == null || images.isEmpty) {
        return;
      }

      final savedPaths = await saveScannedImages(images);

      if (!mounted) return;

      setState(() {
        selectedImages.addAll(savedPaths);
      });

      debugPrint('Saved scanned images: $savedPaths');
    } catch (e, stackTrace) {
      debugPrint('Scanner error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to scan document.'),
        ),
      );
    }
  }

  
  Future<void> GalleryDocument() async {
    try {
      final List<XFile> images = await picker.pickMultiImage();

      if (!mounted || images.isEmpty) {
        return;
      }

      setState(() {
        selectedImages.addAll(
          images.map((image) => image.path),
        );
      });

      debugPrint(
        'Selected gallery images: '
        '${images.map((image) => image.path).toList()}',
      );
    } catch (e, stackTrace) {
      debugPrint('Gallery error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to select images.'),
        ),
      );
    }
  }

  
  Future<List<String>> saveScannedImages(
    List<String> images,
  ) async {
    final dir = await getApplicationDocumentsDirectory();

    final scansDir = Directory(
      p.join(dir.path, 'scans'),
    );

    if (!await scansDir.exists()) {
      await scansDir.create(
        recursive: true,
      );
    }

    final savedPaths = <String>[];

    for (final imagePath in images) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_'
          '${p.basename(imagePath)}';

      final destination = p.join(
        scansDir.path,
        fileName,
      );

      final savedFile = await File(imagePath).copy(
        destination,
      );

      savedPaths.add(savedFile.path);
    }

    return savedPaths;
  }

  
  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  

  Future<void> createPdf() async {
  if (selectedImages.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select at least one page.'),
      ),
    );
    return;
  }

  setState(() {
    isCreatingPdf = true;
  });

  try {
    debugPrint(
      'Creating PDF from ${selectedImages.length} images',
    );

    // Create PDF + ScannedDocument
    final pdfFileService = ref.read(pdfFileServiceProvider);

    final document = await pdfFileService.createDocumentFromImages(
      imagePaths: List<String>.from(selectedImages),
    );

    debugPrint('PDF created successfully: ${document.pdfPath}');

    // Add document to PDF Workspace
    await ref
        .read(documentListControllerProvider.notifier)
        .addDocument(document);

    debugPrint('Document added to PDF Workspace');

    if (!mounted) return;

    // Show success dialog only AFTER everything is completed
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 60,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PDF Created!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your PDF has been created successfully.\n\n'
                      'Pages: ${selectedImages.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  } catch (e, stackTrace) {
    debugPrint('PDF generation error: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to create PDF: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isCreatingPdf = false;
      });
    }
  }
}

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9FE),

      appBar: AppBar(
        title: const Text(
          'Scan Document',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 21,
          ),
        ),
        backgroundColor: const Color(0xFFFEF9FE),
        foregroundColor: const Color(0xFF19171D),
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),

               

                Center(
                  child: Container(
                   
                   
                    child: const Icon(
                      Icons.camera,
                      size: 72,
                      color: Color(0xFF3984E8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

               
                const Center(
                  child: Text(
                    'Scan Documents Easily',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF24212B),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

          

                const Center(
                  child: Text(
                    'Scan, organize, and convert your documents '
                    'into a PDF in just a few taps.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF77737F),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                
                const Text(
                  'Choose your document source',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF292631),
                  ),
                ),

                const SizedBox(height: 18),

                
                _buildSourceCard(
                  icon: Icons.camera_alt_rounded,
                  title: 'Scan with Camera',
                  subtitle:
                      'Capture, auto-crop and enhance a document',
                  iconBackground: const Color(0xFFEAF1FF),
                  iconColor: const Color(0xFF3984E8),
                  onTap: openDocumentScanner,
                ),

                const SizedBox(height: 14),

                

                _buildSourceCard(
                  icon: Icons.folder_rounded,
                  title: 'Select from Storage',
                  subtitle:
                      'Choose one or more images from your phone',
                  iconBackground: const Color(0xFFFBEAF0),
                  iconColor: const Color(0xFFD47797),
                  onTap: GalleryDocument,
                ),

                const SizedBox(height: 25),

               

                if (selectedImages.isNotEmpty)
                  _buildSelectedPagesSection(),

                const SizedBox(height: 20),

              

                if (selectedImages.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton.icon(
                      onPressed: isCreatingPdf
                          ? null
                          : openDocumentScanner,
                      icon: const Icon(
                        Icons.add,
                        size: 24,
                      ),
                      label: const Text(
                        'Add More Pages',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(0xFF3984E8),
                        side: const BorderSide(
                          color: Color(0xFF3984E8),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSelectedPagesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD8E3F5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          

          Text(
            '${selectedImages.length} selected files/pages',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF292631),
            ),
          ),

          const SizedBox(height: 18),

         
          SizedBox(
            height: 350,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return _buildSelectedImage(index);
              },
            ),
          ),

          const SizedBox(height: 20),

         

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: isCreatingPdf ? null : createPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3984E8),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isCreatingPdf
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create PDF',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // 

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
              // ICON
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

              // TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF292631),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF77737F),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ARROW
              const Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: Color(0xFF77737F),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildSelectedImage(int index) {
    final imagePath = selectedImages[index];

    final fileName = p.basename(imagePath);

    return Container(
      width: 275,
      margin: const EdgeInsets.only(
        right: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD8E3F5),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
         

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // IMAGE
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(14),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // FILE NAME
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  4,
                  12,
                  12,
                ),
                child: Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF292631),
                  ),
                ),
              ),
            ],
          ),

        

          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  removeImage(index);
                },
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    size: 22,
                    color: Color(0xFFE05A5A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}