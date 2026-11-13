import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/scanned_document.dart';
import 'pdf_generation_service.dart';

final pdfFileServiceProvider = Provider<PdfFileService>((ref) {
  return PdfFileService();
});

class PdfFileService {
  final PdfGenerationService _pdfGenerationService;
  final Uuid _uuid;

  PdfFileService({
    PdfGenerationService? pdfGenerationService,
    Uuid? uuid,
  })  : _pdfGenerationService = pdfGenerationService ?? PdfGenerationService(),
        _uuid = uuid ?? const Uuid();

  /// Imports a PDF file from the device via file picker and saves a local copy.
  Future<ScannedDocument?> importPdfFromDevice() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final pickedPath = result.files.single.path;
    if (pickedPath == null || pickedPath.isEmpty) {
      return null;
    }

    final originalFile = File(pickedPath);
    if (!await originalFile.exists()) {
      return null;
    }

    final originalName = result.files.single.name;
    final rawName = p.basenameWithoutExtension(originalName).trim();
    final sanitizedName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

    final directory = await getApplicationDocumentsDirectory();
    final pdfDirectory = Directory(p.join(directory.path, 'pdfs'));
    if (!await pdfDirectory.exists()) {
      await pdfDirectory.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetFileName = 'imported_${timestamp}_$sanitizedName.pdf';
    final targetFilePath = p.join(pdfDirectory.path, targetFileName);

    final localPdfFile = await originalFile.copy(targetFilePath);

    int pageCount = 1;
    try {
      final pdfDoc = await PdfDocument.openFile(localPdfFile.path);
      try {
        pageCount = pdfDoc.pagesCount;
      } finally {
        await pdfDoc.close();
      }
    } catch (e) {
      debugPrint('Failed to read PDF page count with pdfx: $e');
      pageCount = 1;
    }

    final cleanTitle = rawName.isEmpty ? 'Imported Document' : rawName;

    return ScannedDocument(
      id: _uuid.v4(),
      title: cleanTitle,
      pdfPath: localPdfFile.path,
      pageCount: pageCount,
      createdAt: DateTime.now(),
      extractedText: '',
    );
  }

  /// Generates a PDF from a list of scanned image paths and returns a new [ScannedDocument].
  Future<ScannedDocument> createDocumentFromImages({
    required List<String> imagePaths,
    String? title,
    String extractedText = '',
    String? aiSummary,
  }) async {
    final pdfPath = await _pdfGenerationService.generatePdf(imagePaths: imagePaths);
    final defaultTitle = 'Scan ${DateTime.now().toIso8601String().substring(0, 10)}';

    return ScannedDocument(
      id: _uuid.v4(),
      title: title ?? defaultTitle,
      pdfPath: pdfPath,
      pageCount: imagePaths.length,
      createdAt: DateTime.now(),
      extractedText: extractedText,
      aiSummary: aiSummary,
    );
  }

  /// Exports an existing PDF file to user-selected device storage via Storage Access Framework.
  Future<String?> exportPdfToDevice({
    required String pdfPath,
    required String suggestedFileName,
  }) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      return null;
    }

    final bytes = await file.readAsBytes();
    final trimmedName = suggestedFileName.trim();
    final fileName = trimmedName.toLowerCase().endsWith('.pdf')
        ? trimmedName
        : '$trimmedName.pdf';

    return await FilePicker.saveFile(
      dialogTitle: 'Export PDF',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );
  }

  /// Shares a PDF document using the platform share sheet.
  Future<void> sharePdf({
    required String pdfPath,
    required String title,
  }) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      debugPrint('Cannot share PDF: file not found at $pdfPath');
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(pdfPath)],
        text: title,
      ),
    );
  }

  /// Safely deletes a PDF file from local app storage.
  Future<void> deletePdfFile(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete PDF file at $pdfPath: $e');
    }
  }
}
