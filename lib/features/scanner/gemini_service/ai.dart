import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqOcrService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static Future<String> analyzeDocument(String imagePath) async {
    // 1. Validate API key
    if (_apiKey.trim().isEmpty) {
      throw Exception(
        'Groq API key is missing. Check your .env configuration.',
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

    // 4. Convert image to Base64
    final base64Image = base64Encode(imageBytes);

    // Groq expects the local image as a data URL
    final imageDataUrl = 'data:$mimeType;base64,$base64Image';

    // 5. OCR prompt
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

    // 6. Retry handling
    const maxAttempts = 2;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final stopwatch = Stopwatch()..start();

      try {
        debugPrint(
          'Sending Groq Vision request. '
          'Attempt $attempt of $maxAttempts.',
        );

        final response = await http
            .post(
              Uri.parse(
                'https://api.groq.com/openai/v1/chat/completions',
              ),
              headers: {
                'Authorization': 'Bearer ${_apiKey.trim()}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': 'qwen/qwen3.8-27b',
                'messages': [
                  {
                    'role': 'user',
                    'content': [
                      {
                        'type': 'text',
                        'text': prompt,
                      },
                      {
                        'type': 'image_url',
                        'image_url': {
                          'url': imageDataUrl,
                        },
                      },
                    ],
                  },
                ],
                'temperature': 0.1,
                'max_completion_tokens': 2048,
              }),
            )
            .timeout(
              const Duration(seconds: 60),
            );

        stopwatch.stop();

        debugPrint(
          'Groq request took '
          '${stopwatch.elapsed.inSeconds} seconds.',
        );

        debugPrint(
          'Groq HTTP status: ${response.statusCode}',
        );

        // 7. Successful response
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          final result =
              data['choices']?[0]?['message']?['content']?.toString().trim();

          if (result == null || result.isEmpty) {
            throw Exception(
              'Groq returned an empty response.',
            );
          }

          debugPrint(
            'Groq OCR completed successfully.',
          );

          return result;
        }

        // 8. Handle API errors
        final errorBody = response.body;

        debugPrint(
          'GROQ API ERROR ${response.statusCode}: $errorBody',
        );

        final error = errorBody.toLowerCase();

        final isTemporaryError = response.statusCode == 429 ||
            response.statusCode == 500 ||
            response.statusCode == 502 ||
            response.statusCode == 503 ||
            error.contains('timeout') ||
            error.contains('temporarily unavailable') ||
            error.contains('rate limit');

        // Invalid API key
        if (response.statusCode == 401) {
          throw Exception(
            'Groq API key is invalid. '
            'Check your GROQ_API_KEY in the .env file.',
          );
        }

        // Don't retry permanent errors
        if (!isTemporaryError || attempt == maxAttempts) {
          throw Exception(
            'Groq OCR failed. '
            'HTTP ${response.statusCode}: $errorBody',
          );
        }

        debugPrint(
          'Temporary Groq error. Retrying in 2 seconds...',
        );

        await Future.delayed(
          const Duration(seconds: 2),
        );
      } catch (e, stackTrace) {
        stopwatch.stop();

        debugPrint(
          'GROQ OCR ERROR: $e',
        );

        final error = e.toString().toLowerCase();

        final isTemporaryError = e is TimeoutException ||
            error.contains('timeout') ||
            error.contains('503') ||
            error.contains('502') ||
            error.contains('500') ||
            error.contains('429') ||
            error.contains('socketexception') ||
            error.contains('temporarily unavailable');

        // If it's a permanent error, don't retry.
        if (!isTemporaryError || attempt == maxAttempts) {
          debugPrint(
            'STACK TRACE: $stackTrace',
          );

          if (e is TimeoutException) {
            throw Exception(
              'Groq request timed out. Please try again.',
            );
          }

          rethrow;
        }

        debugPrint(
          'Temporary error. Retrying in 2 seconds...',
        );

        await Future.delayed(
          const Duration(seconds: 2),
        );
      }
    }

    throw Exception(
      'Groq OCR failed after retries.',
    );
  }
}


