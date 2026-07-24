import 'package:flutter/material.dart';
import '../Library/RestClient.dart';
import '../../Student/Dashboard.dart';
import 'PodcastDashboard.dart';
import 'DownloadedVideos.dart';
import 'ExamReport.dart';
import 'Subject.dart';
import '../Widgets/Course.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int currentPageIndex = 0;

  Course _getCourseForSubject(String subjectName) {
    final nameLower = subjectName.toLowerCase();
    int id = 1;
    if (nameLower.contains('math')) {
      id = 1;
    } else if (nameLower.contains('physical') || nameLower.contains('physics')) {
      id = 2;
    } else if (nameLower.contains('life') || nameLower.contains('bio')) {
      id = 3;
    } else if (nameLower.contains('account')) {
      id = 4;
    } else if (nameLower.contains('english')) {
      id = 5;
    } else if (nameLower.contains('geography')) {
      id = 6;
    } else if (nameLower.contains('history')) {
      id = 7;
    } else if (nameLower.contains('business')) {
      id = 8;
    }

    return Course(
      title: subjectName,
      description: 'Offline Course',
      progress: 100,
      id: id,
    );
  }

  void _openOfflineVideoInSubjects(Map<String, dynamic> video) {
    final String subjectName = video['subject']?.toString() ?? 'Mathematics';
    final Course course = _getCourseForSubject(subjectName);

    setState(() {
      currentPageIndex = 0; // Switch to the Subjects tab
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Subject(
          course: course,
          autoPlayVideo: video,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          OverlayToastManager().dismissActiveToast();
          RestClient.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          setState(() {
            currentPageIndex = index;
          });
        },
        backgroundColor: Colors.purple,
        indicatorColor: currentPageIndex == 2 ? Colors.transparent : Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          const NavigationDestination(
            icon: Icon(
              Icons.ondemand_video_outlined,
              color: Colors.white,
            ),
            label: 'Subjects',
          ),
          const NavigationDestination(
            icon: Icon(
              Icons.podcasts,
              color: Colors.white,
            ),
            label: 'Podcasts',
          ),
          NavigationDestination(
            icon: Container(
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                color: currentPageIndex == 2 ? Colors.amber : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.arrow_circle_down_rounded,
                color: Colors.white,
              ),
            ),
            label: 'Offline Videos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.pie_chart, color: Colors.white),
            label: 'Report',
          ),
        ],
      ),
      body: _buildCurrentPage(),
    );
  }

  Widget _buildCurrentPage() {
    switch (currentPageIndex) {
      case 0:
        return const Dashboard();
      case 1:
        return const PodcastDashboard();
      case 2:
        return DownloadedVideos(
          onVideoTap: (video) => _openOfflineVideoInSubjects(video),
        );
      case 3:
        return const ExamReport();
      default:
        return const Dashboard();
    }
  }
}
