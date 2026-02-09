import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pdfrx/pdfrx.dart';
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
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    debugPrint('========== PDFScreen initState ==========');
    debugPrint('PDF Path: ${widget.path}');
    debugPrint('Platform: ${Platform.operatingSystem}');

    if (!Platform.isWindows) {
      _initializeAndroidWebView();
    }
  }

  // For Android, we use custom WebView with secure PDF viewer
  Future<String> _getCustomHtmlViewer() async {
    try {
      // Load the custom HTML viewer template
      String htmlContent =
          await rootBundle.loadString('assets/html/pdf_viewer.html');

      debugPrint('HTML template loaded successfully');

      String pdfUrl;

      // Check if it's a remote URL or local file
      if (widget.path!.startsWith('http')) {
        // Remote URL - use as is
        pdfUrl = widget.path!;
        debugPrint('Using remote PDF URL: $pdfUrl');
      } else {
        // Local file - convert to base64 data URL to avoid CORS issues
        try {
          final file = File(widget.path!);
          debugPrint('Checking if file exists: ${widget.path}');

          if (!await file.exists()) {
            debugPrint('ERROR: File does not exist!');
            throw Exception('File not found: ${widget.path!}');
          }

          debugPrint('File exists, reading bytes...');
          final bytes = await file.readAsBytes();
          debugPrint(
              'PDF file size: ${bytes.length} bytes (${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');

          debugPrint('Converting to base64...');
          final base64Pdf = base64Encode(bytes);
          debugPrint('Base64 length: ${base64Pdf.length} characters');

          pdfUrl = 'data:application/pdf;base64,$base64Pdf';
          debugPrint('PDF converted to base64 successfully');
        } catch (e) {
          debugPrint('Error reading PDF file: $e');
          throw Exception('Failed to load PDF: $e');
        }
      }

      // Replace the getPdfUrl function to return our PDF URL directly
      // Properly escape the string for JavaScript
      final escapedPdfUrl = pdfUrl
          .replaceAll(r'\', r'\\')
          .replaceAll("'", r"\'")
          .replaceAll('\n', r'\n')
          .replaceAll('\r', r'\r')
          .replaceAll('\t', r'\t');

      htmlContent = htmlContent.replaceAll(
          'const pdfUrl = getPdfUrl();', "const pdfUrl = '$escapedPdfUrl';");

      debugPrint('HTML content prepared, total length: ${htmlContent.length}');
      debugPrint(
          'PDF URL embedded successfully (first 100 chars): ${pdfUrl.substring(0, pdfUrl.length > 100 ? 100 : pdfUrl.length)}');
      return htmlContent;
    } catch (e) {
      debugPrint('ERROR in _getCustomHtmlViewer: $e');
      rethrow;
    }
  }

  void _initializeAndroidWebView() async {
    try {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..addJavaScriptChannel(
          'FlutterLog',
          onMessageReceived: (JavaScriptMessage message) {
            debugPrint('JS >>> ${message.message}');
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              debugPrint('WebView loading progress: $progress%');
            },
            onPageStarted: (String url) {
              debugPrint('WebView page started: $url');
            },
            onPageFinished: (String url) {
              debugPrint('WebView page finished: $url');

              // Inject JavaScript to capture console logs and errors
              _webController!.runJavaScript('''
                // Capture console logs
                const originalLog = console.log;
                const originalError = console.error;
                
                console.log = function(...args) {
                  originalLog.apply(console, args);
                  window.flutter_log = args.join(' ');
                };
                
                console.error = function(...args) {
                  originalError.apply(console, args);
                  window.flutter_error = args.join(' ');
                };
                
                // Log PDF URL length for debugging
                if (typeof pdfUrl !== 'undefined') {
                  console.log('PDF URL type: ' + (pdfUrl.startsWith('data:') ? 'base64' : 'url'));
                  console.log('PDF URL length: ' + pdfUrl.length);
                }
              ''');

              // Set up periodic check to retrieve JavaScript console logs
              Future.delayed(const Duration(seconds: 2), () {
                _webController!
                    .runJavaScriptReturningResult('window.flutter_log || ""')
                    .then((log) {
                  if (log.toString().isNotEmpty && log.toString() != '""') {
                    debugPrint('JS Log: $log');
                  }
                });
                _webController!
                    .runJavaScriptReturningResult('window.flutter_error || ""')
                    .then((error) {
                  if (error.toString().isNotEmpty && error.toString() != '""') {
                    debugPrint('JS Error: $error');
                  }
                });
              });

              setState(() {
                isReady = true;
              });
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView error: ${error.description}');
              debugPrint('WebView error type: ${error.errorType}');
              debugPrint('WebView error code: ${error.errorCode}');
              setState(() {
                errorMessage = error.description;
              });
            },
          ),
        )
        ..enableZoom(true);

      debugPrint('Loading PDF from: ${widget.path}');

      // Get custom HTML viewer with PDF URL embedded
      String htmlContent = await _getCustomHtmlViewer();

      debugPrint('HTML content length: ${htmlContent.length}');

      // Convert HTML to base64 data URL for Android WebView
      final String contentBase64 =
          base64Encode(const Utf8Encoder().convert(htmlContent));
      final String dataUrl = 'data:text/html;base64,$contentBase64';

      await _webController!.loadRequest(Uri.parse(dataUrl));

      // Trigger UI update to show WebView
      if (mounted) {
        setState(() {});
      }
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
      ),
      body: Platform.isWindows ? _buildWindowsView() : _buildAndroidView(),
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
    // Use pdfrx for Windows - native, fast, no WebView needed
    if (widget.path == null || widget.path!.isEmpty) {
      return const Center(
        child: Text('No PDF file specified'),
      );
    }

    return PdfViewer.file(
      widget.path!,
      params: PdfViewerParams(
        enableTextSelection: false,
        backgroundColor: const Color(0xFF525659),
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading PDF...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        },
        errorBannerBuilder: (context, error, stackTrace, docRef) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load PDF',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAndroidView() {
    // Always use our custom WebView with secure PDF viewer
    return _buildWebView();
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
    if (_webController == null) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing PDF viewer...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webController!),
        if (!isReady)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
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
            ),
          ),
        if (errorMessage.isNotEmpty)
          Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          errorMessage = '';
                          isReady = false;
                        });
                        _initializeAndroidWebView();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    // pdfrx and WebView handle cleanup automatically
    super.dispose();
  }
}
