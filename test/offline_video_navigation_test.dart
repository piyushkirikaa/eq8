import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:EQ8/Widgets/Course.dart';
import 'package:EQ8/Student/Subject.dart';
import 'package:EQ8/Library/DownloadManager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    for (var channelName in [
      'plugins.flutter.io/path_provider',
      'plugins.flutter.io/path_provider_ios',
      'plugins.flutter.io/path_provider_macos',
      'dev.fluttercommunity.plus/path_provider'
    ]) {
      final channel = MethodChannel(channelName);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async => '.');
    }
  });

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

    test('Deleted video stays deleted across DownloadManager singleton lifecycle', () {
      final manager = DownloadManager();

      // Simulate the initial/hardcoded video list from DownloadedVideos widget
      final initialVideos = [
        {
          'id': '101',
          'title': 'Algebraic Equations & Functions Overview',
          'subject': 'Mathematics',
          'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_math.mp4',
        },
        {
          'id': '102',
          'title': 'Newton Laws of Motion & Momentum',
          'subject': 'Physical Sciences',
          'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_physics.mp4',
        },
      ];

      // Before deletion: video '101' is not deleted
      expect(manager.isVideoDeleted('101', initialVideos[0]['video_url']), false);

      // Perform deletion (same call path as DownloadedVideos._deleteVideo)
      manager.removeCompletedVideo(
        initialVideos[0]['video_url']!,
        videoId: '101',
      );

      // After deletion: video '101' is permanently marked as deleted
      expect(manager.isVideoDeleted('101', initialVideos[0]['video_url']), true);
      expect(manager.deletedVideoIds.contains('101'), true);
      expect(manager.deletedVideoIds.contains(initialVideos[0]['video_url']), true);

      // Simulate what _allDownloadedVideos getter does: filter out deleted
      final filteredVideos = initialVideos.where((v) =>
          !manager.isVideoDeleted(v['id'], v['video_url'])).toList();

      // Video 101 should be gone, video 102 should remain
      expect(filteredVideos.length, 1);
      expect(filteredVideos[0]['id'], '102');
      expect(filteredVideos.any((v) => v['id'] == '101'), false);

      // Video 102 is unaffected
      expect(manager.isVideoDeleted('102', initialVideos[1]['video_url']), false);
    });
  });
}
