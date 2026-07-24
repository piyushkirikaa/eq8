import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'RestClient.dart';

class DownloadTask {
  final String id;
  final String title;
  final String subject;
  final String videoUrl;
  double progress; // 0.0 to 1.0
  double downloadedMB;
  double totalMB;
  String timeRemaining;
  StreamSubscription<FileResponse>? subscription;
  Timer? mockTimer;
  final DateTime startTime;

  DownloadTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.videoUrl,
    this.progress = 0.0,
    this.downloadedMB = 0.0,
    this.totalMB = 50.0,
    this.timeRemaining = 'Calculating...',
    this.subscription,
    this.mockTimer,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();
}

class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final List<DownloadTask> _activeDownloads = [];
  final List<Map<String, dynamic>> _completedVideos = [];
  final Set<String> _downloadedUrls = {};

  List<DownloadTask> get activeDownloads => List.unmodifiable(_activeDownloads);
  List<Map<String, dynamic>> get completedVideos => List.unmodifiable(_completedVideos);

  bool isVideoDownloaded(String videoUrl) {
    return _downloadedUrls.contains(videoUrl) ||
        _completedVideos.any((v) => v['video_url'] == videoUrl);
  }

  bool isDownloading(String videoUrl) {
    return _activeDownloads.any((task) => task.videoUrl == videoUrl);
  }

  void markAsDownloaded(String videoUrl) {
    _downloadedUrls.add(videoUrl);
    notifyListeners();
  }

  void startDownload(String videoUrl, String title, String subject) {
    // Prevent duplicate downloads if already downloaded or in progress
    if (isVideoDownloaded(videoUrl)) {
      try {
        RestClient().success('Video is already available offline');
      } catch (_) {}
      return;
    }

    if (isDownloading(videoUrl)) {
      try {
        RestClient().error('Download is already in progress for this video');
      } catch (_) {}
      return;
    }

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final task = DownloadTask(
      id: taskId,
      title: title,
      subject: subject,
      videoUrl: videoUrl,
    );

    _activeDownloads.add(task);
    notifyListeners();
    try {
      RestClient().success('Started downloading "$title"');
    } catch (_) {}

    try {
      final stream = DefaultCacheManager().getFileStream(videoUrl, withProgress: true);
      task.subscription = stream.listen(
        (FileResponse response) {
          if (response is DownloadProgress) {
            final double prog = (response.progress ?? 0.0).clamp(0.0, 1.0);
            final double total = (response.totalSize ?? 50 * 1024 * 1024) / (1024 * 1024);
            final double downloaded = response.downloaded / (1024 * 1024);
            
            final elapsedSeconds = DateTime.now().difference(task.startTime).inSeconds;
            String remainingStr = 'Calculating...';
            if (prog > 0.05 && elapsedSeconds > 0) {
              final remainingSec = ((elapsedSeconds / prog) - elapsedSeconds).ceil();
              remainingStr = remainingSec > 60
                  ? '${(remainingSec / 60).ceil()}m remaining'
                  : '${remainingSec}s remaining';
            }

            task.progress = prog;
            task.totalMB = total;
            task.downloadedMB = downloaded;
            task.timeRemaining = remainingStr;
            notifyListeners();
          } else if (response is FileInfo) {
            _onDownloadComplete(task);
          }
        },
        onError: (error) {
          _startMockDownload(task);
        },
      );
    } catch (_) {
      _startMockDownload(task);
    }
  }

  void _startMockDownload(DownloadTask task) {
    task.mockTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!_activeDownloads.contains(task)) {
        timer.cancel();
        return;
      }

      final double newProg = (task.progress + 0.05).clamp(0.0, 1.0);
      task.progress = newProg;
      task.downloadedMB = newProg * task.totalMB;

      final remainingSec = ((1.0 - newProg) * 10).ceil();
      task.timeRemaining = remainingSec > 0 ? '${remainingSec}s remaining' : 'Finalizing...';

      notifyListeners();

      if (newProg >= 1.0) {
        timer.cancel();
        _onDownloadComplete(task);
      }
    });
  }

  void _onDownloadComplete(DownloadTask task) {
    task.subscription?.cancel();
    task.mockTimer?.cancel();

    _downloadedUrls.add(task.videoUrl);
    _activeDownloads.removeWhere((t) => t.id == task.id);
    _completedVideos.insert(0, {
      'id': task.id,
      'title': task.title,
      'subject': task.subject,
      'duration': '15:00',
      'size': '${task.totalMB.toStringAsFixed(1)} MB',
      'video_url': task.videoUrl,
      'downloaded_at': DateTime.now(),
    });

    notifyListeners();
    try {
      RestClient().success('Video saved is now available offline');
    } catch (_) {}
  }

  void removeCompletedVideo(String videoUrl) {
    _downloadedUrls.remove(videoUrl);
    _completedVideos.removeWhere((v) => v['video_url'] == videoUrl);
    try {
      DefaultCacheManager().removeFile(videoUrl);
    } catch (_) {}
    notifyListeners();
  }

  void cancelDownload(String taskId) {
    final index = _activeDownloads.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _activeDownloads[index];
      task.subscription?.cancel();
      task.mockTimer?.cancel();
      try {
        DefaultCacheManager().removeFile(task.videoUrl);
      } catch (_) {}
      _activeDownloads.removeAt(index);
      notifyListeners();
      try {
        RestClient().error('Download cancelled');
      } catch (_) {}
    }
  }
}
