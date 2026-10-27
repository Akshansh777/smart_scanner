import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/scanned_document.dart';
import '../../../core/services/database_service.dart';

final documentListControllerProvider =
    StateNotifierProvider<DocumentListController, List<ScannedDocument>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return DocumentListController(dbService);
});

class DocumentListController extends StateNotifier<List<ScannedDocument>> {
  final DatabaseService _dbService;

  DocumentListController(this._dbService) : super([]) {
    loadDocuments();
  }

  void loadDocuments() {
    state = _dbService.getAllDocuments();
  }

  Future<void> addDocument(ScannedDocument doc) async {
    await _dbService.saveDocument(doc);
    loadDocuments();
  }

  Future<void> updateDocumentSummary(String docId, String summary) async {
    final existing = _dbService.getDocument(docId);
    if (existing != null) {
      final updated = existing.copyWith(aiSummary: summary);
      await _dbService.saveDocument(updated);
      loadDocuments();
    }
  }

  Future<void> deleteDocument(String id) async {
    await _dbService.deleteDocument(id);
    loadDocuments();
  }
}