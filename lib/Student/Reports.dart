import 'package:flutter/material.dart';

import '../Library/RestClient.dart';
import '../Service/Analytics.dart';
import '../SignIn.dart';
import 'StudentProfile.dart';

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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: interNetCheck(),
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
              return Text('Error: ${snapshot.error}'); // Show an error message if the future throws an error
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
                            title: Text('${tutorial['key']} action is taken on ${tutorial['created_at']}', style: const TextStyle(color: Colors.black)),
                            subtitle: Text("Subject: ${tutorial['value']['subject_name'].toString()=='null' ? "N/A" : tutorial['value']['subject_name']} and Video:  ${tutorial['value']['video'].toString()=='null' ? "N/A" : tutorial['value']['video']}"),
                            contentPadding: const EdgeInsets.only(right: 10, left: 10),
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
            }
          }),
    );
  }

  Widget statusImage(status){
    if(status == "CHECK_EXAM_HISTORY"){
      return  const Icon(Icons.receipt_long, weight: 65,);
    } else if (status == "VIEW_SUBJECT"){
      return  const Icon(Icons.book, weight: 65,);
    } else if (status == "login"){
      return  const Icon(Icons.account_circle_outlined, weight: 65,);
    } else if (status == "START_EXAM"){
      return  const Icon(Icons.pages_rounded, weight: 65,);
    } else if (status == "WATCH_VIDEO"){
      return  const Icon(Icons.video_camera_back_outlined, weight: 65,);
    } else {
      return  const Icon(Icons.receipt_long, weight: 65,);
    }
  }

  Log() async {
    final response = await RestClient().authGet('/student/activity', {});
    if (response["status"] == 'success') {
      return response["data"];
    } else {
      RestClient().error(response["data"].toString());
      return []; // Return an empty list in case of an error
    }
  }

  Widget interNetCheck(){
    return FutureBuilder(
      future: RestClient().checkInternetConnection(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Icon(Icons.wifi_find_outlined);
        } else if (snapshot.hasError) {
          return const Icon(Icons.wifi_find_outlined);
        } else {
          if(snapshot.data){
            return const Icon(Icons.wifi);
          } else {
            return const Icon(Icons.wifi_off);
          }
        }
      },
    );
  }
  _checkDeviceStatus() async {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.purple,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Device Status'.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Container(
                    margin: const EdgeInsets.all(15),
                    child: Center(child: deviceStatusWidget())
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget deviceStatusWidget(){
    return FutureBuilder(
      future: RestClient().checkInternetConnection(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Checking..." , style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white));
        } else if (snapshot.hasError) {
          return const Text("We are unable to check device status." , style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white));
        } else {
          if(snapshot.data){
            return const Text("Awesome! You're connected. All system go!. " , style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white));
          } else {
            return const Text("Oops! Looks like you're offline. Check your connection, and let's get back on track." , style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red));
          }
        }
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
                Center(child: Text('Are You Sure?'.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                const SizedBox(height: 5,),
                Center(child: Text('All Your Offline Data Will Lost'.toUpperCase(), style: const TextStyle(fontSize: 16))),
                const Divider(),
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black,),
                    onPressed: () async {
                      Navigator.pop(context);
                      logout();
                    },
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
    await Analytics().logEvent('logout',{});
    await RestClient().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignIn()),
    );
  }

}
