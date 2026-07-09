import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:window_manager/window_manager.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class LiveTeacherWindows extends StatefulWidget {
  const LiveTeacherWindows({super.key});

  @override
  State<LiveTeacherWindows> createState() => _LiveTeacherWindowsState();
}

class _LiveTeacherWindowsState extends State<LiveTeacherWindows> {
  final WebviewController _controller = WebviewController();
  final bool _isWebviewSuspended = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl('https://mydigitalcollege.co.za/ai-teacher/');

      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<String>(
          stream: _controller.title,
          builder: (context, snapshot) {
            return Text(snapshot.hasData
                ? snapshot.data!
                : 'WebView (Windows) Example');
          },
        ),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? Webview(_controller)
            : const Text(
                'Not Initialized',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w900),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
