import 'package:flutter/material.dart';

import 'Course.dart';

class CourseCard extends StatelessWidget {
  final Course course;

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 10),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3), // Customize shadow color and opacity
            spreadRadius: 2, // Customize the spread radius
            blurRadius: 5, // Customize the blur radius
            offset: const Offset(0, 1), // Customize the shadow offset
          ),
        ],
        borderRadius: BorderRadius.circular(5.0),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.purple, Colors.purple.shade400, Colors.purple], // Customize gradient colors
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SubjectIcon(course.title),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title.toUpperCase(),
                    style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8.0),
                  Text(course.description, style: const TextStyle( color: Colors.white),),
                  const SizedBox(height: 16.0),
                  LinearProgressIndicator(
                    value: course.progress / 100,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black45),
                  ),
                  const SizedBox(height: 8.0),
                  Text("${course.progress}% Complete", style: const TextStyle( color: Colors.white),),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget SubjectIcon(title) {
    String modifiedString = title.substring(0,1);
    return Container(
      width: 70,
      height: 70,
      margin: const EdgeInsets.only(right: 15, left: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.purple,
        boxShadow: const [
          BoxShadow(color: Colors.white, spreadRadius: 2),
        ],
      ),
      child: Center(
        child: Text(modifiedString, style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),),
      ),
    );
  }

}