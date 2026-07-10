// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

// Theme constants for sci-fi styling
class SciFiTheme {
  static const Color primaryColor = Color(0xFF00BCD4);
  static const Color secondaryColor = Color(0xFF80DEEA);
  static const Color accentColor = Color(0xFF18FFFF);
  static const Color backgroundColor = Color(0xFF0A0E21);
  static const Color cardColor = Color(0xFF1D1E33);

  static const LinearGradient messageGradient = LinearGradient(
    colors: [Color(0xFF00BCD4), Color(0xFF006064)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const TextStyle messageTextStyle = TextStyle(
    fontSize: 20,
    color: Colors.white,
    letterSpacing: 0.8,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  static BoxDecoration messageDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: primaryColor.withValues(alpha: 0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.2),
        spreadRadius: 2,
        blurRadius: 15,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

class VoiceAssistant extends StatefulWidget {
  const VoiceAssistant({super.key});

  @override
  State<VoiceAssistant> createState() => _VoiceAssistantState();
}

class _VoiceAssistantState extends State<VoiceAssistant>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  late final OpenAI _openAI;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  // Voice assistant state
  bool _isListening = false;
  String _text = "";
  String _lastAiMessage =
      "Hello! I am your AI voice assistant. How can I help you today?";
  bool _isProcessing = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeChatGPT();

    // Delay speech initialization to prevent UI freeze
    Future.delayed(const Duration(milliseconds: 500), () {
      _startHandsFreeMode();
    });
  }

  void _initAnimations() {
    // Use simpler animations to prevent overload
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Start animations but with lower frame rate
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  Future<void> _initializeChatGPT() async {
    _openAI = OpenAI.instance.build(
      token:
          "OPENAI_API_KEY_PLACEHOLDER",
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)),
    );
  }

  Future<void> _startHandsFreeMode() async {
    if (_speech.isAvailable) {
      _stopListening();
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint("Speech status: $status");
        if (status == 'done' || status == 'notListening') {
          // Add delay before restarting to prevent rapid cycling
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && !_isProcessing) {
              _startListening();
            }
          });
        }
      },
      onError: (error) {
        debugPrint('Speech error: $error');
        // Recover from error by restarting after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isProcessing) {
            _startListening();
          }
        });
      },
    );

    if (available) {
      _startListening();
    } else {
      debugPrint("Speech recognition not available");
    }
  }

  Future<void> _startListening() async {
    if (_isProcessing) return;

    try {
      if (!_isListening) {
        setState(() => _isListening = true);

        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _text = result.recognizedWords;

                // Process only after receiving final result and not empty
                if (result.finalResult && _text.isNotEmpty) {
                  _isProcessing = true;
                  _handleCommand(_text);
                  _text = '';
                }
              });
            }
          },
          listenMode: stt.ListenMode.confirmation,
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          listenFor: const Duration(seconds: 10),
          cancelOnError: false,
        );
      }
    } catch (e) {
      debugPrint("Error starting listening: $e");
      _isListening = false;

      // Try to recover after delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _startHandsFreeMode();
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _handleCommand(String command) async {
    try {
      await _sendTextToChatGPT(command);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }

      // Restart listening after processing
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !_isProcessing) {
          _startListening();
        }
      });
    }
  }

  Future<void> _sendTextToChatGPT(String query) async {
    try {
      final request = ChatCompleteText(
        messages: [
          Messages(
                  role: Role.system,
                  content:
                      "You are an advanced AI assistant. Be concise and helpful. Keep answers under 3 sentences.")
              .toJson(),
          Messages(role: Role.user, content: query).toJson(),
        ],
        maxToken: 100,
        model: Gpt4ChatModel(),
      );

      final response = await _openAI.onChatCompletion(request: request);
      final responseText = response?.choices.first.message?.content.trim() ??
          "I didn't understand that. Could you try again?";

      if (mounted) {
        setState(() {
          _lastAiMessage = responseText;
          _isAnimating = true;
        });
      }

      await _speak(responseText);

      if (mounted) {
        setState(() => _isAnimating = false);
      }
    } catch (e) {
      debugPrint("ChatGPT error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Connection error. Please try again.')));
      }
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS error: $e");
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SciFiTheme.backgroundColor,
      body: Stack(
        children: [
          // Simple animated background (more efficient)
          CustomPaint(
            painter: SimpleGridPainter(),
            size: Size.infinite,
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildAiMessage(),
                ),
                _buildVoiceIndicator(),
              ],
            ),
          ),

          // Visualization overlay when speaking
          if (_isListening)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SimplePulsePainter(
                    animation: _pulseAnimation,
                    color: SciFiTheme.accentColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SciFiTheme.messageGradient,
            ),
            child: const Icon(
              Icons.psychology_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'AI Assistant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: SciFiTheme.messageDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use conditional for better performance
            _isAnimating
                ? AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        _lastAiMessage,
                        textStyle: SciFiTheme.messageTextStyle,
                        speed: const Duration(milliseconds: 40),
                      ),
                    ],
                    totalRepeatCount: 1,
                    displayFullTextOnTap: true,
                  )
                : Text(
                    _lastAiMessage,
                    style: SciFiTheme.messageTextStyle,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: SciFiTheme.cardColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: SciFiTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SciFiTheme.messageGradient,
              boxShadow: [
                BoxShadow(
                  color: SciFiTheme.accentColor
                      .withValues(alpha: _isListening ? 0.4 : 0.1),
                  spreadRadius: _isListening ? 4 : 1,
                  blurRadius: _isListening ? 12 : 5,
                ),
              ],
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

// Simplified painters for better performance
class SimpleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SciFiTheme.primaryColor.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    // Draw fewer lines for better performance
    const spacing = 50.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0.0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0.0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SimpleGridPainter oldDelegate) => false;
}

class SimplePulsePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  SimplePulsePainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 3;

    // Draw just one circle for better performance
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, maxRadius * animation.value, paint);
  }

  @override
  bool shouldRepaint(SimplePulsePainter oldDelegate) => true;
}
