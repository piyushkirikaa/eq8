import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../Library/RestClient.dart';
import '../Service/Analytics.dart';
import '../SignIn.dart';
import 'StudentProfile.dart';
import '../Widgets/device_status_sheet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ExamHistory extends StatefulWidget {
  final dynamic tutorialID;
  const ExamHistory({super.key, this.tutorialID});
  @override
  State<ExamHistory> createState() => _ExamHistoryState();
}

class _ExamHistoryState extends State<ExamHistory> {
  // Statistics for charts
  int _passCount = 0;
  int _failCount = 0;
  double _averageScore = 0;
  double _highestScore = 0;
  List<Map<String, dynamic>> _examsData = [];
  bool _showChart = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        elevation: 0,
        title: Text('Exam History',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
            )),
        actions: [
          IconButton(
            icon: interNetCheck(),
            onPressed: () async {
              await _checkDeviceStatus();
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_box_outlined),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentProfile()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              alertOption();
            },
          ),
        ],
      ),
      body: FutureBuilder(
          future: getExamList(),
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: RestClient().loader());
            } else if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            } else {
              if (snapshot.hasData && snapshot.data.length > 0) {
                // Process data for statistics and charts
                _processExamData(snapshot.data);
                return _buildExamHistoryContent(snapshot.data);
              } else {
                return _buildEmptyDataWidget();
              }
            }
          }),
    );
  }

  Widget statusImage(status) {
    if (status == "Pass") {
      return const Image(
          image: AssetImage('assets/Images/like.gif'), width: 65);
    } else if (status == "Fail") {
      return const Image(
          image: AssetImage('assets/Images/mortarboard.gif'), width: 65);
    } else {
      return const Image(
          image: AssetImage('assets/Images/line-chart.gif'), width: 65);
    }
  }

  getExamList() async {
    final dynamic response;
    if (widget.tutorialID != "") {
      response = await RestClient()
          .authGet('/student/exam/history/${widget.tutorialID}', {});
    } else {
      response = await RestClient().authGet('/student/exam/history', {});
    }
    if (response["status"] == 'success') {
      return response["data"];
    } else {
      RestClient().error(response["data"].toString());
      return []; // Return an empty list in case of an error
    }
  }

  getExamDetail(tutorialID) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: <Widget>[
              // Header
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exam Detail',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
              ),

              // Status icon
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: (tutorialID['status'] == 'Pass'
                            ? Colors.green
                            : Colors.redAccent)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: statusImage(tutorialID['status'])),
                ),
              ),

              // Exam details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildDetailItem('Subject',
                          tutorialID['subject_name'] ?? 'Not available'),
                      _buildDetailItem(
                          'Tutorial', tutorialID['title'] ?? 'Not available'),
                      _buildDetailItem(
                          'Exam Date', _formatDate(tutorialID['created_at'])),
                      _buildDetailItem(
                          'Status', tutorialID['status'] ?? 'Not available',
                          valueColor: tutorialID['status'] == 'Pass'
                              ? Colors.green
                              : Colors.redAccent),
                      _buildDetailItem(
                          'Your Score',
                          tutorialID['exam_number'] != null
                              ? "${tutorialID['exam_number']}"
                              : "N/A"),
                      _buildDetailItem(
                          'Passing Marks',
                          tutorialID['passing_marks'] != null
                              ? "${tutorialID['passing_marks']}"
                              : "N/A"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not available';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: valueColor ?? Colors.grey[900],
                fontWeight:
                    valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget interNetCheck() {
    return FutureBuilder(
      future: RestClient().checkInternetConnection(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Icon(Icons.wifi_find_outlined);
        } else if (snapshot.hasError) {
          return const Icon(Icons.wifi_find_outlined);
        } else {
          if (snapshot.data) {
            return const Icon(Icons.wifi);
          } else {
            return const Icon(Icons.wifi_off);
          }
        }
      },
    );
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
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 220,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: <Widget>[
              // Header
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Log Out',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
              ),

              // Confirmation content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        'Are you sure you want to log out?',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'All your offline data will be lost.',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              logout();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Log Out',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void logout() async {
    if (mounted) {
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

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 70,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_edu,
            size: 70,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Exam History Found',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Complete your first exam to see your progress here.',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamHistoryContent(List<dynamic> data) {
    return Column(
      children: [
        // Statistics Summary Cards
        _buildStatisticsCards(),

        // Toggle View Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _showChart ? 'Chart View' : 'List View',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Switch(
                value: _showChart,
                activeThumbColor: Theme.of(context).primaryColor,
                onChanged: (value) {
                  setState(() {
                    _showChart = value;
                  });
                },
              ),
            ],
          ),
        ),

        // View Content: Charts or List
        Expanded(
          child: _showChart ? _buildCharts(data) : _buildExamList(data),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Average Score',
                _averageScore.toStringAsFixed(1),
                Icons.trending_up,
                Colors.blue,
              ),
              _buildStatCard(
                'Highest Score',
                _highestScore.toStringAsFixed(1),
                Icons.emoji_events,
                Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard(
                'C (Competent)',
                '$_passCount',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'NYC',
                '$_failCount',
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharts(List<dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Trend Chart Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Performance Trend',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),

            // Line Chart
            SizedBox(
              height: 220,
              child: _buildLineChart(),
            ),

            // Pass vs Fail Chart Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'C vs NYC',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),

            // Pie Chart
            SizedBox(
              height: 220,
              child: _buildPieChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    if (_examsData.isEmpty) {
      return const Center(child: Text('No data to show'));
    }

    // Prepare line chart data
    List<FlSpot> spots = [];
    for (int i = 0; i < _examsData.length; i++) {
      // Safely convert exam_number to double
      double score = 0.0;
      if (_examsData[i]['exam_number'] != null) {
        try {
          score = double.parse(_examsData[i]['exam_number'].toString());
        } catch (e) {
          score = 0.0;
        }
      }
      spots.add(FlSpot(i.toDouble(), score));
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double minWidth = screenWidth - 32; // Width of screen minus padding
    final double calculatedWidth = _examsData.length * 60.0; // 60px per data point
    final double chartWidth = calculatedWidth > minWidth ? calculatedWidth : minWidth;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Container(
          width: chartWidth,
          height: 220,
          padding: const EdgeInsets.only(bottom: 12),
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        spot.y.toStringAsFixed(1),
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < _examsData.length) {
                        String label = 'Exam ${value.toInt() + 1}';
                        String? dateString = _examsData[value.toInt()]['created_at'];
                        if (dateString != null && dateString.isNotEmpty) {
                          try {
                            final DateTime date = DateTime.parse(dateString);
                            label = DateFormat('dd/MM/yy').format(date);
                          } catch (e) {
                            // fallback to default label
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: Transform.rotate(
                            angle: -1.5708, // -90 degrees in radians (bottom to top)
                            child: Text(
                              label,
                              style: GoogleFonts.lato(fontSize: 12),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_passCount == 0 && _failCount == 0) {
      return const Center(child: Text('No data to show'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            title: 'C\n$_passCount',
            value: _passCount.toDouble(),
            color: Colors.green,
            radius: 80,
            titleStyle: GoogleFonts.lato(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          PieChartSectionData(
            title: 'NYC\n$_failCount',
            value: _failCount.toDouble(),
            color: Colors.redAccent,
            radius: 80,
            titleStyle: GoogleFonts.lato(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamList(List<dynamic> data) {
    return ListView.builder(
      itemCount: data.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final tutorial = data[index];

        // Format the date properly
        String formattedDate;
        try {
          final DateTime date = DateTime.parse(tutorial['created_at']);
          formattedDate = DateFormat('MMM dd, yyyy').format(date);
        } catch (e) {
          formattedDate = tutorial['created_at'] ?? 'Unknown date';
        }

        // Extract exam status and determine style colors
        final String status = tutorial['status'] ?? '';
        final Color statusColor =
            status == 'Pass' ? Colors.green : Colors.redAccent;

        // Extract marks and passing marks
        final examMarks = tutorial['exam_number'] != null
            ? tutorial['exam_number'].toString()
            : "N/A";
        final passingMarks = tutorial['passing_marks'] ?? 'N/A';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => getExamDetail(tutorial),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Status icon
                  Container(
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: statusImage(status),
                  ),
                  const SizedBox(width: 16),
                  // Exam details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tutorial['subject_name'] ?? 'Unknown Subject',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Score: $examMarks / $passingMarks',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _processExamData(List<dynamic> data) {
    _passCount = 0;
    _failCount = 0;
    double totalScore = 0.0;
    _highestScore = 0.0;
    _examsData = [];

    if (data.isEmpty) return;

    for (var exam in data) {
      // Convert to Map and add to exams data for charts
      _examsData.add(Map<String, dynamic>.from(exam));

      // Count pass/fail
      if (exam['status'] == 'Pass') {
        _passCount++;
      } else if (exam['status'] == 'Fail') {
        _failCount++;
      }

      // Calculate scores safely
      double examScore = 0.0;
      if (exam['exam_number'] != null) {
        // Safely convert to double
        try {
          examScore = double.parse(exam['exam_number'].toString());
        } catch (e) {
          examScore = 0.0; // Default to 0 if conversion fails
        }

        totalScore += examScore;

        if (examScore > _highestScore) {
          _highestScore = examScore;
        }
      }
    }

    _averageScore = data.isNotEmpty ? totalScore / data.length : 0.0;
  }
}
