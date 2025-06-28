import 'package:flutter/material.dart';
import 'Course.dart';

class CourseCardPodcust extends StatelessWidget {
  final Course course;

  const CourseCardPodcust({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    // Calculate a color based on the course title for variety
    final Color baseColor = _getColorFromTitle(course.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(12.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            baseColor.withOpacity(0.8),
            baseColor.withOpacity(0.9),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          children: [
            // Background pattern for visual interest (subtle diagonal lines)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: PatternPainter(),
                ),
              ),
            ),
            // Main card content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SubjectIcon(course.title, baseColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          course.description,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Decorative accent in corner
            Positioned(
              right: -15,
              top: -15,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget SubjectIcon(String title, Color baseColor) {
    String initial = title.substring(0, 1).toUpperCase();
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Generate a color based on the course title
  Color _getColorFromTitle(String title) {
    if (title.isEmpty) return Colors.purple;

    // Use the string to generate a "random" but consistent color for each course
    int hash = title.codeUnits.fold(0, (prev, element) => prev + element);

    // Use a set of pre-defined professional colors
    final List<Color> colorOptions = [
      const Color(0xFF5C6BC0), // Indigo
      const Color(0xFF7E57C2), // Deep Purple
      const Color(0xFF26A69A), // Teal
      const Color(0xFF5C6BC0), // Indigo
      const Color(0xFF42A5F5), // Blue
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFF7043), // Deep Orange
      const Color(0xFF8D6E63), // Brown
      const Color(0xFF78909C), // Blue Grey
    ];

    return colorOptions[hash % colorOptions.length];
  }
}

// Custom painter to create a subtle pattern background
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines for a subtle pattern
    double spacing = 20;
    for (double i = -size.width; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
