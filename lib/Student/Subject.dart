import 'package:flutter/material.dart';
import 'dart:io';
import '../../Service/Analytics.dart';
import '../../Student/FeedbackController.dart';
import '../../Student/StartYourExam.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../Library/RestClient.dart';
import '../Library/DownloadManager.dart';
import '../Widgets/Course.dart';
import 'ExamHistory.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
// Platform-specific imports
import 'package:flick_video_player/flick_video_player.dart';
import 'PDFScreen.dart';
import 'package:google_fonts/google_fonts.dart';

// Theme constants for consistent styling
class AppTheme {
  static const Color primaryColor = Color(0xFF6A1B9A); // Deep purple
  static const Color secondaryColor = Color(0xFF9575CD); // Light purple
  static const Color accentColor = Color(0xFFD1C4E9); // Very light purple
  static const Color backgroundColor =
      Color(0xFFF5F5F5); // Light grey background
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);

  static TextStyle headingStyle = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static TextStyle subheadingStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );

  static TextStyle bodyStyle = const TextStyle(
    fontSize: 14,
    color: textSecondaryColor,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class Subject extends StatefulWidget {
  final Course course;
  final Map<String, dynamic>? autoPlayVideo;
  const Subject({super.key, required this.course, this.autoPlayVideo});
  @override
  State<Subject> createState() => _SubjectState();
}

class _SubjectState extends State<Subject> {
  dynamic currentTutorial;
  bool isVideoSet = false;
  late List<dynamic> subjectList;
  late BuildContext globalScaffoldContext;

  // Platform-specific video controllers
  FlickManager? flickManager; // For Android
  VideoPlayerController? winVideoController; // For Windows

  bool isSavingVideo = false;
  // Track the ID of the currently playing video
  String? currentlyPlayingId;
  // Store the fetched subject list to avoid reloading
  List<dynamic>? cachedSubjectList;
  Future<dynamic>? _subjectListFuture;
  bool _isOnline = true;

  // Windows video player controls state
  bool _showControls = true;
  bool _isFullScreen = false;
  double _currentVolume = 1.0;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _subjectListFuture = getSubjectList();
    DownloadManager().addListener(_onDownloadManagerChanged);

    if (widget.autoPlayVideo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoPlayVideo(widget.autoPlayVideo!);
      });
    }

    // Initialize platform-specific video players
    if (Platform.isWindows) {
      // For Windows, we'll initialize the controller when needed
      winVideoController = null;
    } else {
      // For Android and other platforms, use FlickManager
      flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.networkUrl(Uri.parse(
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageHeight = MediaQuery.of(context).size.height;
    final playerHeight = (pageHeight * 0.30).clamp(180.0, 320.0);
    final controlBarHeight = (pageHeight * 0.05).clamp(44.0, 56.0);
    globalScaffoldContext = context;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.course.title.toUpperCase(),
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback_outlined, color: Colors.white),
            tooltip: 'Feedback',
            onPressed: () {
              submitYourFeedback();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          videoPlayer(playerHeight, controlBarHeight),
          if (isVideoSet) _buildPlayingVideoDetails(),
          if (!isVideoSet)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Available Tutorials',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder(
              future: _subjectListFuture ??= getSubjectList(),
              builder: (context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: RestClient().loader(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: AppTheme.bodyStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else {
                  if (snapshot.hasData) {
                    final data = snapshot.data;
                    final dataLength = snapshot.data?.length;

                    final bool hasDownloadedVideos = (data != null &&
                        data.any((video) => video['isCached'] == true)) ||
                        widget.autoPlayVideo != null;

                    if (!_isOnline && !hasDownloadedVideos && (data == null || data.isEmpty)) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_outlined,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Video unavailable, please connect to the internet to continue learning.',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (dataLength == 0) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.video_library_outlined,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No tutorials available yet',
                              style: AppTheme.bodyStyle,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 8, bottom: 140),
                        itemCount: dataLength,
                        itemBuilder: (context, index) {
                          final tutorial = data![index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildTutorialCard(tutorial),
                          );
                        });
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: RestClient().loader(),
                    );
                  }
                }
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTutorialCard(dynamic tutorial) {
    final bool isCurrentlyPlaying = currentlyPlayingId != null &&
        tutorial['id'] != null &&
        currentlyPlayingId == tutorial['id'].toString();

    // Check if user is in trial mode and this video is not available in trial
    final bool isTrialUser = tutorial['is_trail_user'] == 1;
    final bool isTrialVideo = tutorial['is_trial'] == 1;
    final bool isLocked = isTrialUser && !isTrialVideo;

    return Card(
      elevation: isCurrentlyPlaying ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentlyPlaying
            ? const BorderSide(color: AppTheme.primaryColor, width: 2)
            : tutorial['isCached']
                ? const BorderSide(color: Colors.green, width: 1)
                : BorderSide.none,
      ),
      color: isCurrentlyPlaying
          ? const Color(0xFFEDE7F6)
          : isLocked
              ? Colors.grey[100] // Lighter gray for locked videos
              : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: GestureDetector(
          onTap: isLocked
              ? () => _handleLockedVideo()
              : () => _handleVideoTap(tutorial),
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: isCurrentlyPlaying
                      ? Border.all(color: AppTheme.primaryColor, width: 2)
                      : isLocked
                          ? Border.all(color: Colors.grey[400]!, width: 1)
                          : null,
                  image: DecorationImage(
                    image:
                        NetworkImage(tutorial['video_cover_image'].toString()),
                    fit: BoxFit.cover,
                    colorFilter: isLocked
                        ? ColorFilter.mode(
                            Colors.grey.withValues(alpha: 0.7),
                            BlendMode.darken,
                          )
                        : null,
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrentlyPlaying
                          ? AppTheme.primaryColor.withValues(alpha: 0.7)
                          : isLocked
                              ? Colors.grey.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        isLocked
                            ? Icons.lock
                            : isCurrentlyPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                        color: Colors.white,
                        size: 20),
                  ),
                ),
              ),
              if (isCurrentlyPlaying)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (isLocked)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: InkWell(
          onTap: isLocked
              ? () => _handleLockedVideo()
              : () => _handleVideoTap(tutorial),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tutorial['title'],
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isLocked
                        ? Colors.grey[600]
                        : isCurrentlyPlaying
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              if (isLocked)
                Icon(
                  Icons.lock,
                  size: 14,
                  color: Colors.grey[600],
                ),
            ],
          ),
        ),
        subtitle: (tutorial['sub_title'] != null &&
                tutorial['sub_title'].toString().trim().isNotEmpty &&
                tutorial['sub_title'].toString().toLowerCase() != 'null')
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  tutorial['sub_title'].toString().toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isLocked
                        ? Colors.grey[500]
                        : isCurrentlyPlaying
                            ? AppTheme.primaryColor.withValues(alpha: 0.7)
                            : AppTheme.textSecondaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            : (tutorial['subject_name'] != null &&
                    tutorial['subject_name'].toString().trim().isNotEmpty &&
                    tutorial['subject_name'].toString().toLowerCase() != 'null')
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tutorial['subject_name'].toString().toUpperCase(),
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isLocked
                            ? Colors.grey[500]
                            : isCurrentlyPlaying
                                ? AppTheme.primaryColor.withValues(alpha: 0.7)
                                : AppTheme.textSecondaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentlyPlaying)
              Container(
                margin: const EdgeInsets.only(right: 8.0),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
            if (tutorial['isCached'])
              const Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Icon(Icons.download_for_offline,
                    color: Colors.green, size: 30),
              ),
            // Only show options menu for currently playing video
            if (isCurrentlyPlaying)
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () => videoOption(
                    tutorial['video_url'].toString(), tutorial['id']),
              ),
          ],
        ),
      ),
    );
  }

  void _handleVideoTap(dynamic tutorial) {
    // First check if this is a locked video (trial user trying to access non-trial content)
    final bool isTrialUser = tutorial['is_trail_user'] == 1;
    final bool isTrialVideo = tutorial['is_trial'] == 1;

    if (isTrialUser && !isTrialVideo) {
      _handleLockedVideo();
      return;
    }

    currentTutorial = tutorial;
    Analytics().logEvent("WATCH_VIDEO", {
      "subject_name": currentTutorial['subject_name'].toString(),
      "video": currentTutorial['title'].toString()
    });
    playVideo(tutorial['video_url'].toString());
  }

  void _autoPlayVideo(Map<String, dynamic> video) async {
    final videoUrl = video['video_url']?.toString() ?? '';
    final videoTitle = video['title']?.toString() ?? '';

    dynamic targetTutorial;

    try {
      final list = await _subjectListFuture;
      if (list is List && list.isNotEmpty) {
        for (var item in list) {
          if (item['video_url'] == videoUrl ||
              (item['title'] != null &&
                  item['title'].toString().toLowerCase() ==
                      videoTitle.toLowerCase())) {
            targetTutorial = item;
            break;
          }
        }
      }
    } catch (_) {}

    if (targetTutorial == null) {
      targetTutorial = {
        'id': video['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'title': videoTitle.isNotEmpty ? videoTitle : 'Offline Video',
        'subject_name': widget.course.title,
        'video_url': videoUrl,
        'video_cover_image': video['video_cover_image'] ??
            'https://www.mydigitalcollege.co.za/crm/api/sample_cover.jpg',
        'isCached': true,
        'is_trail_user': 0,
        'is_trial': 1,
      };

      if (cachedSubjectList != null) {
        if (!cachedSubjectList!
            .any((item) => item['video_url'] == videoUrl)) {
          cachedSubjectList!.insert(0, targetTutorial);
        }
      } else {
        cachedSubjectList = [targetTutorial];
      }
    }

    if (mounted) {
      _handleVideoTap(targetTutorial);
    }
  }

  void _handleLockedVideo() {
    // Show a message to the user that this content is premium
    RestClient().error('This video is only available to premium members');

    // Optionally, you could show a dialog with more information about upgrading
    /*
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Premium Content'),
        content: Text('This content is only available for premium members. Upgrade your account to access all tutorials.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CLOSE'),
          ),
          TextButton(
            onPressed: () {
              // Navigate to upgrade screen
              Navigator.pop(context);
            },
            child: Text('UPGRADE'),
          ),
        ],
      ),
    );
    */
  }

  Future<dynamic> _navigateWithVideoPause(Widget page) async {
    bool wasPlaying = false;

    if (Platform.isWindows) {
      wasPlaying = winVideoController?.value.isPlaying ?? false;
      if (wasPlaying) {
        winVideoController?.pause();
      }
    } else {
      wasPlaying = flickManager
              ?.flickVideoManager?.videoPlayerController?.value.isPlaying ??
          false;
      if (wasPlaying) {
        flickManager?.flickVideoManager?.videoPlayerController?.pause();
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    if (wasPlaying) {
      if (Platform.isWindows) {
        winVideoController?.play();
      } else {
        flickManager?.flickVideoManager?.videoPlayerController?.play();
      }
    }

    return result;
  }

  submitYourFeedback() {
    _navigateWithVideoPause(
      FeedbackController(tutorial: currentTutorial),
    );
  }

  getSubjectList() async {
    _isOnline = await RestClient().checkInternetConnection();
    // Return cached list if available to prevent reloading
    if (cachedSubjectList != null && cachedSubjectList!.isNotEmpty) {
      return cachedSubjectList;
    }

    final currentCourse = widget.course;
    Analytics().logEvent(
        "VIEW_SUBJECT", {"subject_name": currentCourse.title.toString()});
    final currentCourseId = currentCourse.id;

    var videoList = [];

    if (_isOnline) {
      try {
        final response =
            await RestClient().authGet('/student/tutorials/$currentCourseId', {});
        if (response != null && response["status"] == 'success') {
          for (var video in response["data"]) {
            final videoUrl = video['video_url'].toString();
            final isCached = await isUrlCached(videoUrl);
            video['isCached'] = isCached;
            if (isCached && !DownloadManager().isVideoDeleted(video['id']?.toString(), videoUrl)) {
              DownloadManager().registerCachedVideo(
                id: video['id']?.toString() ?? '',
                title: video['title']?.toString() ?? 'Video Tutorial',
                subject: currentCourse.title,
                videoUrl: videoUrl,
                duration: video['duration']?.toString() ?? '15:00',
                size: video['size']?.toString() ?? '15.0 MB',
              );
            }
            videoList.add(video);
          }
        }
      } catch (_) {}
    }

    // Include autoPlayVideo if provided and not already present
    if (widget.autoPlayVideo != null) {
      final autoVideo = Map<String, dynamic>.from(widget.autoPlayVideo!);
      final videoUrl = autoVideo['video_url']?.toString() ?? '';
      autoVideo['isCached'] = true;
      autoVideo['is_trail_user'] = 0;
      autoVideo['is_trial'] = 1;
      autoVideo['subject_name'] = currentCourse.title;

      if (!videoList.any((v) => v['video_url'] == videoUrl)) {
        videoList.insert(0, autoVideo);
      }
    }

    // Include completed offline videos from DownloadManager
    for (var completed in DownloadManager().completedVideos) {
      final String videoUrl = completed['video_url']?.toString() ?? '';
      final String videoId = completed['id']?.toString() ?? '';
      if (DownloadManager().isVideoDeleted(videoId, videoUrl)) continue;

      final String completedSub = completed['subject']?.toString().toLowerCase() ?? '';
      if (completedSub == currentCourse.title.toLowerCase()) {
        if (!videoList.any((v) => v['video_url'] == completed['video_url'])) {
          videoList.add({
            'id': completed['id'],
            'title': completed['title'],
            'subject_name': currentCourse.title,
            'video_url': completed['video_url'],
            'video_cover_image':
                'https://www.mydigitalcollege.co.za/crm/api/sample_cover.jpg',
            'isCached': true,
            'is_trail_user': 0,
            'is_trial': 1,
          });
        }
      }
    }

    cachedSubjectList = videoList;
    return videoList;
  }

  playVideo(video) async {
    final fileInfo = await DefaultCacheManager().getFileFromCache(video);
    if (fileInfo != null) {
      changeVideo(fileInfo.file.path);
    } else {
      changeVideo(video);
    }
  }

  void changeVideo(String videoUrl) {
    final bool isLocalFile = !videoUrl.startsWith('http');
    if (Platform.isWindows) {
      // For Windows platform
      winVideoController?.dispose();
      winVideoController = isLocalFile
          ? VideoPlayerController.file(File(videoUrl))
          : VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      winVideoController!.initialize().then((_) {
        _currentVolume = 1.0;
        winVideoController!.setVolume(_currentVolume);

        setState(() {
          isVideoSet = true;
          if (currentTutorial != null && currentTutorial['id'] != null) {
            currentlyPlayingId = currentTutorial['id'].toString();
          }
        });
      });
    } else {
      // For Android and other platforms
      final newController = isLocalFile
          ? VideoPlayerController.file(File(videoUrl))
          : VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      newController.initialize().then((_) {
        newController.setVolume(1.0);
        if (mounted) {
          setState(() {});
        }
      });

      flickManager?.handleChangeVideo(newController);
      if (flickManager?.flickControlManager != null) {
        flickManager!.flickControlManager!.unmute();
      }

      setState(() {
        isVideoSet = true;
        // Update currently playing ID if we have current tutorial
        if (currentTutorial != null && currentTutorial['id'] != null) {
          currentlyPlayingId = currentTutorial['id'].toString();
        }
      });
    }
  }

  videoOption(videoURL, tutorialID) async {
    final isCached = await isUrlCached(videoURL);
    videoOptionModal(isCached, videoURL, tutorialID);
  }

  Future<void> videoOptionModal(bool isCached, videoURL, tutorialID) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      elevation: 8,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.video_library_outlined,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video Options',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          if (currentTutorial != null &&
                              currentTutorial['title'] != null)
                            Text(
                              currentTutorial['title'].toString(),
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              if (DownloadManager().isVideoDownloaded(videoURL) || isCached) ...[
                _buildOptionTile(
                  icon: Icons.check_circle_outline,
                  title: 'Available Offline',
                  subtitle: 'This video is saved on your device for offline viewing',
                  iconBackgroundColor: Colors.green[50]!,
                  iconColor: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    RestClient().success('Video is already available offline');
                  },
                ),
                _buildOptionTile(
                  icon: Icons.delete_outline,
                  title: 'Delete offline video',
                  subtitle: 'Remove this video from device storage',
                  iconBackgroundColor: Colors.red[50]!,
                  iconColor: Colors.red,
                  onTap: () async {
                    Analytics().logEvent("REMOVE_OFFLINE_VIDEO", {
                      "subject_name":
                          currentTutorial['subject_name'].toString(),
                      "video": currentTutorial['title'].toString()
                    });
                    Navigator.pop(context);
                    DownloadManager().removeCompletedVideo(videoURL);
                    if (cachedSubjectList != null) {
                      for (var item in cachedSubjectList!) {
                        if (item['video_url'] == videoURL) {
                          item['isCached'] = false;
                        }
                      }
                    }
                    setState(() {});
                    RestClient().success('Offline Video Deleted');
                  },
                ),
              ] else ...[
                _buildOptionTile(
                  icon: Icons.download_outlined,
                  title: 'Save Offline',
                  subtitle: 'Download for offline viewing',
                  iconBackgroundColor: Colors.purple[50]!,
                  iconColor: Colors.purple,
                  onTap: () async {
                    Analytics().logEvent("SAVE_VIDEO_OFFLINE", {
                      "subject_name":
                          currentTutorial['subject_name'].toString(),
                      "video": currentTutorial['title'].toString()
                    });
                    Navigator.pop(context);
                    if (cachedSubjectList != null) {
                      for (var item in cachedSubjectList!) {
                        if (item['video_url'] == videoURL) {
                          item['isCached'] = true;
                        }
                      }
                    }
                    setState(() {});
                    DownloadManager().startDownload(
                      videoURL,
                      currentTutorial['title']?.toString() ?? 'Video Tutorial',
                      widget.course.title,
                    );
                  },
                ),
              ],
              // Only show Resource Guide if is_exam is 1
              if (currentTutorial != null && currentTutorial['is_exam'] == 1)
                _buildOptionTile(
                  icon: Icons.book_outlined,
                  title: 'Resource Guide',
                  subtitle: 'Access learning resources',
                  iconBackgroundColor: Colors.amber[50]!,
                  iconColor: Colors.amber[800]!,
                  onTap: () async {
                    final isOnline =
                        await RestClient().checkInternetConnection();
                    if (!mounted || !context.mounted) return;
                    if (!isOnline) {
                      Navigator.pop(context);
                      RestClient().error(
                          "No Internet. Unable to load Resource Guide. Connect to the Internet to Continue.");
                      return;
                    }
                    Analytics().logEvent("DOCUMENT_DOWNLOAD", {
                      "subject_name":
                          currentTutorial['subject_name'].toString(),
                      "video": currentTutorial['title'].toString()
                    });
                    final document =
                        currentTutorial['resource_guide'].toString();
                    debugPrint('=== RESOURCE GUIDE ===');
                    debugPrint('Document URL: $document');
                    if (document != "null" && document.isNotEmpty) {
                      if (!mounted || !context.mounted) return;
                      Navigator.pop(context);
                      globalScaffoldContext.loaderOverlay.show();
                      try {
                        final file = await createFileOfPdfUrl(document);
                        if (mounted) {
                          globalScaffoldContext.loaderOverlay.hide();
                        }
                        debugPrint('Resource Guide file created: ${file.path}');
                        debugPrint('File exists: ${await file.exists()}');
                        debugPrint('File size: ${await file.length()} bytes');
                        viewPDF(file.path);
                      } catch (e) {
                        if (mounted) {
                          globalScaffoldContext.loaderOverlay.hide();
                        }
                        debugPrint('Error with Resource Guide: $e');
                        RestClient().error('Error loading document: $e');
                      }
                    } else {
                      if (!mounted || !context.mounted) return;
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Resource Guide',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          content: Text(
                            'The resource guide is not available for this tutorial at this time. Please check back later or contact support if you need assistance.',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'UNDERSTOOD',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              // Only show Exam History if is_exam is 1
              if (currentTutorial != null && currentTutorial['is_exam'] == 1)
                _buildOptionTile(
                  icon: Icons.history,
                  title: 'Exam History',
                  subtitle: 'View your past exam results',
                  iconBackgroundColor: Colors.teal[50]!,
                  iconColor: Colors.teal,
                  onTap: () async {
                    Analytics().logEvent("CHECK_EXAM_HISTORY", {
                      "subject_name":
                          currentTutorial['subject_name'].toString(),
                      "video": currentTutorial['title'].toString()
                    });
                    _navigateWithVideoPause(
                      ExamHistory(tutorialID: tutorialID),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  viewPDF(url) async {
    debugPrint('viewPDF called with URL: $url');
    return await _navigateWithVideoPause(
      PDFScreen(path: url),
    );
  }

  Widget videoSaveOption(sisaave, videoURL, context) {
    final isDownloaded = sisaave || DownloadManager().isVideoDownloaded(videoURL);
    if (!isDownloaded) {
      return ListTile(
        leading: const Icon(Icons.download),
        title: const Text('Save Offline'),
        onTap: () async {
          Analytics().logEvent("SAVE_VIDEO_OFFLINE", {
            "subject_name": currentTutorial['subject_name'].toString(),
            "video": currentTutorial['title'].toString()
          });
          Navigator.pop(context);
          if (cachedSubjectList != null) {
            for (var item in cachedSubjectList!) {
              if (item['video_url'] == videoURL) {
                item['isCached'] = true;
              }
            }
          }
          setState(() {});
          DownloadManager().startDownload(
            videoURL,
            currentTutorial['title']?.toString() ?? 'Video Tutorial',
            widget.course.title,
          );
        },
      );
    } else {
      return ListTile(
        leading: const Icon(Icons.delete),
        title: const Text('Delete offline video'),
        onTap: () async {
          Analytics().logEvent("REMOVE_OFFLINE_VIDEO", {
            "subject_name": currentTutorial['subject_name'].toString(),
            "video": currentTutorial['title'].toString()
          });
          Navigator.pop(context);
          DownloadManager().removeCompletedVideo(videoURL);
          RestClient().success('Offline Video Deleted');
          if (cachedSubjectList != null) {
            for (var item in cachedSubjectList!) {
              if (item['video_url'] == videoURL) {
                item['isCached'] = false;
              }
            }
          }
          setState(() {});
        },
      );
    }
  }

  Widget _buildPlayingVideoDetails() {
    if (currentTutorial == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppTheme.backgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentTutorial!['title']?.toString() ?? '',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  Widget videoPlayer(playerHeight, controlBarHeight) {
    if (isVideoSet) {
      return Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: playerHeight,
              width: double.infinity,
              child: ClipRect(
                child: Platform.isWindows
                    ? _buildWindowsVideoPlayer()
                    : _buildAndroidVideoPlayer(),
              ),
            ),
            // Only show the Start Exam button if is_exam is 1
            if (currentTutorial != null && currentTutorial['is_exam'] == 1)
              Material(
                elevation: 4,
                color: AppTheme.primaryColor,
                child: InkWell(
                  onTap: startExam,
                  child: Container(
                    height: controlBarHeight,
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.assignment_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Start your Exam'.toUpperCase(),
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildWindowsVideoPlayer() {
    if (winVideoController != null && winVideoController!.value.isInitialized) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          // Cancel existing timer
          _controlsTimer?.cancel();
          // Hide controls after 3 seconds if they're visible
          if (_showControls) {
            _controlsTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showControls = false;
                });
              }
            });
          }
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video player
              Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: winVideoController!.value.size.width > 0
                        ? winVideoController!.value.size.width
                        : 1600,
                    height: winVideoController!.value.size.height > 0
                        ? winVideoController!.value.size.height
                        : 900,
                    child: VideoPlayer(winVideoController!),
                  ),
                ),
              ),
              // Loading indicator
              if (winVideoController!.value.isBuffering)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              // Center play button when paused
              if (!winVideoController!.value.isPlaying && _showControls)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 64,
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: () {
                        winVideoController!.play();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              // YouTube-style bottom controls
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildYouTubeStyleControls(),
                ),
            ],
          ),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
  }

  Widget _buildAndroidVideoPlayer() {
    if (flickManager != null) {
      return Theme(
        data: Theme.of(context).copyWith(
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        child: FlickVideoPlayer(
          flickManager: flickManager!,
          flickVideoWithControls: FlickVideoWithControls(
            videoFit: BoxFit.contain,
            controls: DefaultTextStyle(
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              child: FlickPortraitControls(
                progressBarSettings: FlickProgressBarSettings(
                  playedColor: AppTheme.primaryColor,
                  handleColor: AppTheme.primaryColor,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ),
          flickVideoWithControlsFullscreen: FlickVideoWithControls(
            videoFit: BoxFit.contain,
            controls: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: const IconThemeData(
                  color: Colors.white,
                ),
              ),
              child: const DefaultTextStyle(
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                child: FlickLandscapeControls(),
              ),
            ),
          ),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
  }

  Widget _buildYouTubeStyleControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: VideoProgressIndicator(
              winVideoController!,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              colors: const VideoProgressColors(
                playedColor: Colors.red,
                bufferedColor: Colors.white54,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          // Control buttons row
          Row(
            children: [
              // Play/Pause button
              IconButton(
                icon: Icon(
                  winVideoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  if (winVideoController!.value.isPlaying) {
                    winVideoController!.pause();
                  } else {
                    winVideoController!.play();
                  }
                  setState(() {}); // Only setState on user interaction
                },
              ),
              const SizedBox(width: 8),
              // Current time
              Text(
                _formatDuration(winVideoController!.value.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Text(
                ' / ',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                _formatDuration(winVideoController!.value.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Spacer(),
              // Volume control
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _currentVolume > 0.5
                          ? Icons.volume_up
                          : _currentVolume > 0
                              ? Icons.volume_down
                              : Icons.volume_off,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_currentVolume > 0) {
                          _currentVolume = 0;
                        } else {
                          _currentVolume = 1.0;
                        }
                        winVideoController!.setVolume(_currentVolume);
                      });
                    },
                  ),
                  SizedBox(
                    width: 60,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white54,
                        thumbColor: Colors.white,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: _currentVolume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() {
                            _currentVolume = value;
                            winVideoController!.setVolume(value);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Fullscreen button
              IconButton(
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _toggleFullScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      // Enter fullscreen mode
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => _buildFullScreenPlayer(),
          settings: const RouteSettings(name: '/fullscreen'),
        ),
      )
          .then((_) {
        setState(() {
          _isFullScreen = false;
        });
      });
    }
  }

  Widget _buildFullScreenPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
            // Cancel existing timer
            _controlsTimer?.cancel();
            // Hide controls after 3 seconds if they're visible
            if (_showControls) {
              _controlsTimer = Timer(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _showControls = false;
                  });
                }
              });
            }
          },
          child: Stack(
            children: [
              // Fullscreen video player
              Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: winVideoController!.value.size.width > 0
                        ? winVideoController!.value.size.width
                        : 1600,
                    height: winVideoController!.value.size.height > 0
                        ? winVideoController!.value.size.height
                        : 900,
                    child: VideoPlayer(winVideoController!),
                  ),
                ),
              ),
              // Loading indicator
              if (winVideoController!.value.isBuffering)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              // Center play button when paused
              if (!winVideoController!.value.isPlaying && _showControls)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 64,
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: () {
                        winVideoController!.play();
                        setState(() {}); // Only setState on user interaction
                      },
                    ),
                  ),
                ),
              // Fullscreen controls
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildFullScreenControls(),
                ),
              // Exit fullscreen button
              if (_showControls)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: VideoProgressIndicator(
              winVideoController!,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              colors: const VideoProgressColors(
                playedColor: Colors.red,
                bufferedColor: Colors.white54,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          // Control buttons row
          Row(
            children: [
              // Play/Pause button
              IconButton(
                icon: Icon(
                  winVideoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  if (winVideoController!.value.isPlaying) {
                    winVideoController!.pause();
                  } else {
                    winVideoController!.play();
                  }
                  setState(() {}); // Only setState on user interaction
                },
              ),
              const SizedBox(width: 16),
              // Current time
              Text(
                _formatDuration(winVideoController!.value.position),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const Text(
                ' / ',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                _formatDuration(winVideoController!.value.duration),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const Spacer(),
              // Volume control
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _currentVolume > 0.5
                          ? Icons.volume_up
                          : _currentVolume > 0
                              ? Icons.volume_down
                              : Icons.volume_off,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_currentVolume > 0) {
                          _currentVolume = 0;
                        } else {
                          _currentVolume = 1.0;
                        }
                        winVideoController!.setVolume(_currentVolume);
                      });
                    },
                  ),
                  SizedBox(
                    width: 100,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white54,
                        thumbColor: Colors.white,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _currentVolume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() {
                            _currentVolume = value;
                            winVideoController!.setVolume(value);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Exit fullscreen button
              IconButton(
                icon: const Icon(Icons.fullscreen_exit,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  Future<bool> isUrlCached(String url) async {
    try {
      FileInfo? fileInfo = await DefaultCacheManager().getFileFromCache(url);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  startExam() {
    // Check if exam is available for this tutorial
    if (currentTutorial == null || currentTutorial['is_exam'] != 1) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Exam Not Available',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          content: Text(
            'An exam is not available for this tutorial. Please continue watching the tutorial or explore other available content.',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'UNDERSTOOD',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    Analytics().logEvent("START_EXAM", {
      "subject_name": currentTutorial['subject_name'].toString(),
      "video": currentTutorial['title'].toString()
    });

    _navigateWithVideoPause(
      StartYourExam(tutorial: currentTutorial),
    );
  }

  void showLoadingIndicator() {
    globalScaffoldContext.loaderOverlay.show();
  }

  void hideLoadingIndicator() {
    globalScaffoldContext.loaderOverlay.hide();
  }

  Future<File> createFileOfPdfUrl(String prdUrl) async {
    Completer<File> completer = Completer<File>();
    try {
      debugPrint('createFileOfPdfUrl: Starting download from: $prdUrl');
      final url = prdUrl;
      Uri uri = Uri.parse(url);
      String fileName = uri.pathSegments.last;
      debugPrint('createFileOfPdfUrl: Filename: $fileName');

      var request = await HttpClient().getUrl(uri);
      debugPrint('createFileOfPdfUrl: Request sent');

      var response = await request.close();
      debugPrint(
          'createFileOfPdfUrl: Response received, status: ${response.statusCode}');

      var bytes = await consolidateHttpClientResponseBytes(response);
      debugPrint('createFileOfPdfUrl: Downloaded ${bytes.length} bytes');

      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/$fileName");
      debugPrint('createFileOfPdfUrl: Saving to: ${file.path}');

      await file.writeAsBytes(bytes, flush: true);
      debugPrint('createFileOfPdfUrl: File saved successfully');

      completer.complete(file);
    } catch (e) {
      debugPrint('createFileOfPdfUrl ERROR: $e');
      completer.completeError(e);
      throw Exception('Error parsing asset file!');
    }
    return completer.future;
  }

  @override
  void deactivate() {
    if (Platform.isWindows) {
      winVideoController?.pause();
    } else {
      flickManager?.flickVideoManager?.videoPlayerController?.pause();
    }
    super.deactivate();
  }

  void _onDownloadManagerChanged() {
    if (mounted) {
      if (DownloadManager().activeDownloads.isEmpty) {
        cachedSubjectList = null;
        _subjectListFuture = getSubjectList();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    DownloadManager().removeListener(_onDownloadManagerChanged);
    super.dispose();
    // Cancel timer
    _controlsTimer?.cancel();
    // Dispose platform-specific controllers
    if (Platform.isWindows) {
      winVideoController?.dispose();
    } else {
      flickManager?.dispose();
    }
  }
}
