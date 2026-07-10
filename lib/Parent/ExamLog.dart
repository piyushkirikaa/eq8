import 'package:flutter/material.dart';
import '../Library/RestClient.dart';

class ExamLog extends StatefulWidget {
  final dynamic tutorialID;
  const ExamLog({super.key, required this.tutorialID});
  @override
  State<ExamLog> createState() => _ExamHistoryState();
}

class _ExamHistoryState extends State<ExamLog> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam History'),
      ),
      body: FutureBuilder(
          future: getExamList(),
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: RestClient().loader(),
              ); // Show a loading indicator while waiting for the future to complete
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}'); // Show an error message if the future throws an error
            } else {
              if (snapshot.hasData) {
                final data = snapshot.data;
                final dataLength = snapshot.data?.length;
                if(dataLength > 0 ) {
                  return ListView.builder(
                      itemCount: dataLength,
                      itemBuilder: (context, index) {
                        final tutorial = data![index];
                        return Column(
                          children: [
                            ListTile(
                              leading: statusImage(tutorial['status']),
                              title: Text('${tutorial['subject_name']} exam taken on ${tutorial['created_at']}',
                                  style: const TextStyle(color: Colors.black)),
                              subtitle: Text(
                                  "Passing marks was ${tutorial['passing_marks']} and marks get ${tutorial['exam_number']}"),
                              contentPadding: const EdgeInsets.only(
                                  right: 10, left: 10),
                            ),
                            Container(height: 1, color: Colors.black12,)
                          ],
                        );
                      });
                } else {
                  return Center(
                    child: Text("NO DATA FOUND".toUpperCase()),
                  );
                }
              } else {
                return Center(
                  child: Text("NO DATA FOUND".toUpperCase()),
                );
              }
            }
          }),
    );
  }

  Widget statusImage(status){
    if(status == "Pass"){
     return  const Image(image: AssetImage('assets/Images/pass.png'), width: 65);
    } else if (status == "Fail"){
      return const Image(image: AssetImage('assets/Images/fail.png'), width: 65);
    } else {
      return const Image(image: AssetImage('assets/Images/warning.png'), width: 65);
    }
  }

  getExamList() async {
    final response = await RestClient().authGet('/parent/exams/${widget.tutorialID}', {});
    if (response["status"] == 'success') {
      return response["data"];
    } else {
      RestClient().error(response["data"].toString());
      return []; // Return an empty list in case of an error
    }
  }

}
