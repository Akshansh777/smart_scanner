import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class DocumentScannerService {
  final DocumentScanner _scanner = DocumentScanner(
    options: DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full,
      pageLimit: 10,
      isGalleryImport: true,
    ),
  );

  Future<List<String>> scanDocument() async {
    try {
      final result = await _scanner.scanDocument();

      return result.images;
    } catch (e) {
      throw Exception('Document scanning failed: $e');
    }
  }

  void dispose() {
    _scanner.close();
  }
}