import 'package:flutter/material.dart';
import 'dart:io';
import '../../Service/Analytics.dart';
import '../../Student/FeedbackController.dart';
import '../../Student/StartYourExam.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../Library/RestClient.dart';
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
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class Subject extends StatefulWidget {
  final Course course;
  const Subject({super.key, required this.course});
  @override
  State<Subject> createState() => _SubjectState();
}

class _SubjectState extends State<Subject> {
  var currentTutorial;
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

  // Windows video player controls state
  bool _showControls = true;
  bool _isFullScreen = false;
  double _currentVolume = 1.0;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();

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
    final listHeight = (pageHeight * 57) / 100;
    final playerHeight = (pageHeight * 30) / 100;
    final controlBarHeight = (pageHeight * 5) / 100;
    globalScaffoldContext = context;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            videoPlayer(playerHeight, controlBarHeight),
            if (!isVideoSet)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Available Tutorials',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            SizedBox(
              height: isVideoSet ? listHeight : pageHeight - 88,
              child: FutureBuilder(
                  future: getSubjectList(),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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
                  }),
            )
          ],
        ),
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
            ? BorderSide(color: AppTheme.primaryColor, width: 2)
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
                            Colors.grey.withOpacity(0.7),
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
                          ? AppTheme.primaryColor.withOpacity(0.7)
                          : isLocked
                              ? Colors.grey.withOpacity(0.7)
                              : Colors.black.withOpacity(0.5),
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
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: const BorderRadius.only(
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            tutorial['sub_title'].toString().toUpperCase(),
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isLocked
                  ? Colors.grey[500]
                  : isCurrentlyPlaying
                      ? AppTheme.primaryColor.withOpacity(0.7)
                      : AppTheme.textSecondaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentlyPlaying)
              Container(
                margin: const EdgeInsets.only(right: 8.0),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
            if (tutorial['isCached'])
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(Icons.download_for_offline,
                    color: Colors.green, size: 30),
              ),
            // Only show options menu for currently playing video
            if (isCurrentlyPlaying)
              IconButton(
                icon: Icon(
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

  submitYourFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => FeedbackController(
                tutorial: currentTutorial,
              )),
    );
  }

  getSubjectList() async {
    // Return cached list if available to prevent reloading
    if (cachedSubjectList != null) {
      return cachedSubjectList;
    }

    final currentCourse = widget.course;
    Analytics().logEvent(
        "VIEW_SUBJECT", {"subject_name": currentCourse.title.toString()});
    final currentCourseId = currentCourse.id;
    final response =
        await RestClient().authGet('/student/tutorials/$currentCourseId', {});
    if (response["status"] == 'success') {
      var videoList = [];
      for (var video in response["data"]) {
        final videoUrl = video['video_url'].toString();
        final isCached = await isUrlCached(videoUrl);
        video['isCached'] = isCached;
        videoList.add(video);
      }
      // Cache the result to avoid reloading
      cachedSubjectList = videoList;
      return videoList;
    } else {
      RestClient().error(response['data']);
      return []; // Return an empty list in case of an error
    }
  }

  playVideo(video) async {
    if (await RestClient().checkInternetConnection()) {
      changeVideo(video);
    } else {
      DefaultCacheManager().getSingleFile(video).then((file) {
        changeVideo(file.path);
      });
    }
  }

  void changeVideo(String videoUrl) {
    if (Platform.isWindows) {
      // For Windows platform
      winVideoController?.dispose();
      winVideoController =
          VideoPlayerController.networkUrl(Uri.parse(videoUrl));
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
      flickManager?.handleChangeVideo(
        VideoPlayerController.networkUrl(Uri.parse(videoUrl)),
      );
      // Set volume to maximum when video loads
      if (flickManager?.flickControlManager != null) {
        // Use unmute instead of setting mute property directly
        flickManager!.flickControlManager!.unmute();
      }
      // Set volume to maximum (1.0)
      flickManager?.flickVideoManager?.videoPlayerController?.setVolume(1.0);

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
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
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
              _buildOptionTile(
                icon: isCached ? Icons.delete_outline : Icons.download_outlined,
                title: isCached ? 'Delete offline video' : 'Save Offline',
                subtitle: isCached
                    ? 'Remove this video from device storage'
                    : 'Download for offline viewing',
                iconBackgroundColor:
                    isCached ? Colors.red[50]! : Colors.green[50]!,
                iconColor: isCached ? Colors.red : Colors.green,
                onTap: () async {
                  if (!isCached) {
                    Analytics().logEvent("SAVE_VIDEO_OFFLINE", {
                      "subject_name":
                          currentTutorial['subject_name'].toString(),
                      "video": currentTutorial['title'].toString()
                    });
                    Navigator.pop(context);
                    RestClient().success(
                        'We are saving your video offline, We will notify you when complete.');
                    DefaultCacheManager().getSingleFile(videoURL).then((file) {
                      RestClient()
                          .success('Video saved is now available offline');
                      setState(() {});
                    });
                  } else {
                    Analytics().logEvent("REMOVE_OFFLINE_VIDEO", {
                      "subject_name":
                          currentTutorial['subject_name'].toString(),
                      "video": currentTutorial['title'].toString()
                    });
                    globalScaffoldContext.loaderOverlay.show();
                    DefaultCacheManager().removeFile(videoURL);
                    globalScaffoldContext.loaderOverlay.hide();
                    Navigator.pop(context);
                    RestClient().error('Video Deleted offline');
                    setState(() {});
                  }
                },
              ),
              _buildOptionTile(
                icon: Icons.description_outlined,
                title: 'Video AID',
                subtitle: 'View supplementary material',
                iconBackgroundColor: Colors.blue[50]!,
                iconColor: Colors.blue,
                onTap: () async {
                  Analytics().logEvent("DOCUMENT_DOWNLOAD", {
                    "subject_name": currentTutorial['subject_name'].toString(),
                    "video": currentTutorial['title'].toString()
                  });
                  final document = currentTutorial['document_url'].toString();
                  debugPrint('=== VIDEO AID ===');
                  debugPrint('Document URL: $document');
                  if (document != "null" && document.isNotEmpty) {
                    Navigator.pop(context);
                    try {
                      final file = await createFileOfPdfUrl(document);
                      debugPrint('Video AID file created: ${file.path}');
                      debugPrint('File exists: ${await file.exists()}');
                      debugPrint('File size: ${await file.length()} bytes');
                      viewPDF(file.path);
                    } catch (e) {
                      debugPrint('Error with Video AID: $e');
                      RestClient().error('Error loading document: $e');
                    }
                  } else {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Video AID',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Supplementary materials are not available for this tutorial at this time. Please check back later or contact support if you believe this is an error.',
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
              // Only show Resource Guide if is_exam is 1
              if (currentTutorial != null && currentTutorial['is_exam'] == 1)
                _buildOptionTile(
                  icon: Icons.book_outlined,
                  title: 'Resource Guide',
                  subtitle: 'Access learning resources',
                  iconBackgroundColor: Colors.amber[50]!,
                  iconColor: Colors.amber[800]!,
                  onTap: () async {
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
                      Navigator.pop(context);
                      try {
                        final file = await createFileOfPdfUrl(document);
                        debugPrint('Resource Guide file created: ${file.path}');
                        debugPrint('File exists: ${await file.exists()}');
                        debugPrint('File size: ${await file.length()} bytes');
                        viewPDF(file.path);
                      } catch (e) {
                        debugPrint('Error with Resource Guide: $e');
                        RestClient().error('Error loading document: $e');
                      }
                    } else {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Row(
                            children: [
                              Icon(Icons.info_outline,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ExamHistory(
                                tutorialID: tutorialID,
                              )),
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
    return await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PDFScreen(
                path: url,
              )),
    );
  }

  Widget videoSaveOption(sisaave, videoURL, context) {
    if (!sisaave) {
      return ListTile(
        leading: const Icon(Icons.download),
        title: const Text('Save Offline'),
        onTap: () async {
          Analytics().logEvent("SAVE_VIDEO_OFFLINE", {
            "subject_name": currentTutorial['subject_name'].toString(),
            "video": currentTutorial['title'].toString()
          });
          Navigator.pop(context);
          RestClient().success(
              'We are saving your video offline, We will notify you when complete.');

          DefaultCacheManager().getSingleFile(videoURL).then((file) {
            RestClient().success('Video saved is now available offline');
            setState(() {});
          });
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
          globalScaffoldContext.loaderOverlay.show();
          DefaultCacheManager().removeFile(videoURL);
          globalScaffoldContext.loaderOverlay.hide();
          Navigator.pop(context);
          RestClient().error('Video Deleted offline');
          setState(() {});
        },
      );
    }
  }

  Widget videoPlayer(playerHeight, controlBarHeight) {
    if (isVideoSet) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: playerHeight,
              child: Platform.isWindows
                  ? _buildWindowsVideoPlayer()
                  : _buildAndroidVideoPlayer(),
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
                child: AspectRatio(
                  aspectRatio: winVideoController!.value.aspectRatio,
                  child: VideoPlayer(winVideoController!),
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
                      color: Colors.black.withOpacity(0.7),
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
      return FlickVideoPlayer(
        flickManager: flickManager!,
        flickVideoWithControls: const FlickVideoWithControls(
          controls: FlickPortraitControls(),
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
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
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
                  Container(
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
                child: AspectRatio(
                  aspectRatio: winVideoController!.value.aspectRatio,
                  child: VideoPlayer(winVideoController!),
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
                      color: Colors.black.withOpacity(0.7),
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
                      color: Colors.black.withOpacity(0.5),
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
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
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
                  Container(
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
              Icon(Icons.info_outline, color: AppTheme.primaryColor),
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

    // Pause the video before navigating to the exam page
    if (Platform.isWindows) {
      winVideoController?.pause();
    } else {
      if (flickManager?.flickVideoManager?.videoPlayerController != null) {
        flickManager!.flickVideoManager!.videoPlayerController!.pause();
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StartYourExam(
                tutorial: currentTutorial,
              )),
    ).then((_) {
      // Resume the video when returning from the exam page
      if (Platform.isWindows) {
        winVideoController?.play();
      } else {
        if (flickManager?.flickVideoManager?.videoPlayerController != null) {
          flickManager!.flickVideoManager!.videoPlayerController!.play();
        }
      }
    });
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
  void dispose() {
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
