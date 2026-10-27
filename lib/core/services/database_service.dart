import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/scanned_document.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class DatabaseService {
  static const String boxName = 'scanned_documents_box';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  Box get _box => Hive.box(boxName);

  List<ScannedDocument> getAllDocuments() {
    return _box.values
        .map((entry) => ScannedDocument.fromMap(entry as Map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveDocument(ScannedDocument doc) async {
    await _box.put(doc.id, doc.toMap());
  }

  Future<void> deleteDocument(String id) async {
    await _box.delete(id);
  }

  ScannedDocument? getDocument(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return ScannedDocument.fromMap(data as Map);
  }
}