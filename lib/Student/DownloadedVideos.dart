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

  // Filtered list based on selected subjects
  List<Map<String, dynamic>> get _filteredVideos {
    if (_selectAll || _selectedSubjects.length == _availableSubjects.length) {
      return _downloadedVideos;
    }
    return _downloadedVideos
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
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            tooltip: 'Filter by Subject',
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: filtered.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download_for_offline_outlined,
                      size: 80,
                      color: Colors.purple[200],
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedSubjects =
                              List<String>.from(_availableSubjects);
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
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.purple,
                            size: 32,
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
    );
  }
}
