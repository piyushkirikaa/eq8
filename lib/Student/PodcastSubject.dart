import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../../Service/Analytics.dart';
import '../../Service/AudioPlayerInterface.dart';
import '../../Service/AudioPlayerFactory.dart';
import '../Library/RestClient.dart';
import '../Widgets/Course.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'FeedbackController.dart';
import 'ExamHistory.dart';
import 'PDFScreen.dart';
import 'StartYourExam.dart';
import 'package:google_fonts/google_fonts.dart';

class PodcastSubject extends StatefulWidget {
  final Course course;
  const PodcastSubject({super.key, required this.course});
  @override
  State<PodcastSubject> createState() => _PodcastSubjectState();
}

class _PodcastSubjectState extends State<PodcastSubject> {
  dynamic currentTutorial;
  late AudioPlayerInterface _audioPlayer;
  bool isAudioSet = false;
  late List<dynamic> subjectList = [];
  int selectedIndex = -1;
  bool _isOnline = true;

  late BuildContext globalScaffoldContext;
  bool isSavingAudio = false;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double volume = 1.0; // Store volume level

  late Future<List<dynamic>> _subjectListFuture;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayerFactory.createAudioPlayer();

    // Set volume to full (1.0)
    _audioPlayer.setVolume(1.0);

    // Initialize the future
    _subjectListFuture = getSubjectList();

    // Listen to audio player states
    _audioPlayer.playingStream.listen((playing) {
      setState(() {
        isPlaying = playing;
      });
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((pos) {
      setState(() {
        position = pos;
      });
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((dur) {
      setState(() {
        duration = dur ?? Duration.zero;
      });
    });
  }

  // Format duration to mm:ss
  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Show volume control dialog
  void _showVolumeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Volume Control'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: (newVolume) {
                            setStateDialog(() {
                              volume = newVolume;
                            });
                            setState(() {
                              volume = newVolume;
                            });
                            _audioPlayer.setVolume(newVolume);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Set to maximum volume
                      setStateDialog(() {
                        volume = 1.0;
                      });
                      setState(() {
                        volume = 1.0;
                      });
                      _audioPlayer.setVolume(1.0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text(
                      'Maximum Volume',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    globalScaffoldContext = context;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.course.title.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback_outlined),
            tooltip: 'Feedback',
            onPressed: () {
              submitYourFeedback();
            },
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Volume Control',
            onPressed: () {
              _showVolumeDialog();
            },
          ),
        ],
      ),
      body: FutureBuilder(
          future: _subjectListFuture,
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: RestClient().loader(),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              if (snapshot.hasData) {
                final data = snapshot.data as List<dynamic>;
                final bool hasDownloadedAudios =
                    data.any((audio) => audio['isCached'] == true);

                if (!_isOnline && !hasDownloadedAudios) {
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
                            'Audio unavailable, please connect to the internet to continue learning.',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF757575),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (selectedIndex == -1 && data.isNotEmpty) {
                  // Auto-select first podcast
                  Future.microtask(() {
                    if (mounted) {
                      selectPodcast(0, data[0]);
                    }
                  });
                }

                return Column(
                  children: [
                    // Audio player area
                    buildAudioPlayer(),

                    // Playlist area
                    Expanded(
                      child: buildPlaylist(data),
                    ),
                  ],
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: RestClient().loader(),
                );
              }
            }
          }),
    );
  }

  Widget buildAudioPlayer() {
    if (isAudioSet && currentTutorial != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title area
            Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(
                          currentTutorial['video_cover_image'].toString()),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTutorial['title'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentTutorial['sub_title'].toString(),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Colors.purple,
                inactiveTrackColor: Colors.purple.shade100,
                thumbColor: Colors.purple,
              ),
              child: Slider(
                min: 0,
                max: duration.inMilliseconds.toDouble(),
                value: position.inMilliseconds.toDouble(),
                onChanged: (value) {
                  _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            ),

            // Position and duration indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatTime(position),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    formatTime(duration),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Player controls
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.replay_10, color: Colors.purple),
                    onPressed: () {
                      _audioPlayer.seek(position - const Duration(seconds: 10));
                    },
                  ),
                  const SizedBox(width: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(35),
                        onTap: () {
                          if (isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.forward_10, color: Colors.purple),
                    onPressed: () {
                      _audioPlayer.seek(position + const Duration(seconds: 10));
                    },
                  ),
                ],
              ),
            ),

            // Start Exam button
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: startExam,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size(MediaQuery.of(context).size.width, 0),
                elevation: 4,
              ),
              child: Text(
                'Start your Exam'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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

  Widget buildPlaylist(List<dynamic> data) {
    return Container(
      color: Colors.grey[100],
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final tutorial = data[index];
          final isSelected = selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Card(
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isSelected
                    ? BorderSide(color: Colors.purple.shade300, width: 1.5)
                    : BorderSide.none,
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(
                          tutorial['video_cover_image'].toString()),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                            )
                          ]
                        : null,
                  ),
                ),
                title: Text(
                  tutorial['title'],
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  tutorial['sub_title'].toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Colors.purple.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                selected: isSelected,
                selectedTileColor: Colors.purple.shade50.withValues(alpha: 0.3),
                onTap: () {
                  selectPodcast(index, tutorial);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void selectPodcast(int index, dynamic tutorial) {
    setState(() {
      selectedIndex = index;
      currentTutorial = tutorial;
    });
    Analytics().logEvent("LISTEN_AUDIO", {
      "subject_name": tutorial['subject_name'].toString(),
      "audio": tutorial['title'].toString()
    });
    playAudio(tutorial['audio_url'].toString());
  }

  // Rest of your existing methods here
  submitYourFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => FeedbackController(
                tutorial: currentTutorial,
              )),
    );
  }

  Future<List<dynamic>> getSubjectList() async {
    _isOnline = await RestClient().checkInternetConnection();
    final currentCourse = widget.course;
    Analytics().logEvent(
        "VIEW_SUBJECT", {"subject_name": currentCourse.title.toString()});
    final currentCourseId = currentCourse.id;
    final response = await RestClient()
        .authGet('/student/podcasts/information/$currentCourseId', {});
    if (response != null && response["status"] == 'success') {
      var audioList = [];
      for (var audio in response["data"]) {
        final audioUrl = audio['audio_url'].toString();
        final isCached = await isUrlCached(audioUrl);
        audio['isCached'] = isCached;
        audioList.add(audio);
      }
      subjectList = audioList;
      print("Audio list fetched successfully");
      return audioList;
    } else {
      RestClient().error(
          "Audio unavailable, please connect to the internet to continue learning.");
      print("Error fetching subject list: response is null or failed");
      return []; // Return an empty list in case of an error
    }
  }

  playAudio(audio) async {
    if (await RestClient().checkInternetConnection()) {
      final fileInfo = await DefaultCacheManager().getFileFromCache(audio);
      if (fileInfo != null) {
        changeAudio(fileInfo.file.path);
      } else {
        changeAudio(audio);
      }
    } else {
      final fileInfo = await DefaultCacheManager().getFileFromCache(audio);
      if (fileInfo != null) {
        changeAudio(fileInfo.file.path);
      } else {
        RestClient().error(
            "Audio unavailable, please connect to the internet to continue learning.");
      }
    }
  }

  audioOption(audioURL, tutorialID) async {
    final isCached = await isUrlCached(audioURL);
    audioOptionModal(isCached, audioURL, tutorialID);
  }

  Future<void> audioOptionModal(bool isCached, audioURL, tutorialID) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                    child: Text('Audio Options'.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold))),
                audioSaveOption(isCached, audioURL, context),
                const Divider(
                  height: 0,
                ),
                ListTile(
                  leading: const Icon(Icons.file_copy_outlined),
                  title: const Text('Audio AID'),
                  onTap: () async {
                    final isOnline =
                        await RestClient().checkInternetConnection();
                    if (!mounted || !context.mounted) return;
                    if (!isOnline) {
                      Navigator.pop(context);
                      RestClient().error(
                          "No Internet. Unable to load Audio AID. Connect to the Internet to Continue.");
                      return;
                    }
                    Analytics().logEvent("DOCUMENT_DOWNLOAD", {
                      "subject_name":
                          currentTutorial['subject_name'].toString(),
                      "audio": currentTutorial['title'].toString()
                    });
                    final document = currentTutorial['document_url'].toString();
                    if (document != "null") {
                      if (!mounted || !context.mounted) return;
                      Navigator.pop(context);
                      globalScaffoldContext.loaderOverlay.show();
                      try {
                        final file = await createFileOfPdfUrl(document);
                        if (mounted) {
                          globalScaffoldContext.loaderOverlay.hide();
                          viewPDF(file.path);
                        }
                      } catch (e) {
                        if (mounted) {
                          globalScaffoldContext.loaderOverlay.hide();
                          RestClient().error('Error loading document: $e');
                        }
                      }
                    } else {
                      RestClient().error('No document found');
                    }
                  },
                ),
                const Divider(
                  height: 0,
                ),
                ListTile(
                  leading: const Icon(Icons.file_copy_outlined),
                  title: const Text('Resource Guide'),
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
                      "audio": currentTutorial['title'].toString()
                    });
                    final document =
                        currentTutorial['resource_guide'].toString();
                    if (document != "null") {
                      if (!mounted || !context.mounted) return;
                      Navigator.pop(context);
                      globalScaffoldContext.loaderOverlay.show();
                      try {
                        final file = await createFileOfPdfUrl(document);
                        if (mounted) {
                          globalScaffoldContext.loaderOverlay.hide();
                          viewPDF(file.path);
                        }
                      } catch (e) {
                        if (mounted) {
                          globalScaffoldContext.loaderOverlay.hide();
                          RestClient().error('Error loading document: $e');
                        }
                      }
                    } else {
                      RestClient().error('No resource guide found');
                    }
                  },
                ),
                const Divider(
                  height: 0,
                ),
                ListTile(
                  leading: const Icon(Icons.file_copy_outlined),
                  title: const Text('Past Exam Papers'),
                  onTap: () async {
                    final isOnline =
                        await RestClient().checkInternetConnection();
                    if (!mounted || !context.mounted) return;
                    if (!isOnline) {
                      Navigator.pop(context);
                      RestClient().error(
                          "No Internet. Unable to load Past Exam Papers. Connect to the Internet to Continue.");
                      return;
                    }
                    Analytics().logEvent("DOCUMENT_DOWNLOAD", {
                      "subject_name":
                          currentTutorial['subject_name'].toString(),
                      "audio": currentTutorial['title'].toString()
                    });
                    final document =
                        currentTutorial['previous_exam'].toString();
                    if (document != "null") {
                      if (!mounted || !context.mounted) return;
                      Navigator.pop(context);
                      globalScaffoldContext.loaderOverlay.show();
                      try {
                        final file = await createFileOfPdfUrl(document);
                        if (mounted) {
                          globalScaffoldContext.loaderOverlay.hide();
                          viewPDF(file.path);
                        }
                      } catch (e) {
                        if (mounted) {
                          globalScaffoldContext.loaderOverlay.hide();
                          RestClient().error('Error loading document: $e');
                        }
                      }
                    } else {
                      RestClient().error('No past paper found');
                    }
                  },
                ),
                const Divider(
                  height: 0,
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Exam History'),
                  onTap: () async {
                    Analytics().logEvent("CHECK_EXAM_HISTORY", {
                      "subject_name":
                          currentTutorial['subject_name'].toString(),
                      "audio": currentTutorial['title'].toString()
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
          ),
        );
      },
    );
  }

  viewPDF(url) async {
    return await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PDFScreen(
                path: url,
              )),
    );
  }

  Widget audioSaveOption(sisaave, audioURL, context) {
    if (!sisaave) {
      return ListTile(
        leading: const Icon(Icons.download),
        title: const Text('Save Offline'),
        onTap: () async {
          Analytics().logEvent("SAVE_AUDIO_OFFLINE", {
            "subject_name": currentTutorial['subject_name'].toString(),
            "audio": currentTutorial['title'].toString()
          });
          Navigator.pop(context);
          RestClient().success(
              'We are saving your audio offline, We will notify you when complete.');
          DefaultCacheManager().getSingleFile(audioURL).then((file) {
            RestClient().success('Audio saved is now available offline');
            setState(() {});
          });
        },
      );
    } else {
      return ListTile(
        leading: const Icon(Icons.delete),
        title: const Text('Delete offline audio'),
        onTap: () async {
          Analytics().logEvent("REMOVE_OFFLINE_AUDIO", {
            "subject_name": currentTutorial['subject_name'].toString(),
            "audio": currentTutorial['title'].toString()
          });
          globalScaffoldContext.loaderOverlay.show();
          DefaultCacheManager().removeFile(audioURL);
          globalScaffoldContext.loaderOverlay.hide();
          Navigator.pop(context);
          RestClient().error('Audio Deleted offline');
          setState(() {});
        },
      );
    }
  }

  void changeAudio(String audioUrl) {
    _audioPlayer.setUrl(audioUrl);
    setState(() {
      isAudioSet = true;
      position = Duration.zero;
    });
    _audioPlayer.play();
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
    Analytics().logEvent("START_EXAM", {
      "subject_name": currentTutorial['subject_name'].toString(),
      "audio": currentTutorial['title'].toString()
    });

    // Pause audio before starting the exam
    _audioPlayer.pause();

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StartYourExam(
                tutorial: currentTutorial,
              )),
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
      final url = prdUrl;
      Uri uri = Uri.parse(url);
      String fileName = uri.pathSegments.last;
      var request = await HttpClient().getUrl(uri); // Corrected line
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/$fileName");
      await file.writeAsBytes(bytes, flush: true);
      completer.complete(file);
    } catch (e) {
      completer.completeError(e);
      throw Exception('Error parsing asset file!');
    }
    return completer.future;
  }

  @override
  void deactivate() {
    _audioPlayer.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
