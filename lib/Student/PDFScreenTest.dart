import 'package:flutter/material.dart';
import 'dart:io';
import 'PDFScreen.dart';

class PDFScreenTest extends StatelessWidget {
  const PDFScreenTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'PDF Screen Test - ${Platform.isWindows ? 'Windows' : 'Android'}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Platform: ${Platform.isWindows ? 'Windows' : 'Android'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              Platform.isWindows
                  ? 'Using webview_windows for PDF display'
                  : 'Using flutter_pdfview (native) or webview_flutter (fallback)',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PDFScreen(
                      path:
                          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                    ),
                  ),
                );
              },
              child: const Text('Test with Online PDF'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PDFScreen(
                      path: 'assets/sample.pdf', // This would be a local file
                    ),
                  ),
                );
              },
              child: const Text('Test with Local PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
