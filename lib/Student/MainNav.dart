import 'package:flutter/material.dart';
import '../Library/RestClient.dart';
import '../../Student/Dashboard.dart';
import 'PodcastDashboard.dart';
import 'LiveTeacherAudio.dart';
import 'ExamReport.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int currentPageIndex = 0;

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
              margin: const EdgeInsets.only(top: 15),
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
            label: 'Downloaded\n  Videos',
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
        return const LiveTeacherAudio();
      case 3:
        return const ExamReport();
      default:
        return const Dashboard();
    }
  }
}
