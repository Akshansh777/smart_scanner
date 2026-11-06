import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

class AiOcrService {
  /// Image selection and pass them to list
  Future<AiOcrResult> extractTextAndAnalyze(Object imagePaths) async {
    final paths = imagePaths is String
        ? <String>[imagePaths]
        : imagePaths is List<String>
            ? imagePaths
            : throw ArgumentError(
                'Pass an image path or a list of image paths.',
              );

    if (paths.isEmpty) {
      throw Exception('No images or document pages were provided.');
    }

    ////////////////////////////////////////////////////////////////////////
    /// ML Kit functionality

    final totalStopwatch = Stopwatch()..start();

    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final allPages = <String>[];

      for (var i = 0; i < paths.length; i++) {
        debugPrint('ML Kit OCR: page ${i + 1}/${paths.length}');

        final inputImage = InputImage.fromFilePath(paths[i]);

        // OCR operation
        final recognized = await textRecognizer.processImage(inputImage);

        final StringBuffer pageText = StringBuffer();

        for (final block in recognized.blocks) {
          for (final line in block.lines) {
            final text = line.text.trim();

            if (text.isNotEmpty) {
              pageText.writeln(text);
            }
          }

          // Separate different OCR blocks
          pageText.writeln();
        }

        final cleanedPageText = pageText.toString().trim();

        allPages.add(
          'PAGE ${i + 1}\n$cleanedPageText',
        );
      }

      //////////////////////////////////////////////////////////////////////
      /// Combine all OCR pages

      final extractedText = allPages
          .where((page) => page.trim().isNotEmpty)
          .join('\n\n--------------------\n\n')
          .trim();

      debugPrint(
        'OCR completed for ${paths.length} page(s).',
      );

      debugPrint(
        'Extracted characters: ${extractedText.length}',
      );

      //////////////////////////////////////////////////////////////////////
      /// Check whether OCR found readable text

      if (extractedText.isEmpty ||
          !RegExp(r'\w').hasMatch(
            extractedText.replaceAll(
              RegExp(r'PAGE \d+'),
              '',
            ),
          )) {
        throw Exception(
          'No readable text found. Try a clearer image or PDF.',
        );
      }

      //////////////////////////////////////////////////////////////////////
      /// Get Groq API key

      final apiKey = dotenv.env['GROQ_API_KEY']?.trim();

      if (apiKey == null || apiKey.isEmpty) {
        return AiOcrResult(
          extractedText: extractedText,
          aiResponse: 'AI summary unavailable: Groq API key was not found. '
              'Your extracted text is still available above.',
        );
      }

      //////////////////////////////////////////////////////////////////////
      /// Prompt for Groq

      final prompt = '''
You are an intelligent document analysis assistant. Analyze the combined OCR text from a document that may contain multiple pages.

RULES:
1. Use only information explicitly present in the document. Do not invent facts.
2. Use clear Markdown headings and bullet points.
3. Keep the analysis concise and avoid repetition.
4. Include dates/deadlines only if explicitly present; otherwise omit that section.
5. Never include empty sections or mention missing information.
6. Return only the analysis.
7. If the image contains a question, generate the answer.

SECTIONS:

## MAIN PURPOSE
Explain the purpose in 3-4 sentences.

## IMPORTANT INFORMATION
List key points, facts, and findings.

## IMPORTANT DETAILS
Include relevant names, organizations, amounts, and specific details.

## SOLUTION OF QUESTIONS
Include solution of question only when the pages have the questions othrewise leave this section

## DATES AND DEADLINES
Include only when dates or deadlines are present.

## SHORT SUMMARY
Provide a concise 2-4 sentence summary.

Extracted text:
$extractedText
''';

      //////////////////////////////////////////////////////////////////////
      /// Send request to Groq

      try {
        debugPrint('Sending OCR text to Groq...');

        final response = await http
            .post(
              Uri.parse(
                'https://api.groq.com/openai/v1/chat/completions',
              ),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': 'openai/gpt-oss-20b',
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'You are an intelligent document analysis assistant.',
                  },
                  {
                    'role': 'user',
                    'content': prompt,
                  },
                ],
                'temperature': 0.2,
              }),
            )
            .timeout(
              const Duration(seconds: 60),
            );

        debugPrint(
          'Groq HTTP status: ${response.statusCode}',
        );

        ////////////////////////////////////////////////////////////////////
        /// Successful response

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          final aiResponse =
              data['choices']?[0]?['message']?['content']?.toString().trim();

          if (aiResponse == null || aiResponse.isEmpty) {
            return AiOcrResult(
              extractedText: extractedText,
              aiResponse:
                  'AI summary unavailable: Groq returned an empty response.',
            );
          }

          debugPrint('Groq analysis completed successfully.');

          return AiOcrResult(
            extractedText: extractedText,
            aiResponse: aiResponse,
          );
        }

        ////////////////////////////////////////////////////////////////////
        /// Handle errors

        final errorBody = response.body;

        debugPrint(
          'Groq error ${response.statusCode}: $errorBody',
        );

        if (response.statusCode == 429) {
          return AiOcrResult(
            extractedText: extractedText,
            aiResponse:
                'AI limit reached. Your extracted text is still available. '
                'Please try again later.',
          );
        }

        if (response.statusCode == 401) {
          return AiOcrResult(
            extractedText: extractedText,
            aiResponse:
                'Groq API key is invalid. Please check your GROQ_API_KEY.',
          );
        }

        if (response.statusCode == 400) {
          return AiOcrResult(
            extractedText: extractedText,
            aiResponse:
                'Groq rejected the request. Please check the model or request format.',
          );
        }

        if (response.statusCode == 503) {
          return AiOcrResult(
            extractedText: extractedText,
            aiResponse: 'Groq service is temporarily unavailable. '
                'Your extracted text is still available.',
          );
        }

        return AiOcrResult(
          extractedText: extractedText,
          aiResponse: 'AI summary could not be generated. '
              'Your extracted text is still available.\n'
              'Error: HTTP ${response.statusCode}',
        );
      } catch (e) {
        debugPrint('Groq analysis failed: $e');

        return AiOcrResult(
          extractedText: extractedText,
          aiResponse: 'AI summary could not be generated. '
              'Your extracted text is still available.\n'
              'Error: $e',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('OCR ERROR: $e');
      debugPrint('$stackTrace');
      rethrow;
    } finally {
      await textRecognizer.close();

      totalStopwatch.stop();

      debugPrint(
        'Total OCR + analysis time: '
        '${totalStopwatch.elapsed.inSeconds}s',
      );
    }
  }
}

// Result returned by OCR + AI
class AiOcrResult {
  final String extractedText;
  final String aiResponse;

  const AiOcrResult({
    required this.extractedText,
    required this.aiResponse,
  });
}


