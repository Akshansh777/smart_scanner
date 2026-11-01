import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiOcrService {
  /// OCR every supplied image in order, then send the combined text to Gemini once.
  /// Pass PDF pages as rendered image paths (the screen handles PDF conversion).
  Future<AiOcrResult> extractTextAndAnalyze(Object imagePaths) async {
    // Backward-compatible: older callers may still pass a single image path.
    final paths = imagePaths is String
        ? <String>[imagePaths]
        : imagePaths is List<String>
            ? imagePaths
            : throw ArgumentError('Pass an image path or a list of image paths.');
    if (paths.isEmpty) {
      throw Exception('No images or document pages were provided.');
    }

    final totalStopwatch = Stopwatch()..start();
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final allPages = <String>[];
      for (var i = 0; i < paths.length; i++) {
        debugPrint('ML Kit OCR: page ${i + 1}/${paths.length}');
        final inputImage = InputImage.fromFilePath(paths[i]);
        final recognized = await textRecognizer.processImage(inputImage);
        final pageText = recognized.text.trim();
        allPages.add('PAGE ${i + 1}\n$pageText');
      }

      final extractedText = allPages
          .where((page) => page.trim().isNotEmpty)
          .join('\n\n--------------------\n\n')
          .trim();

      debugPrint('OCR completed for ${paths.length} page(s).');
      debugPrint('Extracted characters: ${extractedText.length}');

      if (extractedText.isEmpty ||
          !RegExp(r'\w').hasMatch(extractedText.replaceAll(RegExp(r'PAGE \d+'), ''))) {
        throw Exception('No readable text found. Try a clearer image or PDF.');
      }

      // OCR has already succeeded. Missing key/quota should not discard OCR text.
      final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
      if (apiKey == null || apiKey.isEmpty) {
        return AiOcrResult(
          extractedText: extractedText,
          aiResponse: 'AI summary unavailable: Gemini API key was not found. '
              'Your extracted text is still available above.',
        );
      }

      final model = GenerativeModel(
        model: 'gemini-3.8-flash',
        apiKey: apiKey,
      );
      final prompt = '''
You are an intelligent document analysis assistant. Analyze the combined OCR text from a document that may contain multiple pages.

RULES:
1. Use only information explicitly present in the document. Do not invent facts.
2. Use clear Markdown headings and bullet points.
3. Keep the analysis concise and avoid repetition.
4. Include dates/deadlines only if explicitly present; otherwise omit that section.
5. Never include empty sections or mention missing information.
6. Return only the analysis.

SECTIONS:
## MAIN PURPOSE
Explain the purpose in 3-4 sentences.
## IMPORTANT INFORMATION
List key points, facts, and findings.
## IMPORTANT DETAILS
Include relevant names, organizations, amounts, and specific details.
## DATES AND DEADLINES
Include only when dates or deadlines are present.
## SHORT SUMMARY
Provide a concise 2-4 sentence summary.

Extracted text:
$extractedText
''';

      try {
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 120));
        final aiResponse = response.text?.trim();
        if (aiResponse == null || aiResponse.isEmpty) {
          return AiOcrResult(
            extractedText: extractedText,
            aiResponse: 'AI summary unavailable: Gemini returned an empty response.',
          );
        }
        return AiOcrResult(
          extractedText: extractedText,
          aiResponse: aiResponse,
        );
      } catch (e) {
        debugPrint('Gemini analysis failed: $e');
        final lower = e.toString().toLowerCase();
        final message = lower.contains('429') ||
                lower.contains('quota') ||
                lower.contains('resource_exhausted')
            ? 'Daily AI limit reached. Your extracted text is still available; try the AI summary again after the quota resets.'
            : 'AI summary could not be generated. Your extracted text is still available. Error: $e';
        return AiOcrResult(extractedText: extractedText, aiResponse: message);
      }
    } catch (e, stackTrace) {
      debugPrint('OCR ERROR: $e');
      debugPrint('$stackTrace');
      rethrow;
    } finally {
      await textRecognizer.close();
      totalStopwatch.stop();
      debugPrint('Total OCR + analysis time: ${totalStopwatch.elapsed.inSeconds}s');
    }
  }
}

class AiOcrResult {
  final String extractedText;
  final String aiResponse;

  const AiOcrResult({
    required this.extractedText,
    required this.aiResponse,
  });
}
