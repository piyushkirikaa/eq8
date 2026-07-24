import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Library/RestClient.dart';

class DownloadedVideos extends StatefulWidget {
  const DownloadedVideos({super.key});

  @override
  State<DownloadedVideos> createState() => _DownloadedVideosState();
}

class _DownloadedVideosState extends State<DownloadedVideos> {
  // Available subjects for filtering
  final List<String> _availableSubjects = [
    'Mathematics',
    'Physical Sciences',
    'Life Sciences',
    'Accounting',
    'English',
    'Geography',
    'History',
    'Business Studies',
  ];

  // Currently active selected subject filters (defaults to all selected)
  late List<String> _selectedSubjects;
  bool _selectAll = true;

  // Temp selections inside the filter bottom sheet
  late List<String> _tempSelectedSubjects;
  late bool _tempSelectAll;

  // Active in-progress downloads
  final List<Map<String, dynamic>> _activeDownloads = [];
  Timer? _simulatedDownloadTimer;

  // Sample/cached offline videos list
  final List<Map<String, dynamic>> _downloadedVideos = [
    {
      'id': 101,
      'title': 'Algebraic Equations & Functions Overview',
      'subject': 'Mathematics',
      'duration': '14:20',
      'size': '45 MB',
      'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_math.mp4',
    },
    {
      'id': 102,
      'title': 'Newton Laws of Motion & Momentum',
      'subject': 'Physical Sciences',
      'duration': '18:45',
      'size': '62 MB',
      'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_physics.mp4',
    },
    {
      'id': 103,
      'title': 'Cellular Respiration & Photosynthesis',
      'subject': 'Life Sciences',
      'duration': '12:10',
      'size': '38 MB',
      'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_bio.mp4',
    },
    {
      'id': 104,
      'title': 'Financial Statements & Balance Sheets',
      'subject': 'Accounting',
      'duration': '22:05',
      'size': '70 MB',
      'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_acc.mp4',
    },
    {
      'id': 105,
      'title': 'Shakespeare Literature Analysis',
      'subject': 'English',
      'duration': '15:30',
      'size': '50 MB',
      'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_eng.mp4',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedSubjects = List<String>.from(_availableSubjects);
    _tempSelectedSubjects = List<String>.from(_selectedSubjects);
    _tempSelectAll = true;
  }

  @override
  void dispose() {
    _simulatedDownloadTimer?.cancel();
    super.dispose();
  }

  // Filtered list based on selected subjects
  List<Map<String, dynamic>> get _filteredVideos {
    if (_selectAll || _selectedSubjects.length == _availableSubjects.length) {
      return _downloadedVideos;
    }
    return _downloadedVideos
        .where((video) => _selectedSubjects.contains(video['subject']))
        .toList();
  }

  void _startDownloadWithProgress(String videoUrl, String title, String subject) {
    // Check if already downloading
    if (_activeDownloads.any((item) => item['video_url'] == videoUrl)) {
      RestClient().error('Download already in progress for this video');
      return;
    }

    final newDownload = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': title,
      'subject': subject,
      'video_url': videoUrl,
      'progress': 0.0,
      'downloadedMB': 0.0,
      'totalMB': 50.0,
    };

    setState(() {
      _activeDownloads.add(newDownload);
    });

    RestClient().success('Started downloading "$title"');

    // Subscribe to real-time cache stream
    try {
      DefaultCacheManager().getFileStream(videoUrl, withProgress: true).listen(
        (FileResponse response) {
          if (response is DownloadProgress) {
            final double progress = response.progress ?? 0.0;
            final double totalMB = (response.totalSize ?? 50 * 1024 * 1024) / (1024 * 1024);
            final double downloadedMB = (response.downloaded) / (1024 * 1024);

            if (mounted) {
              setState(() {
                newDownload['progress'] = progress;
                newDownload['downloadedMB'] = downloadedMB;
                newDownload['totalMB'] = totalMB;
              });
            }
          } else if (response is FileInfo) {
            if (mounted) {
              setState(() {
                _activeDownloads.removeWhere((item) => item['id'] == newDownload['id']);
                _downloadedVideos.add({
                  'id': newDownload['id'],
                  'title': title,
                  'subject': subject,
                  'duration': '16:00',
                  'size': '${((newDownload['totalMB'] as double?) ?? 50.0).toStringAsFixed(1)} MB',
                  'video_url': videoUrl,
                });
              });
              RestClient().success('Downloaded "$title" successfully!');
            }
          }
        },
        onError: (_) {
          _cancelDownload(newDownload['id']);
        },
      );
    } catch (_) {
      // Fallback simulated progress for demo/sample URLs
      _startSimulatedDownload(newDownload);
    }
  }

  void _startSimulatedDownload(Map<String, dynamic> downloadItem) {
    _simulatedDownloadTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final double currentProg = downloadItem['progress'] as double;
      if (currentProg >= 1.0) {
        timer.cancel();
        setState(() {
          _activeDownloads.removeWhere((item) => item['id'] == downloadItem['id']);
          _downloadedVideos.add({
            'id': downloadItem['id'],
            'title': downloadItem['title'],
            'subject': downloadItem['subject'],
            'duration': '15:00',
            'size': '50.0 MB',
            'video_url': downloadItem['video_url'],
          });
        });
        RestClient().success('Downloaded "${downloadItem['title']}" successfully!');
      } else {
        setState(() {
          final newProg = (currentProg + 0.08).clamp(0.0, 1.0);
          downloadItem['progress'] = newProg;
          downloadItem['downloadedMB'] = newProg * 50.0;
          downloadItem['totalMB'] = 50.0;
        });
      }
    });
  }

  void _cancelDownload(dynamic id) {
    setState(() {
      _activeDownloads.removeWhere((item) => item['id'] == id);
    });
    RestClient().error('Download cancelled');
  }

  void _openFilterBottomSheet() {
    _tempSelectedSubjects = List<String>.from(_selectedSubjects);
    _tempSelectAll = _selectAll;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 20, bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Offline Videos',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0C132F),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  CheckboxListTile(
                    activeColor: Colors.purple,
                    title: Text(
                      'All Offline Videos',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[800],
                      ),
                    ),
                    value: _tempSelectAll,
                    onChanged: (bool? value) {
                      setModalState(() {
                        _tempSelectAll = value ?? false;
                        if (_tempSelectAll) {
                          _tempSelectedSubjects =
                              List<String>.from(_availableSubjects);
                        } else {
                          _tempSelectedSubjects.clear();
                        }
                      });
                    },
                  ),
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = _availableSubjects[index];
                        final isChecked =
                            _tempSelectedSubjects.contains(subject);
                        return CheckboxListTile(
                          activeColor: Colors.purple,
                          title: Text(
                            subject,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          value: isChecked,
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                if (!_tempSelectedSubjects.contains(subject)) {
                                  _tempSelectedSubjects.add(subject);
                                }
                              } else {
                                _tempSelectedSubjects.remove(subject);
                              }
                              _tempSelectAll = _tempSelectedSubjects.length ==
                                  _availableSubjects.length;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedSubjects =
                              List<String>.from(_tempSelectedSubjects);
                          _selectAll = _tempSelectAll;
                        });
                        Navigator.pop(context);
                        RestClient().success('Filters applied successfully');
                      },
                      child: Text(
                        'SUBMIT',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteVideo(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Offline Video', style: GoogleFonts.poppins()),
          content: Text(
            'Are you sure you want to remove "${video['title']}" from offline storage?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                try {
                  DefaultCacheManager().removeFile(video['video_url']);
                } catch (_) {}
                setState(() {
                  _downloadedVideos.removeWhere((v) => v['id'] == video['id']);
                });
                RestClient().success('Offline Video Deleted');
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredVideos;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: Text(
          'Downloaded Videos',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_photos_rounded, color: Colors.white),
            tooltip: 'Simulate Real-time Download',
            onPressed: () {
              _startDownloadWithProgress(
                'https://www.mydigitalcollege.co.za/crm/api/sample_demo_${DateTime.now().millisecondsSinceEpoch}.mp4',
                'Organic Chemistry & Chemical Bonds',
                'Physical Sciences',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            tooltip: 'Filter by Subject',
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Real-time Downloads Section
              if (_activeDownloads.isNotEmpty) ...[
                Text(
                  'Downloading Videos (${_activeDownloads.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[900],
                  ),
                ),
                const SizedBox(height: 8),
                ..._activeDownloads.map((download) {
                  final progress = (download['progress'] as double).clamp(0.0, 1.0);
                  final percentInt = (progress * 100).toInt();
                  final downloadedMB = (download['downloadedMB'] as double).toStringAsFixed(1);
                  final totalMB = (download['totalMB'] as double).toStringAsFixed(1);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  download['subject'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$percentInt%',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[800],
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(left: 8),
                                icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                                onPressed: () => _cancelDownload(download['id']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            download['title'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.purple[50],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Downloading: $downloadedMB MB / $totalMB MB',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Filtered Downloaded Videos Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Offline Saved Videos (${filtered.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0C132F),
                    ),
                  ),
                  if (!_selectAll)
                    Chip(
                      backgroundColor: Colors.purple[50],
                      label: Text(
                        'Filtered',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.purple[900]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_for_offline_outlined,
                          size: 70,
                          color: Colors.purple[200],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No Videos Found',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0C132F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No offline videos match your current subject filter choice.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedSubjects = List<String>.from(_availableSubjects);
                              _selectAll = true;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final video = filtered[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_circle_fill,
                                color: Colors.purple,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      video['subject'] ?? 'Subject',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple[900],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    video['title'] ?? 'Video Title',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${video['duration']} • ${video['size']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              tooltip: 'Delete offline video',
                              onPressed: () => _deleteVideo(video),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
