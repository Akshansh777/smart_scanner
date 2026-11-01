import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiOcrService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<String> analyzeDocument(String imagePath) async {
    // 1. Validate API key
    if (_apiKey.trim().isEmpty) {
      throw Exception(
        'Gemini API key is missing. Check your .env configuration.',
      );
    }

    // 2. Validate image file
    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    final imageBytes = await imageFile.readAsBytes();

    if (imageBytes.isEmpty) {
      throw Exception('Selected image is empty.');
    }

    // 3. Detect image format
    final extension = imagePath.split('.').last.toLowerCase();

    final mimeType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => throw Exception(
          'Unsupported image format: .$extension',
        ),
    };

    // 4. Initialize Gemini
    final model = GenerativeModel(
      model: 'gemini-3.8-flash',
      apiKey: _apiKey.trim(),
    );

    // 5. OCR-only prompt
    const prompt = '''
You are a precise OCR engine.

TASK:
Read and transcribe the text visible in the provided document image.

STRICT RULES:
1. Transcribe only text that is actually visible in the image.
2. Preserve the original wording, numbers, names, spelling, and paragraph order.
3. Do not summarize, explain, analyze, or interpret the document.
4. Do not add headings unless they exist in the original image.
5. Never invent missing or unreadable text.
6. Mark genuinely unreadable words as [unclear].
7. Do not include introductory sentences or additional commentary.
8. Return only the transcribed text.

TRANSCRIPTION:
''';

    // 6. Send request with timeout and retry handling
    const maxAttempts = 2;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final stopwatch = Stopwatch()..start();

      try {
        debugPrint(
          'Sending Gemini request. Attempt $attempt of $maxAttempts.',
        );

        final response = await model.generateContent([
          Content.multi([
            TextPart(prompt),
            DataPart(mimeType, imageBytes),
          ]),
        ]).timeout(const Duration(seconds: 60));

        stopwatch.stop();

        debugPrint(
          'Gemini request took '
          '${stopwatch.elapsed.inSeconds} seconds.',
        );

        final result = response.text?.trim();

        if (result == null || result.isEmpty) {
          throw Exception('Gemini returned an empty response.');
        }

        debugPrint('Gemini OCR completed successfully.');

        return result;
      } catch (e, stackTrace) {
        stopwatch.stop();

        final error = e.toString().toLowerCase();

        final isTemporaryError = e is TimeoutException ||
            error.contains('503') ||
            error.contains('unavailable') ||
            error.contains('429') ||
            error.contains('resource_exhausted') ||
            error.contains('deadline exceeded') ||
            error.contains('timeout') ||
            error.contains('socketexception');

        debugPrint('GEMINI API ERROR: $e');

        if (!isTemporaryError || attempt == maxAttempts) {
          debugPrint('STACK TRACE: $stackTrace');

          if (e is TimeoutException) {
            throw Exception(
              'Gemini request timed out. Please try again.',
            );
          }

          rethrow;
        }

        debugPrint('Temporary error. Retrying in 2 seconds.');

        await Future.delayed(const Duration(seconds: 2));
      }
    }

    throw Exception('Gemini OCR failed after retries.');
  }
}
