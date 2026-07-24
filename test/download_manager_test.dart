import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  group('DownloadManager Contract Tests', () {
    test('DownloadTask properties and progress calculations', () {
      final task = DownloadTask(
        id: 'task_1',
        title: 'Organic Chemistry & Chemical Bonds',
        subject: 'Physical Sciences',
        videoUrl: 'https://example.com/chem.mp4',
        progress: 0.65,
        downloadedMB: 32.5,
        totalMB: 50.0,
        timeRemaining: '8s remaining',
      );

      expect(task.id, 'task_1');
      expect(task.title, 'Organic Chemistry & Chemical Bonds');
      expect(task.subject, 'Physical Sciences');
      expect(task.progress, 0.65);
      expect((task.progress * 100).toInt(), 65);
      expect(task.downloadedMB, 32.5);
      expect(task.totalMB, 50.0);
      expect(task.timeRemaining, '8s remaining');
    });

    test('Duplicate download prevention and video state tracking', () {
      final manager = DownloadManager();
      const testUrl = 'https://example.com/algebra_lesson.mp4';

      expect(manager.isVideoDownloaded(testUrl), false);

      manager.markAsDownloaded(testUrl);
      expect(manager.isVideoDownloaded(testUrl), true);

      manager.removeCompletedVideo(testUrl);
      expect(manager.isVideoDownloaded(testUrl), false);
    });

    test('Persistent video deletion tracking by ID and URL', () {
      final manager = DownloadManager();
      const testId = '102';
      const testUrl = 'https://example.com/physics.mp4';

      expect(manager.isVideoDeleted(testId, testUrl), false);

      manager.removeCompletedVideo(testUrl, videoId: testId);

      expect(manager.isVideoDeleted(testId, testUrl), true);
      expect(manager.deletedVideoIds.contains(testId), true);
      expect(manager.deletedVideoIds.contains(testUrl), true);
    });
  });
}
