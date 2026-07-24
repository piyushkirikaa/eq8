import 'package:flutter_test/flutter_test.dart';
import 'package:EQ8/Widgets/Course.dart';
import 'package:EQ8/Student/Subject.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Video Navigation Contract Tests', () {
    test('Subject accepts autoPlayVideo parameter', () {
      final course = Course(
        title: 'Physical Sciences',
        description: 'Offline Course',
        progress: 100,
        id: 2,
      );

      final video = {
        'id': '102',
        'title': 'Newton Laws of Motion & Momentum',
        'subject': 'Physical Sciences',
        'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_physics.mp4',
      };

      final widget = Subject(
        course: course,
        autoPlayVideo: video,
      );

      expect(widget.course.title, 'Physical Sciences');
      expect(widget.autoPlayVideo?['title'], 'Newton Laws of Motion & Momentum');
      expect(widget.autoPlayVideo?['subject'], 'Physical Sciences');
    });
  });
}
