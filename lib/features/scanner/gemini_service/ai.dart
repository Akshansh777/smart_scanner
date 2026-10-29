import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiOcrService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<String> analyzeDocument(String imagePath) async {
    if (_apiKey.trim().isEmpty) {
      throw Exception(
        'Gemini API key is missing. Check your .env configuration.',
      );
    }

    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    final imageBytes = await imageFile.readAsBytes();

    if (imageBytes.isEmpty) {
      throw Exception('Selected image is empty.');
    }

    final extension = imagePath.split('.').last.toLowerCase();

    final mimeType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => throw Exception(
          'Unsupported image format: .$extension',
        ),
    };

    final model = GenerativeModel(
      model: 'gemini-3.8-flash',
      apiKey: _apiKey.trim(),
    );

    const prompt = '''
You are an expert at reading handwritten documents.

Analyze the original image and return the following sections:

1. TRANSCRIBED TEXT
Transcribe the document as accurately as possible.
Use surrounding context to interpret unclear handwriting.
Correct obvious spelling errors only when the intended word is clear.
Preserve the original meaning, names, dates, numbers, and important details.
Mark unreadable words as [unclear] rather than inventing them.

2. IMPORTANT KEY POINTS
List the most important facts and requests in concise bullet points.
Use only information supported by the document.

3. SUMMARY
Write a short summary of the document.

4. UNCERTAIN DETAILS
List any names, dates, numbers, or words that need manual verification.

Do not invent missing information.
If a section cannot be read, clearly say so.
''';

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint(
          'Sending Gemini request. Attempt $attempt of 3.',
        );

        final response = await model.generateContent([
          Content.multi([
            TextPart(prompt),
            DataPart(mimeType, imageBytes),
          ]),
        ]);

        final result = response.text?.trim();

        if (result == null || result.isEmpty) {
          throw Exception('Gemini returned an empty response.');
        }

        debugPrint('Gemini analysis completed successfully.');

        return result;
      } catch (e, stackTrace) {
        final error = e.toString().toLowerCase();

        final isTemporaryError = error.contains('503') ||
            error.contains('unavailable') ||
            error.contains('429') ||
            error.contains('resource_exhausted') ||
            error.contains('deadline exceeded') ||
            error.contains('timeout');

        debugPrint('GEMINI API ERROR: $e');
        debugPrint('ERROR TYPE: ${e.runtimeType}');

        if (!isTemporaryError || attempt == 3) {
          debugPrint('STACK TRACE: $stackTrace');
          rethrow;
        }

        final delaySeconds = attempt * 2;

        debugPrint(
          'Temporary Gemini error. Retrying in '
          '$delaySeconds seconds...',
        );

        await Future.delayed(
          Duration(seconds: delaySeconds),
        );
      }
    }

    throw Exception('Gemini request failed after retries.');
  }
}
