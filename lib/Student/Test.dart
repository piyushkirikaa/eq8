import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import '../../Student/ExamComplete.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Library/RestClient.dart';
import '../Service/Analytics.dart';

class Test extends StatefulWidget {
  final dynamic examConfig;
  final dynamic tutorial;
  const Test({super.key, required this.examConfig, required this.tutorial});
  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  late BuildContext globalScaffoldContext;

  int _questionIndex = 0;
  List<dynamic> _questions = [];
  double completionPercentage = 0;
  late final List<dynamic> _answers;

  Timer? _examTimer;
  int _secondsRemaining = 300;

  int get _displayQuestionNumber {
    if (_questions.isEmpty) return 0;
    return (_questionIndex + 1).clamp(1, _questions.length);
  }

  @override
  void initState() {
    super.initState();
    _questions = widget.examConfig['questions'];
    _answers = List<dynamic>.filled(_questions.length, null, growable: false);
    _startTimer();
  }

  void _startTimer() {
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _examTimer?.cancel();
        _examComplete(); // Auto-submit when time is up
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _examTimer?.cancel();
    super.dispose();
  }

  void _setAnswerForQuestion(int index, dynamic answerObj) {
    setState(() {
      _answers[index] = answerObj;
      int answeredCount = _answers.where((a) => a != null).length;
      completionPercentage = (_questions.isEmpty)
          ? 0
          : ((answeredCount / _questions.length) * 100);
    });
  }

  void _previousQuestion() {
    if (_questionIndex == 0) return;
    setState(() {
      _questionIndex--;
    });
  }

  void _skipOrNextQuestion() {
    if (_questionIndex < _questions.length) {
      setState(() {
        _questionIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    globalScaffoldContext = context;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Online Examination',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: const Color(0xFF2D3142)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFF2D3142)),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(_secondsRemaining)} remaining',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF2D3142),
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFE63946)),
                  onPressed: _cancelExam,
                  tooltip: 'Cancel Exam',
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress: ${completionPercentage.toInt()}%',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: const Color(0xFF2D3142)),
                        ),
                        Text(
                          'Question $_displayQuestionNumber/${_questions.length}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: const Color(0xFF2D3142)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FAProgressBar(
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: Colors.grey[200] ?? Colors.grey.shade200,
                      progressColor: const Color(0xFF4D7CFE),
                      currentValue: completionPercentage,
                      animatedDuration: const Duration(milliseconds: 300),
                      maxValue: 100,
                    ),
                  ],
                )),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: questionWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget questionWidget() {
    if (_questionIndex < _questions.length) {
      final data = _questions[_questionIndex];
      return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 1),
              )
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4D7CFE).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Question ${_questionIndex + 1}",
                style: GoogleFonts.poppins(
                    color: const Color(0xFF4D7CFE),
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              data["question"].toString(),
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D3142),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: List.generate(5, (index) {
                String optionText = data['option${index + 1}'].toString();
                if (optionText == "null" || optionText.isEmpty) {
                  return const SizedBox.shrink();
                }
                final currentAnswer = _answers[_questionIndex];
                final bool isSelected = currentAnswer != null &&
                    currentAnswer['answerKey'] == 'option${index + 1}';
                return ChoiceButton(
                  index: index,
                  text: optionText,
                  isSelected: isSelected,
                  onPressed: () {
                    final examID = widget.examConfig['exam_id'];
                    final tutorialID = widget.examConfig['tutorial_id'];
                    final studentID = widget.examConfig['student_id'];
                    final questionID = data['id'];
                    final answerKey = 'option${index + 1}';
                    final answerValue = data['option${index + 1}'];
                    final answer = data['answer'];
                    _setAnswerForQuestion(_questionIndex, {
                      'exam_id': examID,
                      'tutorial_id': tutorialID,
                      'student_id': studentID,
                      'question_id': questionID,
                      'answerKey': answerKey,
                      'answerValue': answerValue,
                      'answer': answer
                    });
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (mounted && _questionIndex < _questions.length) {
                        setState(() {
                          _questionIndex++;
                        });
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_questionIndex > 0)
                  TextButton.icon(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: Color(0xFF8C8FA5)),
                    label: Text(
                      'Previous',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8C8FA5),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                TextButton.icon(
                  onPressed: _skipOrNextQuestion,
                  icon: Icon(
                    _answers[_questionIndex] != null
                        ? Icons.arrow_forward_rounded
                        : Icons.skip_next_rounded,
                    size: 18,
                    color: const Color(0xFF4D7CFE),
                  ),
                  label: Text(
                    _answers[_questionIndex] != null ? 'Next' : 'Skip',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4D7CFE),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    } else {
      return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 1),
              )
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/Images/exam_complete.gif",
              height: 180,
            ),
            const SizedBox(height: 20),
            Text(
              "Exam Completed",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You have completed the exam. Click below to submit and see your results.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF8C8FA5),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _examComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D7CFE),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(
                "SUBMIT FOR RESULTS",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _previousQuestion,
              icon: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: Color(0xFF8C8FA5)),
              label: Text(
                'Review Answers',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C8FA5),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  _examComplete() async {
    _examTimer?.cancel();
    int timeTaken = 300 - _secondsRemaining;
    showLoadingIndicator();

    final List<dynamic> finalAnswers = [];
    final examID = widget.examConfig['exam_id'];
    final tutorialID = widget.examConfig['tutorial_id'];
    final studentID = widget.examConfig['student_id'];

    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] != null) {
        finalAnswers.add(_answers[i]);
      } else {
        final question = _questions[i];
        finalAnswers.add({
          'exam_id': examID,
          'tutorial_id': tutorialID,
          'student_id': studentID,
          'question_id': question['id'],
          'answerKey': 'skipped',
          'answerValue': '',
          'answer': question['answer'] ?? ''
        });
      }
    }

    String jsonString = json.encode(finalAnswers);
    final response = await RestClient().authPost('/student/exam/finish', {
      'answers': jsonString,
    });

    if (response != null && response['status'] == "success") {
      hideLoadingIndicator();
      Analytics().logEvent("EXAM_COMPLETED", {
        "subject_name": widget.tutorial['subject_name'].toString(),
        "video": widget.tutorial['title'].toString(),
        "total_number": response['data']['total_number'].toString(),
        "passing_marks": response['data']['passing_marks'].toString(),
        "right_answers": response['data']['right_answers'].toString(),
        "wrong_answers": response['data']['wrong_answers'].toString(),
        "exam_status": response['data']['exam_status'].toString(),
      });
      finishExam(response['data'], timeTaken);
    } else {
      hideLoadingIndicator();
      final dummyResponse = {
        'total_number': _questions.length,
        'passing_marks': widget.examConfig['passing_marks'] ?? 50,
        'right_answers': finalAnswers.where((a) => a['answerKey'] != 'skipped' && a['answerValue'] == a['answer']).length,
        'wrong_answers': finalAnswers.where((a) => a['answerKey'] == 'skipped' || a['answerValue'] != a['answer']).length,
        'exam_status': (finalAnswers.where((a) => a['answerKey'] != 'skipped' && a['answerValue'] == a['answer']).length / _questions.length * 100) >= (widget.examConfig['passing_marks'] ?? 50) ? "Pass" : "Fail"
      };

      Analytics().logEvent("EXAM_COMPLETED_OFFLINE", {
        "subject_name": widget.tutorial['subject_name'].toString(),
        "video": widget.tutorial['title'].toString(),
        "total_number": dummyResponse['total_number'].toString(),
        "passing_marks": dummyResponse['passing_marks'].toString(),
        "right_answers": dummyResponse['right_answers'].toString(),
        "wrong_answers": dummyResponse['wrong_answers'].toString(),
        "exam_status": dummyResponse['exam_status'].toString(),
      });

      finishExam(dummyResponse, timeTaken);
    }
  }

  finishExam(response, int timeTaken) {
    // Navigate to ExamComplete without popping back to Subject
    // This keeps the video paused while viewing results
    // When user clicks "Continue Study", we'll pop back to Subject and resume video
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => ExamComplete(
                examStatus: response,
                timeTakenSeconds: timeTaken,
              )),
    );
  }

  void showLoadingIndicator() {
    globalScaffoldContext.loaderOverlay.show();
  }

  void hideLoadingIndicator() {
    globalScaffoldContext.loaderOverlay.hide();
  }

  void _cancelExam() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Cancel Exam?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
          content: Text(
            'Are you sure you want to cancel this exam? Your progress will not be saved.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8C8FA5),
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D7CFE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'CONTINUE EXAM',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit exam screen
              },
              child: Text(
                'YES, CANCEL',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE63946),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ChoiceButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final int index;
  final bool isSelected;

  const ChoiceButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.index,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final optionLabels = ['A', 'B', 'C', 'D', 'E'];

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF4D7CFE) : const Color(0xFFE8E9EC),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? const Color(0xFF4D7CFE).withValues(alpha: 0.05) : Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4D7CFE)
                      : const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    optionLabels[index],
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : const Color(0xFF4D7CFE),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: const Color(0xFF2D3142),
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
