import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:async';
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:flutter/services.dart';

class PDFScreen extends StatefulWidget {
  final String? path;

  const PDFScreen({super.key, this.path});

  @override
  State<PDFScreen> createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> with WidgetsBindingObserver {
  // Android PDF viewer variables
  final Completer<PDFViewController> _pdfController =
      Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  // Android WebView variables
  late final WebViewController _webController;

  // Windows WebView variables
  final WebviewController _windowsController = WebviewController();

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _initializeWindowsWebView();
    } else {
      _initializeAndroidWebView();
    }
  }

  Future<void> _initializeWindowsWebView() async {
    try {
      await _windowsController.initialize();
      await _windowsController.setBackgroundColor(Colors.transparent);
      await _windowsController
          .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      // Load PDF using Google Docs viewer or file:// protocol
      String url;
      if (widget.path!.startsWith('http')) {
        url =
            'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.path!)}';
      } else {
        // Convert local file path to file:// URL
        url = 'file:///${widget.path!.replaceAll('\\', '/')}';
      }

      await _windowsController.loadUrl(url);

      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: ${e.code}'),
                Text('Message: ${e.message}'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Continue'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        );
      }
    }
  }

  void _initializeAndroidWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar if needed
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              isReady = true;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              errorMessage = error.description;
            });
          },
        ),
      );

    // Load PDF using Google Docs viewer
    String url;
    if (widget.path!.startsWith('http')) {
      url =
          'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.path!)}';
    } else {
      // For local files, we'll use Google Docs viewer with a publicly accessible URL
      // or you can implement a local file server
      url =
          'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.path!)}';
    }

    _webController.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Document"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: Platform.isWindows ? _buildWindowsView() : _buildAndroidView(),
      floatingActionButton:
          Platform.isWindows ? null : _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Only show floating action button for native PDF view
    if (widget.path != null && !widget.path!.startsWith('http')) {
      return FutureBuilder<PDFViewController>(
        future: _pdfController.future,
        builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
          if (snapshot.hasData && pages! > 0) {
            return FloatingActionButton.extended(
              label: Text("Go to ${pages! ~/ 2}"),
              onPressed: () async {
                await snapshot.data!.setPage(pages! ~/ 2);
              },
            );
          }
          return Container();
        },
      );
    }
    return null;
  }

  Widget _buildWindowsView() {
    return Center(
      child: _windowsController.value.isInitialized
          ? Webview(_windowsController)
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading PDF...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
    );
  }

  Widget _buildAndroidView() {
    // Try to use native PDF viewer first, fallback to WebView
    if (widget.path != null && !widget.path!.startsWith('http')) {
      return _buildNativePDFView();
    } else {
      return _buildWebView();
    }
  }

  Widget _buildNativePDFView() {
    return Stack(
      children: <Widget>[
        PDFView(
          filePath: widget.path,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: true,
          pageSnap: true,
          defaultPage: currentPage!,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            setState(() {
              this.pages = pages;
              isReady = true;
            });
          },
          onError: (error) {
            setState(() {
              errorMessage = error.toString();
            });
            debugPrint('PDF Error: ${error.toString()}');
          },
          onPageError: (page, error) {
            setState(() {
              errorMessage = '$page: ${error.toString()}';
            });
            debugPrint('PDF Page Error: $page: ${error.toString()}');
          },
          onViewCreated: (PDFViewController pdfViewController) {
            _pdfController.complete(pdfViewController);
          },
          onLinkHandler: (String? uri) {
            debugPrint('PDF Link Handler: $uri');
          },
          onPageChanged: (int? page, int? total) {
            debugPrint('PDF Page changed: $page/$total');
            setState(() {
              currentPage = page;
            });
          },
        ),
        errorMessage.isEmpty
            ? !isReady
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Container()
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          errorMessage = '';
                          isReady = false;
                        });
                        _initializeAndroidWebView();
                      },
                      child: const Text('Try WebView'),
                    ),
                  ],
                ),
              )
      ],
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _webController),
        if (!isReady)
          const Center(
            child: CircularProgressIndicator(),
          ),
        if (errorMessage.isNotEmpty)
          Center(
            child: Text(errorMessage),
          ),
      ],
    );
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }
}
