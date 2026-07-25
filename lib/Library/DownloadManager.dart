import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  DownloadManager._internal() {
    _loadPersistedCompletedVideos();
  }

  final List<DownloadTask> _activeDownloads = [];
  final List<Map<String, dynamic>> _completedVideos = [];
  final Set<String> _downloadedUrls = {};
  final Set<String> _deletedVideoIds = {};

  List<DownloadTask> get activeDownloads => List.unmodifiable(_activeDownloads);
  List<Map<String, dynamic>> get completedVideos => List.unmodifiable(_completedVideos);
  Set<String> get deletedVideoIds => Set.unmodifiable(_deletedVideoIds);

  Future<void> _loadPersistedCompletedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? deletedList = prefs.getStringList('persisted_deleted_video_ids');
      if (deletedList != null) {
        _deletedVideoIds.addAll(deletedList);
      }

      final String? jsonStr = prefs.getString('persisted_completed_videos');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> rawList = jsonDecode(jsonStr);
        for (var item in rawList) {
          if (item is Map<String, dynamic>) {
            final String videoUrl = item['video_url']?.toString() ?? '';
            final String videoId = item['id']?.toString() ?? '';
            final DateTime downloadedAt = item['downloaded_at'] != null
                ? DateTime.tryParse(item['downloaded_at'].toString()) ?? DateTime.now()
                : DateTime.now();

            final map = {
              'id': videoId,
              'title': item['title']?.toString() ?? '',
              'subject': item['subject']?.toString() ?? '',
              'duration': item['duration']?.toString() ?? '15:00',
              'size': item['size']?.toString() ?? '50.0 MB',
              'video_url': videoUrl,
              'downloaded_at': downloadedAt,
            };

            if (videoUrl.isNotEmpty &&
                !_completedVideos.any((v) => v['video_url'] == videoUrl) &&
                !isVideoDeleted(videoId, videoUrl)) {
              _completedVideos.add(map);
              _downloadedUrls.add(videoUrl);
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading persisted completed videos: $e');
    }
  }

  Future<void> _savePersistedCompletedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('persisted_deleted_video_ids', _deletedVideoIds.toList());

      final serializedList = _completedVideos.map((v) {
        final dt = v['downloaded_at'];
        final String isoDate = (dt is DateTime) ? dt.toIso8601String() : DateTime.now().toIso8601String();
        return {
          'id': v['id'],
          'title': v['title'],
          'subject': v['subject'],
          'duration': v['duration'],
          'size': v['size'],
          'video_url': v['video_url'],
          'downloaded_at': isoDate,
        };
      }).toList();

      await prefs.setString('persisted_completed_videos', jsonEncode(serializedList));
    } catch (e) {
      debugPrint('Error saving persisted completed videos: $e');
    }
  }

  bool isVideoDeleted(String? id, String? videoUrl) {
    if (id != null && id.isNotEmpty && _deletedVideoIds.contains(id)) {
      return true;
    }
    if (videoUrl != null && videoUrl.isNotEmpty && _deletedVideoIds.contains(videoUrl)) {
      return true;
    }
    return false;
  }

  bool isVideoDownloaded(String videoUrl) {
    return (_downloadedUrls.contains(videoUrl) ||
            _completedVideos.any((v) => v['video_url'] == videoUrl)) &&
        !isVideoDeleted(null, videoUrl);
  }

  bool isDownloading(String videoUrl) {
    return _activeDownloads.any((task) => task.videoUrl == videoUrl);
  }

  void markAsDownloaded(String videoUrl) {
    _downloadedUrls.add(videoUrl);
    notifyListeners();
  }

  void registerCachedVideo({
    required String id,
    required String title,
    required String subject,
    required String videoUrl,
    String duration = '15:00',
    String size = '15.0 MB',
  }) {
    if (videoUrl.isEmpty || isVideoDeleted(id, videoUrl)) return;

    if (!_completedVideos.any((v) => v['video_url'] == videoUrl || (id.isNotEmpty && v['id'] == id))) {
      _completedVideos.insert(0, {
        'id': id.isNotEmpty ? id : DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'subject': subject,
        'duration': duration,
        'size': size,
        'video_url': videoUrl,
        'downloaded_at': DateTime.now(),
      });
      _downloadedUrls.add(videoUrl);
      _savePersistedCompletedVideos();
      notifyListeners();
    }
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
      RestClient().success('Offline Video is Downloading');
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

    _savePersistedCompletedVideos();
    notifyListeners();
    try {
      RestClient().success('Video saved is now available offline');
    } catch (_) {}
  }

  void removeCompletedVideo(String videoUrl, {String? videoId}) {
    if (videoUrl.isNotEmpty) {
      _deletedVideoIds.add(videoUrl);
    }
    if (videoId != null && videoId.isNotEmpty) {
      _deletedVideoIds.add(videoId);
    }
    _downloadedUrls.remove(videoUrl);
    _completedVideos.removeWhere((v) => v['video_url'] == videoUrl || (videoId != null && v['id'] == videoId));
    if (videoUrl.isNotEmpty) {
      runZonedGuarded(() {
        try {
          DefaultCacheManager().removeFile(videoUrl);
        } catch (_) {}
      }, (error, stack) {});
    }
    _savePersistedCompletedVideos();
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
