import 'package:flutter/material.dart';

import '../Library/RestClient.dart';
import '../Library/StyleConfig.dart';

class FeedbackController extends StatefulWidget {

  final tutorial;

  const FeedbackController({super.key, this.tutorial});

  @override
  State<FeedbackController> createState() => _FeedbackControllerState();
}

class _FeedbackControllerState extends State<FeedbackController> {

  String _feedback = "";

  @override
  Widget build(BuildContext context) {

    double width = MediaQuery.of(context).size.width;

    final outlineInputBorderStyle = OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(width: 1)
    );

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
            const SizedBox(height: 15,),
            Container(
              height: 200,
              width: width,
              margin: const EdgeInsets.only(left: 15,right: 15),
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
            const SizedBox(height: 15,),
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 15, right: 15),
              child: OutlinedButton(
                onPressed:()async{
                  await submitFeedback();
                },
                style:  StyleConfig.feedbackButtonStyle,
                child: const Text("SUBMIT YOUR FEEDBACK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  submitFeedback()async {
    if (_feedback.isEmpty) {
      RestClient().error("Please enter your feedback");
    } else {
      final response = await RestClient().authPost('/student/feedback', {
        'feedback' : _feedback,
        'tutorial_id' : widget.tutorial['id'].toString()
      });
      print(response);
      RestClient().success("Your feedback Submitted successfully");
      Navigator.pop(context);
    }
  }

}
