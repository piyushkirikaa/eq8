import 'package:flutter/material.dart';
import '../../Library/RestClient.dart';
import '../../Parent/BuySubscription.dart';
import '../../Parent/ExamLog.dart';
import '../../SignIn.dart';
import 'package:loader_overlay/loader_overlay.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          OutlinedButton(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
              backgroundColor: WidgetStateProperty.all<Color>(Colors.yellow),
            ),
            onPressed: () {
              buySubscription();
            },
            child: const Text("Buy Subscription"),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'log',
            onPressed: () async {
              logout();
            },
          ),
        ],
      ),
      body: FutureBuilder(
          future: getSubscriptionsList(),
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: RestClient().loader(),
              ); // Show a loading indicator while waiting for the future to complete
            } else if (snapshot.hasError) {
              return Text(
                  'Error: ${snapshot.error}'); // Show an error message if the future throws an error
            } else {
              if (snapshot.hasData) {
                final data = snapshot.data;
                final dataLength = snapshot.data?.length;
                return ListView.builder(
                    itemCount: dataLength,
                    itemBuilder: (context, index) {
                      final subscriptions = data![index];
                      return InkWell(
                        onTap: () async {
                          examLog(subscriptions['student_id'].toString());
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                              left: 15, right: 15, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(
                                    alpha:
                                        0.3), // Customize shadow color and opacity
                                spreadRadius: 2, // Customize the spread radius
                                blurRadius: 5, // Customize the blur radius
                                offset: const Offset(
                                    0, 1), // Customize the shadow offset
                              ),
                            ],
                            borderRadius: BorderRadius.circular(5.0),
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Colors.blueAccent,
                                Colors.blueAccent.shade200,
                                Colors.blueAccent
                              ], // Customize gradient colors
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "${subscriptions['first_name']} ${subscriptions['last_name']}",
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${subscriptions['grade_name']}",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 8, bottom: 8),
                                  child: Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Colors.black12),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Start Date".toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    Text("End Date".toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    Text("Status".toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ],
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        "${subscriptions['start_date']}"
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.black38)),
                                    Text(
                                        "${subscriptions['start_date']}"
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.black38)),
                                    Text(
                                        "${subscriptions['membership_status']}"
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.black38)),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 8, bottom: 8),
                                  child: Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Colors.black12),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Pay By".toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    Text("FEE".toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    Text("Status".toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ],
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        "${subscriptions['pay_by']}"
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.black38)),
                                    Text(
                                        "USD ${subscriptions['total_amount']}"
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.black38)),
                                    Text(
                                        "${subscriptions['payment_status']}"
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.black38)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
              } else {
                return Center(
                  child: Text("NO DATA FOUND".toUpperCase()),
                );
              }
            }
          }),
    );
  }

  getSubscriptionsList() async {
    try {
      final response = await RestClient().authGet('/parent/subscriptions', {});
      if (response["status"] == 'success') {
        return response["data"];
      } else {
        RestClient().error(response["data"].toString());
        return ""; // Return an empty list in case of an error
      }
    } finally {
      if (context.mounted) {
        context.loaderOverlay.hide();
      }
    }
  }

  void examLog(studentID) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExamLog(tutorialID: studentID)),
    );
  }

  void logout() async {
    if (context.mounted) {
      context.loaderOverlay.show();
    }
    await RestClient().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignIn()),
    );
  }

  void buySubscription() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BuySubscription()),
    );
  }
}
