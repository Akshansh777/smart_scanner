import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/models/scanned_document.dart';
import '../services/pdf_file_service.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final ScannedDocument? document;
  final String? pdfPath;

  const PdfViewerScreen({
    super.key,
    this.document,
    this.pdfPath,
  }) : assert(
          document != null || pdfPath != null,
          'Either document or pdfPath must be provided.',
        );

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  late final PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  int _totalPages = 0;
  String? _loadError;

  String get effectivePath => widget.document?.pdfPath ?? widget.pdfPath!;
  String get effectiveTitle => widget.document?.title ?? 'PDF Viewer';

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _handlePrint() async {
    try {
      final file = File(effectivePath);
      if (!file.existsSync()) {
        _showErrorSnackBar('PDF file not found on device.');
        return;
      }

      await Printing.layoutPdf(
        name: effectiveTitle,
        onLayout: (_) async => file.readAsBytes(),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to print PDF: $e');
    }
  }

  Future<void> _handleShare() async {
    try {
      final fileService = ref.read(pdfFileServiceProvider);
      await fileService.sharePdf(
        pdfPath: effectivePath,
        title: effectiveTitle,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share PDF: $e');
    }
  }

  Future<void> _handleExport() async {
    try {
      final fileService = ref.read(pdfFileServiceProvider);
      final savedPath = await fileService.exportPdfToDevice(
        pdfPath: effectivePath,
        suggestedFileName: effectiveTitle,
      );

      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to $savedPath'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to export PDF: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showJumpToPageDialog() async {
    final textController = TextEditingController(text: '$_currentPage');
    final formKey = GlobalKey<FormState>();

    final targetPage = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Go to Page'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Page Number (1 - $_totalPages)',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a page number';
                }
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed < 1 || parsed > _totalPages) {
                  return 'Enter a valid page between 1 and $_totalPages';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(
                    dialogContext,
                    int.parse(textController.text.trim()),
                  );
                }
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );

    if (targetPage != null && mounted) {
      _pdfViewerController.jumpToPage(targetPage);
    }
  }

  Widget _buildErrorView(bool isMissingFile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isMissingFile
                  ? 'PDF file not found'
                  : 'Failed to load PDF document',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isMissingFile
                  ? 'The file does not exist at $effectivePath.'
                  : (_loadError ?? 'An unexpected error occurred while reading the PDF.'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavigationPill() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Center(
          child: Material(
            elevation: 6,
            color: const Color(0xFF1E293B),
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    tooltip: 'Previous Page',
                    onPressed: _currentPage > 1
                        ? () => _pdfViewerController.previousPage()
                        : null,
                  ),
                  InkWell(
                    onTap: _showJumpToPageDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        'Page $_currentPage of $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    tooltip: 'Next Page',
                    onPressed: _currentPage < _totalPages
                        ? () => _pdfViewerController.nextPage()
                        : null,
                  ),
                  Container(
                    height: 20,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.25),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out_map, color: Colors.white),
                    tooltip: 'Reset Zoom (100%)',
                    onPressed: () {
                      _pdfViewerController.zoomLevel = 1.0;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileExists = File(effectivePath).existsSync();
    final hasError = !fileExists || _loadError != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(effectiveTitle),
        actions: [
          if (!hasError) ...[
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print',
              onPressed: _handlePrint,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: _handleShare,
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Export / Save As',
              onPressed: _handleExport,
            ),
          ],
        ],
      ),
      body: hasError
          ? _buildErrorView(!fileExists)
          : Stack(
              children: [
                SfPdfViewer.file(
                  File(effectivePath),
                  controller: _pdfViewerController,
                  onDocumentLoaded: (details) {
                    setState(() {
                      _totalPages = details.document.pages.count;
                    });
                  },
                  onPageChanged: (details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                  onDocumentLoadFailed: (details) {
                    setState(() {
                      _loadError = details.description;
                    });
                  },
                ),
                if (_totalPages > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildFloatingNavigationPill(),
                  ),
              ],
            ),
    );
  }
}
