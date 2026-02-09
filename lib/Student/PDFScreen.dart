import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
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

  Future<String> _getCustomHtmlViewer() async {
    // Load the custom HTML viewer template
    String htmlContent =
        await rootBundle.loadString('assets/html/pdf_viewer.html');

    // Prepare PDF URL
    String pdfUrl = widget.path!;
    if (!Platform.isWindows && !pdfUrl.startsWith('http')) {
      // For local files on Android
      pdfUrl = 'file://$pdfUrl';
    } else if (Platform.isWindows && !pdfUrl.startsWith('http')) {
      // For local files on Windows
      pdfUrl = 'file:///${pdfUrl.replaceAll(r'\', '/')}';
    }

    // Replace the getPdfUrl function to return our PDF URL directly
    htmlContent = htmlContent.replaceAll(
        'const pdfUrl = getPdfUrl();', 'const pdfUrl = "$pdfUrl";');

    return htmlContent;
  }

  Future<void> _initializeWindowsWebView() async {
    try {
      await _windowsController.initialize();
      await _windowsController.setBackgroundColor(Colors.transparent);
      await _windowsController
          .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      // Get custom HTML viewer with PDF URL embedded
      String htmlContent = await _getCustomHtmlViewer();

      // Load the HTML content directly
      await _windowsController.loadStringContent(htmlContent);

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

  void _initializeAndroidWebView() async {
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

    // Get custom HTML viewer with PDF URL embedded
    try {
      String htmlContent = await _getCustomHtmlViewer();

      // Convert HTML to base64 data URL for Android WebView
      final String contentBase64 =
          base64Encode(const Utf8Encoder().convert(htmlContent));
      final String dataUrl = 'data:text/html;base64,$contentBase64';

      _webController.loadRequest(Uri.parse(dataUrl));
    } catch (e) {
      debugPrint('Error loading custom PDF viewer: $e');
      setState(() {
        errorMessage = 'Error loading PDF viewer: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Document"),
        // Removed share button to prevent document sharing
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
