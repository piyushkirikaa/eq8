import 'package:EQ8/Student/VoiceAssistant.dart';
import 'package:flutter/material.dart';
import '../../Student/Dashboard.dart';
import 'PodcastDashboard.dart';
import 'ExamHistory.dart';
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
          setState(() {
            currentPageIndex = index;
          });
        },
        backgroundColor: Colors.purple,
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(
              Icons.ondemand_video_outlined,
              color: Colors.white,
            ),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.podcasts,
              color: Colors.white,
            ),
            label: 'Podcasts',
          ),
          NavigationDestination(
            icon: Icon(Icons.ac_unit_rounded, color: Colors.white),
            label: 'Live Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart, color: Colors.white),
            label: 'Report',
          ),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: const <Widget>[
          Dashboard(),
          PodcastDashboard(),
          LiveTeacherAudio(),
          //VoiceAssistant(),
          ExamReport(),
          //LiveTeacher(),
          //LiveTeacherWindows()
        ],
      ),
    );
  }
}
