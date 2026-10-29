import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_scanner/features/home/screens/Setting_Icon.dart';
import 'package:smart_scanner/features/home/screens/camera.dart'
    show ScanDocs, camera;
//import '../../../core/models/scanned_document.dart';
import '../controllers/document_list_controller.dart';
//import '../../ai_assistant/screens/ai_summary_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        //elevation: 10,
        toolbarHeight: 120,
        backgroundColor: const Color.fromARGB(255, 255, 252, 252),
        title: Column(
          children: [
            Align(
              alignment: AlignmentGeometry.topLeft,
              child: Row(
                children: [
                  const Text(
                    "AI SCANNER ",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(31, 31, 31, 1),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsIcon(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
            ),
            //SizedBox(height: 2),
            const Align(
              alignment: AlignmentGeometry.topLeft,
              child: Text(
                "SCANNER",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 19, 98, 236),
                ),
              ),
            ),
            const Align(
              alignment: AlignmentGeometry.topLeft,
              child: Text(
                "Scan. Convert. Understand.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight(350)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ScanDocs()));
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  HomepageContainers(
                      iconColor: Colors.blueAccent,
                      ic: Icons.settings_rounded,
                      name: "Scan\nDocuments",
                      onClick: () {
                        Navigator.push(
                          ///access the camera
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ScanDocs()),
                        );
                      }),
                  const HomepageContainers(
                      iconColor: Colors.blue,
                      ic: (Icons.text_snippet_outlined),
                      name: 'Extract\nText (OCR)'),
                  const HomepageContainers(
                    iconColor: Colors.red,
                    ic: Icons.picture_as_pdf_outlined,
                    name: 'View &\nEdit PDF',
                  ),
                  const HomepageContainers(
                      iconColor: Colors.blue,
                      ic: Icons.auto_awesome,
                      name: 'AI Summarize\n& Q&A'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Documents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See All',
                        style: TextStyle(color: Color(0xFF3B82F6))),
                  ),
                ],
              ),
            ),
          ),
          documents.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open,
                            size: 54, color: Colors.grey.shade600),
                        const SizedBox(height: 12),
                        const Text('No documents scanned yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = documents[index];
                      return HomeScreen();
                    },
                    childCount: documents.length,
                  ),
                ),
        ],
      ),
    );
  }
}

class HomepageContainers extends StatelessWidget {
  final IconData ic;
  final String name;
  final Color iconColor;
  final VoidCallback? onClick;

  const HomepageContainers({
    super.key,
    required this.ic,
    required this.name,
    required this.iconColor,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 250,
          width: 190,
          decoration: BoxDecoration(
            color: const Color.fromARGB(66, 248, 245, 245),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(179, 206, 199, 199),
                spreadRadius: 1,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onClick,
                icon: Icon(
                  ic,
                  color: iconColor,
                ),
                iconSize: 40,
              ),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
