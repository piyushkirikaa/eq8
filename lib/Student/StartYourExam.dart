import 'package:flutter/material.dart';
import '../../Student/Test.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../Library/RestClient.dart';

class StartYourExam extends StatefulWidget {
  final dynamic tutorial;
  const StartYourExam({super.key, required this.tutorial});

  @override
  State<StartYourExam> createState() => _StartYourExamState();
}

class _StartYourExamState extends State<StartYourExam> {
  double contentSpaceing = 25;
  String examType = "Tutorial Specific";

  late BuildContext globalScaffoldContext;

  @override
  Widget build(BuildContext context) {
    globalScaffoldContext = context;
    var tutorial = widget.tutorial;

    return Scaffold(
      appBar: AppBar(
          title: Text(
        'Your test is ready'.toUpperCase(),
        style: const TextStyle(color: Colors.white),
      )),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: contentSpaceing, right: 15, left: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 75,
              width: MediaQuery.of(context).size.width,
              child: const Image(
                  image: AssetImage('assets/Images/icons8-approval-64.png')),
            ),
            const Text('Your test is ready!',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 26)),
            Container(
              height: 15,
            ),
            const Text('Your customized test has been successfully generated.',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            Container(
              height: contentSpaceing,
            ),
            Container(
              height: 500,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: Colors.grey.shade200),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 15, right: 15, top: 20),
                    height: 30,
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                      child: Text(
                        tutorial['subject_name'].toString().toUpperCase(),
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 23,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 18, right: 18, top: 18),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.access_time_filled,
                              color: Colors.black),
                          title: Text('Time allowed',
                              style: TextStyle(color: Colors.grey)),
                          trailing: Text('5',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17)),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.message_rounded,
                              color: Colors.black),
                          title: const Text('No: of Questions',
                              style: TextStyle(color: Colors.grey)),
                          trailing: Text(tutorial['load_q_per_exam'].toString(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17)),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.message_rounded,
                              color: Colors.black),
                          title: const Text('Total Marks',
                              style: TextStyle(color: Colors.grey)),
                          trailing: Text(tutorial['passing_marks'].toString(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17)),
                        ),
                        const Divider(),
                        ListTile(
                          onTap: selectExamType,
                          leading: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.white),
                            child: const Icon(Icons.account_tree_outlined,
                                color: Colors.black),
                          ),
                          title: const Text('Select Exam Type',
                              style: TextStyle(color: Colors.grey)),
                          subtitle: Text(examType.toString(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17)),
                        ),
                        Container(
                          height: 14,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 20,
                  ),
                  Container(
                    height: 55,
                    margin: const EdgeInsets.only(left: 18, right: 18),
                    decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8)),
                    width: MediaQuery.of(context).size.width,
                    child: OutlinedButton(
                      style: ButtonStyle(
                        side: WidgetStateProperty.all<BorderSide>(
                          const BorderSide(
                              color: Colors
                                  .purple), // Set the border color to yellow
                        ),
                      ),
                      onPressed: createExam,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Start your Test'.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          const SizedBox(
                            width: 10,
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  selectExamType() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        const textStyle = TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
        return Container(
          height: 360,
          color: Colors.blue,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Select Exam Type'.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Container(
                  child: Column(
                    children: [
                      ListTile(
                        title:
                            const Text('Tutorial Specific', style: textStyle),
                        onTap: () {
                          setState(() {
                            examType = "Tutorial Specific";
                          });
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Lower Order', style: textStyle),
                        onTap: () {
                          setState(() {
                            examType = "Lower Order";
                          });
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Medium Order', style: textStyle),
                        onTap: () {
                          setState(() {
                            examType = "Medium Order";
                          });
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Higher Order', style: textStyle),
                        onTap: () {
                          setState(() {
                            examType = "Higher Order";
                          });
                          Navigator.pop(context);
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  createExam() async {
    globalScaffoldContext.loaderOverlay.show();
    final response = await RestClient().authPost('/student/exam/create', {
      'tutorial_id': widget.tutorial['id'].toString(),
      'subject_id': widget.tutorial['subject_id'].toString(),
      'grade_id': widget.tutorial['grade_id'].toString(),
      'exam_type': examType,
    });
    if (response['status'] == "success") {
      if (mounted) {
        globalScaffoldContext.loaderOverlay.hide();
        startExam(response);
      }
    } else {
      RestClient().error(response['message'].toString());
    }
  }

  startExam(response) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Test(
                tutorial: widget.tutorial,
                examConfig: response['data'],
              )),
    );
  }
}
