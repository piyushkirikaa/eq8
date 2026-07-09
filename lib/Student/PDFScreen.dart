import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PDFScreen extends StatelessWidget {
  final String? path;

  const PDFScreen({super.key, this.path});

  bool get _isRemote =>
      path != null &&
      (path!.startsWith('http://') || path!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document'),
      ),
      body: _buildViewer(),
    );
  }

  Widget _buildViewer() {
    if (path == null || path!.isEmpty) {
      return const Center(child: Text('No PDF file specified'));
    }

    final params = PdfViewerParams(
      enableTextSelection: true,
      backgroundColor: const Color(0xFF525659),
      loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
        final progress = totalBytes != null && totalBytes > 0
            ? bytesDownloaded / totalBytes
            : null;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(value: progress, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                totalBytes != null
                    ? 'Loading PDF... ${(bytesDownloaded / 1024 / 1024).toStringAsFixed(1)} MB'
                    : 'Loading PDF...',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );
      },
      errorBannerBuilder: (context, error, stackTrace, docRef) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load PDF',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (_isRemote) {
      return PdfViewer.uri(Uri.parse(path!), params: params);
    } else {
      return PdfViewer.file(path!, params: params);
    }
  }
}
