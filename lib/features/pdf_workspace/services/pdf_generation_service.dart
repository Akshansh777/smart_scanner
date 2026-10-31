
import 'dart:io';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PdfGenerationService {
  Future<String> generatePdf({
    required List<String> imagePaths,
  }) async {
    // 1. Check whether images were provided.
    if (imagePaths.isEmpty) {
      throw ArgumentError('No images provided for PDF generation.');
    }

    // 2. Create an empty PDF document.
    final pdf = pw.Document();

    // 3. Convert every image into a PDF page.
    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);

      if (!await imageFile.exists()) {
        throw FileSystemException(
          'Image file does not exist.',
          imagePath,
        );
      }

      final imageBytes = await imageFile.readAsBytes();

      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    // 4. Get the app's documents directory.
    final directory = await getApplicationDocumentsDirectory();

    // 5. Create a folder for generated PDFs.
    final pdfDirectory = Directory(
      p.join(directory.path, 'pdfs'),
    );

    if (!await pdfDirectory.exists()) {
      await pdfDirectory.create(recursive: true);
    }

    // 6. Generate a filename.
    final fileName =
        'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

    // 7. Create the output file.
    final outputFile = File(
      p.join(pdfDirectory.path, fileName),
    );

    // 8. Save the PDF.
    await outputFile.writeAsBytes(
      await pdf.save(),
      flush: true,
    );

    // 9. Return the generated PDF's path.
    return outputFile.path;
  }
}
