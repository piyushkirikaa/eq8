import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../../Student/StudentProfile.dart';
import '../../SignIn.dart';
import '../../Student/Subject.dart';
import '../Library/RestClient.dart';
import '../Service/Analytics.dart';
import '../Widgets/Course.dart';
import '../Widgets/CourseCard.dart';
import '../Widgets/ListViewItemAnimation.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../Widgets/device_status_sheet.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  double _shouldFade = 0;
  bool isExpanded = false;
  final ContainerTransitionType _transitionType =
      ContainerTransitionType.fadeThrough;
  late List<Course> courses = [];

  @override
  void initState() {
    super.initState();
    // Start the animation to reveal the image
    _startAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
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
        title: Text('Study Material'.toUpperCase()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _shouldFade,
              child: Image.asset('assets/Images/dashboard_banner.png',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover),
            ),
            const SizedBox(
              height: 10,
            ),
            FutureBuilder<List<Course>>(
              future:
                  getSubjectList(), // Replace this with your actual future that fetches the courses
              builder:
                  (BuildContext context, AsyncSnapshot<List<Course>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: RestClient().loader(),
                  ); // Show a loading indicator while waiting for the future to complete
                } else if (snapshot.hasError) {
                  return Text(
                      'Error: ${snapshot.error}'); // Show an error message if the future throws an error
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data?.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListViewItemAnimation(
                        index: index,
                        child: OpenContainer(
                          openColor: Colors.deepPurple.shade50,
                          closedColor: Colors.deepPurple.shade50,
                          transitionType: _transitionType,
                          openBuilder:
                              (BuildContext _, VoidCallback openContainer) {
                            return Subject(
                              course: snapshot.data![index],
                            );
                          },
                          onClosed: _showMarkedAsDoneSnackbar,
                          tappable: true,
                          closedShape: const RoundedRectangleBorder(),
                          closedElevation: 0.0,
                          closedBuilder:
                              (BuildContext _, VoidCallback openContainer) {
                            return CourseCard(course: snapshot.data![index]);
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget interNetCheck() {
    return FutureBuilder(
      future: RestClient().checkInternetConnection(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Icon(Icons.wifi_find_outlined);
        } else if (snapshot.hasError) {
          return const Icon(Icons.wifi_find_outlined);
        } else {
          if (snapshot.data) {
            return const Icon(Icons.wifi);
          } else {
            return const Icon(Icons.wifi_off);
          }
        }
      },
    );
  }

  _checkDeviceStatus() async {
    if (context.mounted) {
      context.loaderOverlay.show();
    }
    final isConnected = await RestClient().checkInternetConnection();
    if (context.mounted) {
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

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _shouldFade = 1; // Adjust the width as needed
    });
  }

  void _showMarkedAsDoneSnackbar(bool? isMarkedAsDone) {
    if (isMarkedAsDone ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Marked as done!'),
      ));
    }
  }

  Future<List<Course>> getSubjectList() async {
    courses = [];
    try {
      final response = await RestClient().authGet('/student/subject-list', {});
      print('API Response: $response');

      // Check if response is null
      if (response == null) {
        RestClient().error(
            "Unable to connect to server. Please check your internet connection.");
        return [];
      }

      // Check if response has the expected structure
      if (response is Map<String, dynamic> && response.containsKey("status")) {
        if (response["status"] == 'success') {
          final courseList = response["data"];
          courses = [];

          if (courseList != null && courseList is List) {
            for (var course in courseList) {
              int tutorialCount = course["tutorial_count"] ?? 0;
              int examCount = course["exam_count"] ?? 0;
              double completionPercentage = 0;
              if (tutorialCount == 0 && examCount == 0) {
                completionPercentage = 0;
              } else {
                completionPercentage = ((examCount / tutorialCount) * 100).clamp(0, 100);
              }
              courses.add(Course(
                  title: course["name"] ?? "Unknown Course",
                  description:
                      "Tutorial ${course["tutorial_count"] ?? 0} | Exam ${course["exam_count"] ?? 0}",
                  progress: completionPercentage.toInt(),
                  id: course["id"] ?? 0));
            }
          }
          return courses;
        } else {
          String errorMessage = response["data"] ?? "Unknown error occurred";
          RestClient().error(errorMessage);
          return [];
        }
      } else {
        RestClient().error("Invalid response format received from server");
        return [];
      }
    } catch (e) {
      print('Error in getSubjectList: $e');
      RestClient().error("Failed to load subjects. Please try again.");
      return [];
    } finally {
      if (context.mounted) {
        context.loaderOverlay.hide();
      }
    }
  }

  void logout() async {
    if (context.mounted) {
      context.loaderOverlay.show();
    }
    await Analytics().logEvent('logout', {});
    await RestClient().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignIn()),
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
                  child: IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.black,
                    ),
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
}
