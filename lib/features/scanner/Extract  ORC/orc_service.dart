import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiOcrService {
  Future<AiOcrResult> extractTextAndAnalyze(String imagePath) async {
    // STEP 1: Get the Gemini API key.
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'Gemini API key not found. Check your .env configuration.',
      );
    }

    // STEP 2: Initialize the OCR recognizer.
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      // STEP 3: Load the selected image.
      final inputImage = InputImage.fromFilePath(imagePath);

      // STEP 4: Extract text using Google ML Kit.
      final recognizedText =
          await textRecognizer.processImage(inputImage);

      final extractedText = recognizedText.text.trim();

      if (extractedText.isEmpty) {
        throw Exception(
          'No text found in this image. Please select a clearer image.',
        );
      }

      debugPrint('OCR completed successfully.');
      debugPrint('Extracted characters: ${extractedText.length}');

      // STEP 5: Initialize Gemini AI.
      final model = GenerativeModel(
        model: 'gemini-3.8-flash',
        apiKey: apiKey,
      );

      // STEP 6: Prepare the prompt.
      final prompt = '''
You are an intelligent document assistant.

Analyze the following text extracted from a document.

Please:
1. Identify the document's main purpose.
2. Summarize its important information.
3. Highlight important dates, names, amounts, and deadlines.
4. Use clear headings and bullet points.
5. Do not invent information that is not present in the text.

Extracted document text:
$extractedText
''';

      // STEP 7: Send the request to Gemini.
      // Retry temporary service errors up to 3 times.
      GenerateContentResponse? response;

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          debugPrint(
            'Sending Gemini request. Attempt $attempt of 3.',
          );

          response = await model.generateContent([
            Content.text(prompt),
          ]);

          break;
        } catch (e, stackTrace) {
          final errorMessage = e.toString().toLowerCase();

          final isTemporaryError =
              errorMessage.contains('503') ||
              errorMessage.contains('unavailable') ||
              errorMessage.contains('overloaded') ||
              errorMessage.contains('500') ||
              errorMessage.contains('502') ||
              errorMessage.contains('504');

          debugPrint('Gemini request failed: $e');
          debugPrint('Stack trace: $stackTrace');

          if (!isTemporaryError || attempt == 3) {
            rethrow;
          }

          // Wait before retrying.
          await Future.delayed(
            Duration(seconds: attempt * 2),
          );
        }
      }

      // STEP 8: Validate Gemini's response.
      final aiResponse = response?.text?.trim();

      if (aiResponse == null || aiResponse.isEmpty) {
        throw Exception(
          'Gemini returned an empty response. Please try again.',
        );
      }

      debugPrint('Gemini analysis completed successfully.');

      // STEP 9: Return OCR text and AI analysis.
      return AiOcrResult(
        extractedText: extractedText,
        aiResponse: aiResponse,
      );
    } catch (e, stackTrace) {
      debugPrint('OCR / GEMINI ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      rethrow;
    } finally {
      // Always release OCR resources.
      await textRecognizer.close();
    }
  }
}

// Stores the extracted text and AI analysis.
class AiOcrResult {
  final String extractedText;
  final String aiResponse;

  const AiOcrResult({
    required this.extractedText,
    required this.aiResponse,
  });
}