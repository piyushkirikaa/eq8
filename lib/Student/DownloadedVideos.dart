import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Library/DownloadManager.dart';
import '../Library/RestClient.dart';

class DownloadedVideos extends StatefulWidget {
  const DownloadedVideos({super.key});

  @override
  State<DownloadedVideos> createState() => _DownloadedVideosState();
}

class _DownloadedVideosState extends State<DownloadedVideos> {
  final DownloadManager _downloadManager = DownloadManager();

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

  // Initial cached offline videos list
  final List<Map<String, dynamic>> _initialDownloadedVideos = [
    {
      'id': '101',
      'title': 'Algebraic Equations & Functions Overview',
      'subject': 'Mathematics',
      'duration': '14:20',
      'size': '45 MB',
      'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_math.mp4',
      'downloaded_at': DateTime.now().subtract(const Duration(minutes: 5)),
    },
    {
      'id': '102',
      'title': 'Newton Laws of Motion & Momentum',
      'subject': 'Physical Sciences',
      'duration': '18:45',
      'size': '62 MB',
      'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_physics.mp4',
      'downloaded_at': DateTime.now().subtract(const Duration(minutes: 45)),
    },
    {
      'id': '103',
      'title': 'Cellular Respiration & Photosynthesis',
      'subject': 'Life Sciences',
      'duration': '12:10',
      'size': '38 MB',
      'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_bio.mp4',
      'downloaded_at': DateTime.now().subtract(const Duration(hours: 3)),
    },
    {
      'id': '104',
      'title': 'Financial Statements & Balance Sheets',
      'subject': 'Accounting',
      'duration': '22:05',
      'size': '70 MB',
      'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_acc.mp4',
      'downloaded_at': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '105',
      'title': 'Shakespeare Literature Analysis',
      'subject': 'English',
      'duration': '15:30',
      'size': '50 MB',
      'video_url': 'https://www.mydigitalcollege.co.za/crm/api/sample_eng.mp4',
      'downloaded_at': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  late List<Map<String, dynamic>> _localVideos;

  @override
  void initState() {
    super.initState();
    _selectedSubjects = List<String>.from(_availableSubjects);
    _tempSelectedSubjects = List<String>.from(_selectedSubjects);
    _tempSelectAll = true;
    _localVideos = List<Map<String, dynamic>>.from(_initialDownloadedVideos);
    _downloadManager.addListener(_onDownloadManagerChanged);
  }

  @override
  void dispose() {
    _downloadManager.removeListener(_onDownloadManagerChanged);
    super.dispose();
  }

  void _onDownloadManagerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDownloadedTime(dynamic date) {
    if (date is! DateTime) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // Combined downloaded videos sorted by most recently downloaded first (descending by date)
  List<Map<String, dynamic>> get _allDownloadedVideos {
    final list = List<Map<String, dynamic>>.from(_localVideos);
    for (var completed in _downloadManager.completedVideos) {
      if (!list.any((v) => v['id'] == completed['id'])) {
        list.add(completed);
      }
    }

    // Default sorting: Descending order by date downloaded (most recent first)
    list.sort((a, b) {
      final dateA = (a['downloaded_at'] as DateTime?) ?? DateTime(2020);
      final dateB = (b['downloaded_at'] as DateTime?) ?? DateTime(2020);
      return dateB.compareTo(dateA);
    });

    return list;
  }

  // Filtered list based on selected subjects
  List<Map<String, dynamic>> get _filteredVideos {
    final all = _allDownloadedVideos;
    if (_selectAll || _selectedSubjects.length == _availableSubjects.length) {
      return all;
    }
    return all
        .where((video) => _selectedSubjects.contains(video['subject']))
        .toList();
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
                final videoUrl = video['video_url']?.toString() ?? '';
                _downloadManager.removeCompletedVideo(videoUrl);
                setState(() {
                  _localVideos.removeWhere((v) => v['id'] == video['id']);
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
    final activeTasks = _downloadManager.activeDownloads;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: Text(
          'Offline Videos',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
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
              // Active Real-Time Downloads Section (Circular Progress Ring Only)
              if (activeTasks.isNotEmpty) ...[
                Text(
                  'Downloading Videos (${activeTasks.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[900],
                  ),
                ),
                const SizedBox(height: 10),
                ...activeTasks.map((task) {
                  final percentInt = (task.progress * 100).toInt();

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          // Circular Filling Progress Ring with centered percent
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: task.progress,
                                  strokeWidth: 4.5,
                                  backgroundColor: Colors.purple[100],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                                ),
                                Text(
                                  '$percentInt%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    task.subject,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[900],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  task.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${task.downloadedMB.toStringAsFixed(1)} MB / ${task.totalMB.toStringAsFixed(1)} MB • ${task.timeRemaining}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Stop / Cancel button (Icons.stop_circle)
                          IconButton(
                            icon: const Icon(
                              Icons.stop_circle,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                            tooltip: 'Cancel Download',
                            onPressed: () => _downloadManager.cancelDownload(task.id),
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
                                    '${video['duration']} • ${video['size']} • ${_formatDownloadedTime(video['downloaded_at'])}',
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
