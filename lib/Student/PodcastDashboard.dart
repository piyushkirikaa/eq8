import 'package:EQ8/Widgets/CourseCardPodcust.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../../Student/StudentProfile.dart';
import '../../SignIn.dart';
import '../Widgets/device_status_sheet.dart';
import '../../Student/PodcastSubject.dart';
import '../Library/RestClient.dart';
import '../Service/Analytics.dart';
import '../Widgets/Course.dart';
import '../Widgets/ListViewItemAnimation.dart';
import '../Widgets/ConnectivityIcon.dart';

class PodcastDashboard extends StatefulWidget {
  const PodcastDashboard({super.key});

  @override
  State<PodcastDashboard> createState() => _PodcastDashboardState();
}

class _PodcastDashboardState extends State<PodcastDashboard> {
  double _shouldFade = 0;
  bool isExpanded = false;
  final ContainerTransitionType _transitionType =
      ContainerTransitionType.fadeThrough;
  late List<Course> courses = [];
  Alignment _bannerAlignment = Alignment.centerLeft;

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
        automaticallyImplyLeading: false,
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
        title: Text('Podcasts'.toUpperCase()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _shouldFade,
              child: AnimatedAlign(
                alignment: _bannerAlignment,
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                child: FractionallySizedBox(
                  widthFactor: 0.67,
                  child: Image.asset('assets/Images/dashboard_banner.png',
                      fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            FutureBuilder<List<Course>>(
              future: getSubjectList(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Course>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: RestClient().loader(),
                  );
                } else if (snapshot.hasError) {
                  // Show a user-friendly error message with custom design
                  return Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.deepPurple,
                            size: 60,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Thank you for your patience , something special is coming soon…',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(
                                  () {}); // Refresh the page by triggering a rebuild
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text('Retry'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                  // Handle case when data is empty
                  return const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.headphones_outlined,
                            color: Colors.deepPurple,
                            size: 60,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'No Podcasts Available',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'There are currently no podcasts available for you',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
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
                            return PodcastSubject(
                              course: snapshot.data![index],
                            );
                          },

                          tappable: true,
                          closedShape: const RoundedRectangleBorder(),
                          closedElevation: 0.0,
                          closedBuilder:
                              (BuildContext _, VoidCallback openContainer) {
                            return CourseCardPodcust(
                                course: snapshot.data![index]);
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

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 50));
    setState(() {
      _shouldFade = 1; // Adjust the width as needed
      _bannerAlignment = Alignment.center;
    });
  }



  Future<List<Course>> getSubjectList() async {
    courses = [];
    final response = await RestClient().authGet('/student/podcast-list', {});
    if (response["status"] == 'success') {
      final courseList = response["data"];
      courses = [];
      if (courseList is List && courseList.isNotEmpty) {
        for (var course in courseList) {
          int tutorialCount = course["tutorial_count"];
          int examCount = course["exam_count"];
          double completionPercentage = 0;
          if (tutorialCount == 0 && examCount == 0) {
            completionPercentage = 0;
          } else {
            completionPercentage =
                ((examCount / tutorialCount) * 100).clamp(0, 100);
          }
          courses.add(Course(
              title: course["name"],
              description: "Podcast ${course["tutorial_count"]} Episodes",
              progress: completionPercentage.toInt(),
              id: course["id"]));
        }
        return courses;
      } else {
        // If data is empty but status is success
        throw Exception('No podcasts found');
      }
    } else {
      //RestClient().error(response["data"]);
      throw Exception(
          'Failed to load podcasts: ${response["message"] ?? "Unknown error"}');
    }
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
}
