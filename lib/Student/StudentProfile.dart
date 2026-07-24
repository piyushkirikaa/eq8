import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../Library/RestClient.dart';
import '../Service/Analytics.dart';
import '../SignIn.dart';
import '../Widgets/device_status_sheet.dart';
import '../Widgets/ConnectivityIcon.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
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
      body: SingleChildScrollView(
        child: ProfileWidget(),
      ),
    );
  }

  Widget ProfileWidget() {
    return FutureBuilder(
      future: RestClient().authGet("/student/my-profile", {}),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Checking...",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45));
        } else if (snapshot.hasError) {
          return const Center(
              child: Text("Unable to load profile",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45)));
        } else {
          if (snapshot.data['status'] == "success") {
            final APIData = snapshot.data['data'][0];
            return Container(
              margin: const EdgeInsets.all(15),
              child: Column(children: [
                Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Student Information".toUpperCase(),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children:
                            ListTile.divideTiles(context: context, tiles: [
                          ListTile(
                            title: const Text('User ID'),
                            subtitle: Text(APIData['user_id']),
                          ),
                          ListTile(
                            title: const Text('First Name'),
                            subtitle: Text(APIData['first_name']),
                          ),
                          ListTile(
                            title: const Text('Last Name'),
                            subtitle: Text(APIData['last_name']),
                          ),
                          ListTile(
                            title: const Text('Gender'),
                            subtitle: Text(APIData['gender']),
                          ),
                          ListTile(
                            title: const Text('Address'),
                            subtitle: Text(APIData['address']),
                          ),
                          ListTile(
                            title: const Text('City'),
                            subtitle: Text(APIData['city']),
                          ),
                        ]).toList(),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Parent Information".toUpperCase(),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children:
                            ListTile.divideTiles(context: context, tiles: [
                          ListTile(
                            title: const Text('First Name'),
                            subtitle: Text(APIData['parent_first_name']),
                          ),
                          ListTile(
                            title: const Text('Last Name'),
                            subtitle: Text(APIData['parent_last']),
                          ),
                          ListTile(
                            title: const Text('Gender'),
                            subtitle: Text(APIData['parent_gender']),
                          ),
                          ListTile(
                            title: const Text('Address'),
                            subtitle: Text(APIData['parent_address']),
                          ),
                          ListTile(
                            title: const Text('City'),
                            subtitle: Text(APIData['parent_city']),
                          ),
                        ]).toList(),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Enrolment Information".toUpperCase(),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children:
                            ListTile.divideTiles(context: context, tiles: [
                          ListTile(
                            title: const Text('Login ID'),
                            subtitle: Text(APIData['user_id']),
                          ),
                          ListTile(
                            title: const Text('Grade'),
                            subtitle: Text(APIData['grade_name']),
                          ),
                          ListTile(
                            title: const Text('Start Date'),
                            subtitle: Text(APIData['start_date']),
                          ),
                          ListTile(
                            title: const Text('End Date'),
                            subtitle: Text(APIData['end_date']),
                          ),
                        ]).toList(),
                      ),
                    ],
                  ),
                )
              ]),
            );
          } else {
            return const Center(
                child: Text("Unable to load profile",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45)));
          }
        }
      },
    );
  }



  _checkDeviceStatus() async {
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
