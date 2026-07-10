import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamComplete extends StatefulWidget {
  final dynamic examStatus;
  final int timeTakenSeconds;
  const ExamComplete({super.key, required this.examStatus, required this.timeTakenSeconds});
  @override
  State<ExamComplete> createState() => _ExamComplete();
}

class _ExamComplete extends State<ExamComplete> {
  String _formatTimeTaken(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Exam Result',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3142),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      resultHeader(),
                      const SizedBox(height: 24),
                      resultCard(),
                      const SizedBox(height: 32),
                      dashboardButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget resultHeader() {
    final examStatus = widget.examStatus;
    final isPassed = examStatus['exam_status'] == "Pass";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPassed
            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
            : const Color(0xFFFFC107).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPassed
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : const Color(0xFFFFC107).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isPassed ? Icons.check_circle : Icons.star,
              color:
                  isPassed ? const Color(0xFF4CAF50) : const Color(0xFFFFC107),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPassed ? "Congratulations!" : "Good Effort!",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                Text(
                  isPassed
                      ? "You've successfully passed the exam."
                      : "Keep practicing to improve your score.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF8C8FA5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget resultCard() {
    final numberOfQuestions = widget.examStatus['number_of_questions'];
    final rightAnswers = widget.examStatus['right_answers'] ?? 0;
    final wrongAnswers = widget.examStatus['wrong_answers'] ?? 0;
    final examStatus = widget.examStatus;
    final isPassed = examStatus['exam_status'] == "Pass";

    // Calculate percentage correctly
    final percentage =
        numberOfQuestions > 0 ? (rightAnswers / numberOfQuestions) * 100 : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Score percentage & Time Taken with side-by-side circular indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFEEEFFF),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPassed
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFFC107),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${percentage.round()}%",
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      Text(
                        isPassed ? "Passed" : "Try Again",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isPassed
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFC107),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CircularProgressIndicator(
                      value: widget.timeTakenSeconds / 300,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFEEEFFF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF4D7CFE),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimeTaken(widget.timeTakenSeconds),
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      Text(
                        "Time Taken",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8C8FA5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Detailed score statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreStat(
                "Total Questions",
                "$numberOfQuestions",
                const Color(0xFF4D7CFE),
              ),
              _buildScoreStat(
                "Correct Answers",
                "$rightAnswers",
                const Color(0xFF4CAF50),
              ),
              _buildScoreStat(
                "Wrong Answers",
                "$wrongAnswers",
                const Color(0xFFEA4335),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Lottie animation
          SizedBox(
            height: 180,
            child: isPassed
                ? Lottie.asset('assets/Data/gold-medal-lottie.json',
                    repeat: true)
                : Lottie.asset('assets/Data/exam.json', repeat: true),
          ),

          const SizedBox(height: 16),

          // Motivational message
          Text(
            isPassed ? "Excellent work!" : "You can do better next time!",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPassed
                ? "Keep up the great work and continue your learning journey."
                : "Review the material again and try to improve your understanding.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8C8FA5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            label.contains("Total")
                ? Icons.assignment_outlined
                : label.contains("Correct")
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF8C8FA5),
          ),
        ),
      ],
    );
  }

  Widget dashboardButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Pop back through all exam screens to return to Subject
          // This pops: ExamComplete -> Test -> StartYourExam -> back to Subject
          // The .then() callback in Subject's startExam() will trigger and resume the video
          Navigator.of(context).pop(); // Pop ExamComplete
          Navigator.of(context).pop(); // Pop Test
          Navigator.of(context)
              .pop(); // Pop StartYourExam (triggers video resume in Subject)
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4D7CFE),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CONTINUE YOUR STUDY',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  double roundUp(String value, int places) {
    // Attempt to convert the string to a double. This works for both integer and
    // floating-point representations in the string.
    double? numericValue = double.tryParse(value);

    // Check if the conversion was successful.
    if (numericValue == null) {
      throw FormatException(
          "The provided string is not a valid number: $value");
    }

    // Perform the rounding operation. At this point, numericValue is a double,
    // and it doesn't matter if the original string represented an integer or
    // a floating-point number; the math works the same.
    double mod = pow(10.0, places).toDouble();
    return ((numericValue * mod).ceil().toDouble() / mod);
  }
}
