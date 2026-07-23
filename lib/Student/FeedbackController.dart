import 'package:flutter/material.dart';

import '../Library/RestClient.dart';
import '../Library/StyleConfig.dart';

class FeedbackController extends StatefulWidget {
  final dynamic tutorial;

  const FeedbackController({super.key, this.tutorial});

  @override
  State<FeedbackController> createState() => _FeedbackControllerState();
}

class _FeedbackControllerState extends State<FeedbackController> {
  String _feedback = "";
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    final outlineInputBorderStyle = OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(width: 1));

    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(width: 1, style: BorderStyle.solid),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Your Feedback"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 15,
            ),
            Container(
              height: 200,
              width: width,
              margin: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                minLines: 50, // Minimum number of lines
                maxLines: 50, // Allows for growth
                onChanged: (value) {
                  setState(() {
                    _feedback = value;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(15),
                  hintText: "Enter Your Feedback",
                  hintStyle: const TextStyle(),
                  filled: true,
                  focusColor: Colors.blueAccent,
                  enabledBorder: outlineInputBorderStyle,
                  fillColor: Colors.white,
                  border: borderStyle,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 15, right: 15),
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        await submitFeedback();
                      },
                style: StyleConfig.feedbackButtonStyle,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text("SUBMIT YOUR FEEDBACK",
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> submitFeedback() async {
    if (_feedback.trim().isEmpty) {
      RestClient().error("Please enter your Feedback.");
    } else if (_isSubmitting) {
      return;
    } else {
      setState(() {
        _isSubmitting = true;
      });
      try {
        final response = await RestClient().authPost('/student/feedback', {
          'feedback': _feedback.trim(),
          'tutorial_id': widget.tutorial['id'].toString()
        }).timeout(const Duration(seconds: 20));
        if (!mounted) return;
        if (response['status'] == 'success') {
          RestClient().success("Your feedback has been submitted successfully.");
          Navigator.pop(context);
        } else {
          RestClient().error(
              response['message']?.toString() ?? "Feedback submission failed");
        }
      } catch (e) {
        if (mounted) {
          RestClient().error("Feedback submission failed. Please try again.");
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }
}
