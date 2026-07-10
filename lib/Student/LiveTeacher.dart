import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LiveTeacher extends StatefulWidget {
  const LiveTeacher({super.key});

  @override
  State<LiveTeacher> createState() => _LiveTeacherState();
}

class _LiveTeacherState extends State<LiveTeacher> {

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://mydigitalcollege.co.za/ai-teacher/'));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Teacher'),
        backgroundColor: Colors.purple,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
