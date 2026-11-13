import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/scanned_document.dart';
import '../../home/controllers/document_list_controller.dart';
import '../services/pdf_file_service.dart';
import 'pdf_viewer_screen.dart';

enum DocumentMenuAction { rename, share, export, delete }

class PdfWorkspaceScreen extends ConsumerWidget {
  const PdfWorkspaceScreen({super.key});

  Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
    final fileService = ref.read(pdfFileServiceProvider);
    try {
      final doc = await fileService.importPdfFromDevice();
      if (doc != null && context.mounted) {
        await ref
            .read(documentListControllerProvider.notifier)
            .addDocument(doc);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported "${doc.title}" successfully'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    ScannedDocument document,
  ) async {
    final textController = TextEditingController(text: document.title);
    final formKey = GlobalKey<FormState>();

    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Document'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Document Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title cannot be empty';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, textController.text.trim());
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newTitle != null && newTitle.isNotEmpty && context.mounted) {
      await ref
          .read(documentListControllerProvider.notifier)
          .renameDocument(document.id, newTitle);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Renamed to "$newTitle"')),
        );
      }
    }
  }

  Future<void> _shareDocument(
    BuildContext context,
    WidgetRef ref,
    ScannedDocument document,
  ) async {
    final file = File(document.pdfPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF file not found on device.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fileService = ref.read(pdfFileServiceProvider);
    await fileService.sharePdf(
      pdfPath: document.pdfPath,
      title: document.title,
    );
  }

  Future<void> _exportDocument(
    BuildContext context,
    WidgetRef ref,
    ScannedDocument document,
  ) async {
    final file = File(document.pdfPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF file not found on device.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fileService = ref.read(pdfFileServiceProvider);
    final savedPath = await fileService.exportPdfToDevice(
      pdfPath: document.pdfPath,
      suggestedFileName: document.title,
    );

    if (savedPath != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to $savedPath'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ScannedDocument document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Document'),
          content: Text(
            'Are you sure you want to delete "${document.title}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final fileService = ref.read(pdfFileServiceProvider);
      await fileService.deletePdfFile(document.pdfPath);

      if (context.mounted) {
        await ref
            .read(documentListControllerProvider.notifier)
            .deleteDocument(document.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${document.title}"')),
          );
        }
      }
    }
  }

  void _openDocument(BuildContext context, ScannedDocument document) {
    final file = File(document.pdfPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF file not found on device.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          document: document,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentListControllerProvider);
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Workspace'),
        actions: [
          IconButton(
            tooltip: 'Import PDF',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => _importPdf(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.file_upload_outlined),
        label: const Text('Import PDF'),
        onPressed: () => _importPdf(context, ref),
      ),
      body: documents.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No PDF documents available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan a document or import an existing PDF file from your device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => _importPdf(context, ref),
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Import PDF from Device'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final document = documents[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.red,
                        size: 26,
                      ),
                    ),
                    title: Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            '${document.pageCount} ${document.pageCount == 1 ? "page" : "pages"}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(document.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<DocumentMenuAction>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        switch (action) {
                          case DocumentMenuAction.rename:
                            _showRenameDialog(context, ref, document);
                            break;
                          case DocumentMenuAction.share:
                            _shareDocument(context, ref, document);
                            break;
                          case DocumentMenuAction.export:
                            _exportDocument(context, ref, document);
                            break;
                          case DocumentMenuAction.delete:
                            _showDeleteDialog(context, ref, document);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: DocumentMenuAction.rename,
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: DocumentMenuAction.share,
                          child: Row(
                            children: [
                              Icon(Icons.share_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Share'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: DocumentMenuAction.export,
                          child: Row(
                            children: [
                              Icon(Icons.download_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Export (Save As)'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: DocumentMenuAction.delete,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _openDocument(context, document),
                  ),
                );
              },
            ),
    );
  }
}
