import 'package:ai_doc_scanner/BottomNavigation_pages/homepage/scan_Docs.dart';
import 'package:flutter/material.dart';

import 'homePage_Containers.dart' show HomepageContainers;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
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
                  Text(
                    "AI  DOC ",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(31, 31, 31, 1),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            //SizedBox(height: 2),
            Align(
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
            Align(
              alignment: AlignmentGeometry.topLeft,
              child: Text(
                "Scan. Convert. Understand.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight(350)),
              ),
            ),
          ],
        ),
      ),

      ///////////////////////////////////////////////
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          children: [
            Row(
              children: [
                HomepageContainers(
                  ic: Icons.camera_alt_rounded,
                  name: "Scan Document",
                  onClick: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanDocs()),
                    );
                  },
                ),
                SizedBox(width: 5),
                // HomepageContainers(
                //   ic: Icons.text_decrease_rounded,
                //   name: "Extract Text [ORC]",
                // ),
              ],
            ),
            // Row(
            //   children: [
            //     HomepageContainers(ic: Icons.picture_as_pdf, name: "View PDF"),
            //     SizedBox(width: 5),
            //     HomepageContainers(
            //       ic: Icons.auto_awesome_rounded,
            //       name: "AI Summarize",
            //     ),
            //   ],
            // ),
            SizedBox(height: 5),
            Align(
              alignment: AlignmentGeometry.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Recent Documents",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
