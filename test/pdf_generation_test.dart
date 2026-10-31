import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_scanner/features/pdf_workspace/services/pdf_generation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return tempDirectory.path;
      }

      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    await tempDirectory.delete(recursive: true);
  });

  test('Generates a PDF from three images', () async {
    final pdfService = PdfGenerationService();

    final imagePaths = [
      'assets/test_images/05. Graphite Mono.png',
      'assets/test_images/07. Graphite Mono.png',
      'assets/test_images/20. Catppuccin Mocha.jpg',
    ];

    final pdfPath = await pdfService.generatePdf(
      imagePaths: imagePaths,
    );

    final pdfFile = File(pdfPath);

    expect(await pdfFile.exists(), isTrue);
    expect(await pdfFile.length(), greaterThan(0));

    final bytes = await pdfFile.openRead(0, 5).first;
    expect(String.fromCharCodes(bytes), '%PDF-');

    print('Generated PDF: $pdfPath');
    print('PDF size: ${await pdfFile.length()} bytes');
  });
}