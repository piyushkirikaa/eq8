import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../Library/RestClient.dart';
import '../Service/Analytics.dart';
import '../SignIn.dart';
import 'StudentProfile.dart';
import '../Widgets/device_status_sheet.dart';
import 'dart:async';
import '../Widgets/ConnectivityIcon.dart';

class ExamReport extends StatefulWidget {
  const ExamReport({super.key});

  @override
  State<ExamReport> createState() => _ExamReportState();
}

class _ExamReportState extends State<ExamReport>
    with SingleTickerProviderStateMixin {
  final List<Color> chartColors = [
    const Color(0xFF4285F4), // Google Blue
    const Color(0xFFEA4335), // Google Red
    const Color(0xFF34A853), // Google Green
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFFFFA000), // Amber
    const Color(0xFF009688), // Teal
    const Color(0xFF9E9E9E), // Grey
    const Color(0xFF3949AB), // Indigo
    const Color(0xFF00ACC1), // Cyan
    const Color(0xFFE91E63), // Pink
  ];

  // Animation controllers and properties
  late AnimationController _animationController;
  late Animation<double> _animation;
  int touchedIndex = -1;
  double _chartAnimationValue = 0;

  // Future cache to prevent rebuild reloading
  late Future<List<dynamic>> _examScoresFuture;

  // Scroll tracking for pie chart scaling
  late ScrollController _scrollController;
  bool _isScrolledDown = false;

  @override
  void initState() {
    super.initState();
    // Initialize analytics
    Analytics().logEvent('exam_report_viewed', {});

    _examScoresFuture = getExamAverageScores();

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Set up the animation controller for pie chart animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );

    _animation.addListener(() {
      setState(() {
        _chartAnimationValue = _animation.value;
      });
    });

    // Start the animation when the widget is created
    _animationController.forward();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 10 && !_isScrolledDown) {
        setState(() {
          _isScrolledDown = true;
        });
      } else if (_scrollController.offset <= 10 && _isScrolledDown) {
        setState(() {
          _isScrolledDown = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isIPad = MediaQuery.of(context).size.shortestSide >= 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        actions: [
          IconButton(
            icon: const ConnectivityIcon(),
            onPressed: () async {
              await _checkDeviceStatus();
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_box_outlined),
            tooltip: 'profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentProfile()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'log',
            onPressed: () async {
              alertOption();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
          future: _examScoresFuture,
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: RestClient().loader());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              if (snapshot.hasData && snapshot.data.length > 0) {
                final List<dynamic> data = List.from(snapshot.data);
                data.sort((a, b) {
                  final aAvg =
                      double.tryParse(a['average_number'].toString()) ?? 0.0;
                  final bAvg =
                      double.tryParse(b['average_number'].toString()) ?? 0.0;
                  return bAvg.compareTo(aAvg);
                });
                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        height: _isScrolledDown
                            ? (isIPad
                                ? 230.0
                                : MediaQuery.of(context).size.height * 0.25)
                            : (isIPad
                                ? 460.0
                                : MediaQuery.of(context).size.height * 0.50),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              'Subject Performance Overview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: AnimatedScale(
                                scale: _isScrolledDown ? 0.5 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: AspectRatio(
                                  aspectRatio: 1.3,
                                  child: PieChart(
                                    PieChartData(
                                      pieTouchData: PieTouchData(
                                        touchCallback: (FlTouchEvent event,
                                            pieTouchResponse) {
                                          setState(() {
                                            if (!event
                                                    .isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse
                                                        .touchedSection ==
                                                    null) {
                                              touchedIndex = -1;
                                              return;
                                            }
                                            touchedIndex = pieTouchResponse
                                                .touchedSection!
                                                .touchedSectionIndex;
                                          });
                                        },
                                      ),
                                      startDegreeOffset: 180,
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 1,
                                      centerSpaceRadius:
                                          (isIPad ? 60.0 : 52.5) *
                                              _chartAnimationValue,
                                      sections: showingSections(data, isIPad),
                                    ),
                                    swapAnimationDuration:
                                        const Duration(milliseconds: 400),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 20, 16, 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.analytics_outlined,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Per Subject Performance',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final subject = data[index];
                                final color =
                                    chartColors[index % chartColors.length];
                                final isSelected = index == touchedIndex;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isSelected ? 0.08 : 0.04),
                                        blurRadius: isSelected ? 4 : 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        touchedIndex =
                                            index == touchedIndex ? -1 : index;
                                      });
                                    },
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      leading: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: color,
                                        ),
                                      ),
                                      title: Text(
                                        subject['subject_name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[850],
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Avg: ${(subject['average_number'] as num).toStringAsFixed(1)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: getScoreColor(
                                                  (subject['average_number']
                                                          as num)
                                                      .toDouble()),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 80,
                                            height: 6,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              child: LinearProgressIndicator(
                                                value:
                                                    (subject['average_number']
                                                                as num)
                                                            .toDouble() /
                                                        10,
                                                backgroundColor:
                                                    Colors.grey[200] ??
                                                        Colors.grey.shade200,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  getScoreColor(
                                                      (subject['average_number']
                                                              as num)
                                                          .toDouble()),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "NO EXAM DATA AVAILABLE",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Complete exams to generate your performance report",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
            }
          }),
    );
  }

  List<PieChartSectionData> showingSections(List<dynamic> data, bool isIPad) {
    final double total = data.fold(
        0.0, (sum, item) => sum + (item['average_number'] as num).toDouble());

    return List.generate(data.length, (i) {
      final subject = data[i];
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 14.0 : 12.0;
      final baseRadius = isIPad ? 120.0 : 105.0;
      final touchedRadius = isIPad ? 140.0 : 122.5;
      final radius = isTouched
          ? touchedRadius * _chartAnimationValue
          : baseRadius * _chartAnimationValue;
      final color = chartColors[i % chartColors.length];

      // Calculate a value for the pie chart segment
      final value = (subject['average_number'] as num).toDouble();

      // Calculate the percentage for display
      final percentage = ((value / total) * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: color,
        value: value,
        title: '$percentage%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
            ),
          ],
        ),
        badgeWidget: isTouched
            ? _buildIndicator(subject['subject_name'], value, color)
            : null,
        badgePositionPercentageOffset: 1.1,
      );
    });
  }

  Widget _buildIndicator(String subjectName, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              subjectName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${value.toStringAsFixed(1)})',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getScoreColor(double score) {
    if (score >= 8) {
      return Colors.green;
    } else if (score >= 6) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  Future<List<dynamic>> getExamAverageScores() async {
    final response =
        await RestClient().authGet('/student/exam/average-scores', {});
    if (response != null && response["status"] == 'success') {
      return response["data"];
    } else {
      if (response != null) {
        RestClient().error(response["data"].toString());
      }
      return []; // Return an empty list in case of an error
    }
  }



  _checkDeviceStatus() async {
    if (mounted) {
      context.loaderOverlay.show();
    }
    final isConnected = await RestClient().checkInternetConnection();
    if (mounted) {
      context.loaderOverlay.hide();
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return DeviceStatusSheet(isConnected: isConnected);
      },
    );
  }

  Future<void> alertOption() {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                    child: Text('Are You Sure?'.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold))),
                const SizedBox(
                  height: 5,
                ),
                Center(
                    child: Text('All Your Offline Data Will Lost'.toUpperCase(),
                        style: const TextStyle(fontSize: 16))),
                const Divider(),
                Center(
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      logout();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.logout,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void logout() async {
    if (context.mounted) {
      context.loaderOverlay.show();
    }
    try {
      await Analytics().logEvent('logout', {});
    } catch (e) {
      print('Error logging event: $e');
    }
    try {
      await RestClient().logout();
    } catch (e) {
      print('Error during logout: $e');
    }
    if (mounted) {
      context.loaderOverlay.hide();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignIn()),
      );
    }
  }
}
