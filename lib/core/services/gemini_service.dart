import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  // Replace with your production key injection (e.g. const String.fromEnvironment('GEMINI_API_KEY'))
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_GEMINI_API_KEY');
  return GeminiService(apiKey: apiKey);
});

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        topK: 32,
        topP: 0.9,
      ),
    );
  }

  /// Generates clean, structured Markdown summaries from OCR text
  Future<String> summarizeDocument(String rawOcrText) async {
    if (rawOcrText.trim().isEmpty) {
      return "No text available in this document to summarize.";
    }

    final prompt = '''
You are an expert document analysis engine. Analyze the following document text extracted via OCR.
Provide a clean, readable Markdown response with:
1. **Executive Summary** (1-2 sentences)
2. **Key Highlights & Takeaways** (bullet points)
3. **Important Action Items / Dates / Numbers** (if applicable)

Document Text:
"""
$rawOcrText
"""
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Failed to generate summary.';
  }

  /// Context-aware Q&A against the document contents
  Future<String> askDocumentQuestion({
    required String rawOcrText,
    required String question,
    required List<Map<String, String>> previousConversation,
  }) async {
    final systemPrompt = '''
You are answering questions about the following document text extracted via OCR:
"""
$rawOcrText
"""
Rules:
- Answer accurately based ONLY on the provided document text.
- If the answer cannot be determined from the document, explicitly state that.
- Keep answers clear, professional, and concise.
''';

    final chatHistory = [
      Content.text(systemPrompt),
      ...previousConversation.map((msg) =>
          msg['role'] == 'user'
              ? Content.text(msg['text']!)
              : Content.model([TextPart(msg['text']!)])),
      Content.text(question),
    ];

    final response = await _model.generateContent(chatHistory);
    return response.text ?? "I'm sorry, I couldn't process that question.";
  }
}