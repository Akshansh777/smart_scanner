import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/scanned_document.dart';
import '../controllers/ai_chat_controller.dart';

class AiSummaryScreen extends ConsumerStatefulWidget {
  final ScannedDocument document;

  const AiSummaryScreen({super.key, required this.document});

  @override
  ConsumerState<AiSummaryScreen> createState() => _AiSummaryScreenState();
}

class _AiSummaryScreenState extends ConsumerState<AiSummaryScreen> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiChatControllerProvider(widget.document.id).notifier).generateInitialSummary(
            widget.document.extractedText,
            cachedSummary: widget.document.aiSummary,
          );
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatControllerProvider(widget.document.id));
    final controller = ref.read(aiChatControllerProvider(widget.document.id).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.generateInitialSummary(widget.document.extractedText),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'AI Document Summary',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (chatState.isLoading && chatState.summary.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (chatState.errorMessage != null && chatState.summary.isEmpty)
                        Text(
                          chatState.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        )
                      else
                        MarkdownBody(
                          data: chatState.summary,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (chatState.messages.isNotEmpty) ...[
                  const Text('Follow-up Q&A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...chatState.messages.map((msg) => Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isUser ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg.text, style: const TextStyle(fontSize: 13.5)),
                        ),
                      )),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Ask about this document...',
                      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                  icon: const Icon(Icons.arrow_upward, color: Colors.white),
                  onPressed: () {
                    final text = _questionController.text;
                    if (text.trim().isNotEmpty) {
                      controller.sendQuestion(widget.document.extractedText, text);
                      _questionController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}