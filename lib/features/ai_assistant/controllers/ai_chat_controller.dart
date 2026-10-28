import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/gemini_service.dart';
import '../../home/controllers/document_list_controller.dart';

final aiChatControllerProvider =
    StateNotifierProvider.family<AiChatController, AiChatState, String>(
        (ref, documentId) {
  final gemini = ref.watch(geminiServiceProvider);
  final docController = ref.read(documentListControllerProvider.notifier);
  return AiChatController(
    geminiService: gemini,
    docController: docController,
    documentId: documentId,
  );
});

class AiChatState {
  final bool isLoading;
  final String summary;
  final List<ChatMessage> messages;
  final String? errorMessage;

  AiChatState({
    this.isLoading = false,
    this.summary = '',
    this.messages = const [],
    this.errorMessage,
  });

  AiChatState copyWith({
    bool? isLoading,
    String? summary,
    List<ChatMessage>? messages,
    String? errorMessage,
  }) {
    return AiChatState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      messages: messages?? this.messages,
      errorMessage: errorMessage,
    );
  }
}

class AiChatController extends StateNotifier<AiChatState> {
  final GeminiService _geminiService;
  final DocumentListController _docController;
  final String documentId;
  final _uuid = const Uuid();

  AiChatController({
    required GeminiService geminiService,
    required DocumentListController docController,
    required this.documentId,
  })  : _geminiService = geminiService,
        _docController = docController,
        super(AiChatState());

  Future<void> generateInitialSummary(String rawText,
      {String? cachedSummary}) async {
    if (cachedSummary != null && cachedSummary.isNotEmpty) {
      state = state.copyWith(summary: cachedSummary);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summary = await _geminiService.summarizeDocument(rawText);
      state = state.copyWith(isLoading: false, summary: summary);
      await _docController.updateDocumentSummary(documentId, summary);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to generate summary: ${e.toString()}',
      );
    }
  }

  Future<void> sendQuestion(String rawText, String question) async {
    if (question.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: question.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final history = state.messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'text': m.text,
              })
          .toList();

      final answer = await _geminiService.askDocumentQuestion(
        rawOcrText: rawText,
        question: question,
        previousConversation: history,
      );

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        text: answer,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        isLoading: false,
        messages: [...state.messages, aiMsg],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get answer: ${e.toString()}',
      );
    }
  }
}
