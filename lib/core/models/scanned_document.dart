class ScannedDocument {
  final String id;
  final String title;
  final String pdfPath;
  final String? thumbnailPath;
  final int pageCount;
  final DateTime createdAt;
  final String extractedText;
  final String? aiSummary;

  const ScannedDocument({
    required this.id,
    required this.title,
    required this.pdfPath,
    this.thumbnailPath,
    required this.pageCount,
    required this.createdAt,
    required this.extractedText,
    this.aiSummary,
  });

  ScannedDocument copyWith({
    String? id,
    String? title,
    String? pdfPath,
    String? thumbnailPath,
    int? pageCount,
    DateTime? createdAt,
    String? extractedText,
    String? aiSummary,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      pdfPath: pdfPath ?? this.pdfPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      extractedText: extractedText ?? this.extractedText,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'pdfPath': pdfPath,
      'thumbnailPath': thumbnailPath,
      'pageCount': pageCount,
      'createdAt': createdAt.toIso8601String(),
      'extractedText': extractedText,
      'aiSummary': aiSummary,
    };
  }

  factory ScannedDocument.fromMap(Map<dynamic, dynamic> map) {
    return ScannedDocument(
      id: map['id'] as String,
      title: map['title'] as String,
      pdfPath: map['pdfPath'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      pageCount: map['pageCount'] as int? ?? 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      extractedText: map['extractedText'] as String? ?? '',
      aiSummary: map['aiSummary'] as String?,
    );
  }
}