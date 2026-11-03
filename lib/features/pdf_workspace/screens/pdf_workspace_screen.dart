import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//import '../../../core/models/document_model.dart';
import '../../home/controllers/document_list_controller.dart';
import 'pdf_viewer_screen.dart';

class PdfWorkspaceScreen extends ConsumerWidget {
  const PdfWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Workspace'),
      ),
      body: documents.isEmpty
          ? const Center(
              child: Text('No PDF documents available'),
            )
          : ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final document = documents[index];

                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(document.title),
                  subtitle: Text(
                    '${document.pageCount} pages',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(
                          pdfPath: document.pdfPath,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
