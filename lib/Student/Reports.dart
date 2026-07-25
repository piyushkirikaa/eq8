import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../Library/RestClient.dart';
import '../Service/Analytics.dart';
import '../SignIn.dart';
import 'StudentProfile.dart';
import '../Widgets/device_status_sheet.dart';
import '../Widgets/ConnectivityIcon.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const ConnectivityIcon(),
            onPressed: () async {
              await _checkDeviceStatus();
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_box_outlined),
            tooltip: 'profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentProfile()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'log',
            onPressed: () async {
              alertOption();
            },
          ),
        ],
      ),
      body: FutureBuilder(
          future: Log(),
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
                      final tutorial = data![index];
                      return Column(
                        children: [
                          ListTile(
                            leading: statusImage(tutorial['key']),
                            title: Text(
                                '${tutorial['key']} action is taken on ${tutorial['created_at']}',
                                style: const TextStyle(color: Colors.black)),
                            subtitle: Text(
                                "Subject: ${tutorial['value']['subject_name'].toString() == 'null' ? "N/A" : tutorial['value']['subject_name']} and Video:  ${tutorial['value']['video'].toString() == 'null' ? "N/A" : tutorial['value']['video']}"),
                            contentPadding:
                                const EdgeInsets.only(right: 10, left: 10),
                          ),
                          Container(
                            height: 1,
                            color: Colors.black12,
                          )
                        ],
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

  Widget statusImage(status) {
    if (status == "CHECK_EXAM_HISTORY") {
      return const Icon(
        Icons.receipt_long,
        weight: 65,
      );
    } else if (status == "VIEW_SUBJECT") {
      return const Icon(
        Icons.book,
        weight: 65,
      );
    } else if (status == "login") {
      return const Icon(
        Icons.account_circle_outlined,
        weight: 65,
      );
    } else if (status == "START_EXAM") {
      return const Icon(
        Icons.pages_rounded,
        weight: 65,
      );
    } else if (status == "WATCH_VIDEO") {
      return const Icon(
        Icons.video_camera_back_outlined,
        weight: 65,
      );
    } else {
      return const Icon(
        Icons.receipt_long,
        weight: 65,
      );
    }
  }

  Future<dynamic> Log() async {
    final response = await RestClient().authGet('/student/activity', {});
    if (response["status"] == 'success') {
      return response["data"];
    } else {
      RestClient().error(response["data"].toString());
      return []; // Return an empty list in case of an error
    }
  }



  Future<void> _checkDeviceStatus() async {
    if (mounted) {
      context.loaderOverlay.show();
    }
    final isConnected = await RestClient().checkInternetConnection();
    if (mounted) {
      context.loaderOverlay.hide();
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return DeviceStatusSheet(isConnected: isConnected);
      },
    );
  }

  Future<void> alertOption() {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                    child: Text('Are You Sure?'.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold))),
                const SizedBox(
                  height: 5,
                ),
                Center(
                    child: Text('All Your Offline Data Will Lost'.toUpperCase(),
                        style: const TextStyle(fontSize: 16))),
                const Divider(),
                Center(
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      logout();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.logout,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void logout() async {
    if (mounted) {
      context.loaderOverlay.show();
    }
    try {
      await Analytics().logEvent('logout', {});
    } catch (e) {
      print('Error logging event: $e');
    }
    try {
      await RestClient().logout();
    } catch (e) {
      print('Error during logout: $e');
    }
    if (mounted) {
      context.loaderOverlay.hide();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignIn()),
      );
    }
  }
}
