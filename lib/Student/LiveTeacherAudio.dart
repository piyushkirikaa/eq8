// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../Library/RestClient.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;

// Theme constants for consistent styling
class TeacherTheme {
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color secondaryColor = Color(0xFF5F6368);
  static const Color accentColor = Color(0xFF4285F4);
  static const Color userBubbleColor = Color(0xFFE8F5FE);
  static const Color botBubbleColor = Color(0xFFF8F9FA);
  static const Color backgroundColor = Color(0xFFFAFAFA);

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const TextStyle appBarTextStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle messageTextStyle = TextStyle(
    fontSize: 16,
    color: Color(0xFF202124),
  );

  static BoxDecoration bubbleDecoration(bool isUserMessage) => BoxDecoration(
        color: isUserMessage ? userBubbleColor : botBubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isUserMessage
              ? const Radius.circular(16)
              : const Radius.circular(4),
          bottomRight: isUserMessage
              ? const Radius.circular(4)
              : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      );
}

class LiveTeacherAudio extends StatefulWidget {
  const LiveTeacherAudio({super.key});

  @override
  State<LiveTeacherAudio> createState() => _LiveTeacherAudioState();
}

class _LiveTeacherAudioState extends State<LiveTeacherAudio>
    with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  late final OpenAI _openAI;

  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;

  bool _isListening = false;
  String _text = "";
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeChatGPT();
    _initializeAnimations();
    _initializeTTS();

    // Add a welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add({
          "sender": "bot",
          "text":
              "Hello! I'm Genius, your digital teacher assistant. How can I help you today?"
        });
      });
    });
  }

  void _initializeAnimations() {
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Fix: Use a different curve that works within the valid range
    _micAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _micAnimationController,
        curve: Curves
            .easeIn, // Changed from Curves.easeInOut to fix the assert error
      ),
    );

    _micAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _micAnimationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_isListening) {
          _micAnimationController.forward();
        }
      }
    });
  }

  void _initializeTTS() {
    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _initializeChatGPT() async {
    _openAI = OpenAI.instance.build(
      token: const String.fromEnvironment('OPENAI_API_KEY', defaultValue: ''),
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)),
    );
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'notListening' && _isListening) {
            // Restart listening after a pause
            _speech.stop();
            _listen();
          }
        },
        onError: (val) {
          print('onError: $val');
          setState(() => _isListening = false);
          _micAnimationController.stop();
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _micAnimationController.forward();
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.finalResult) {
              if (_text.isNotEmpty) {
                _addMessage("user", _text);
                _sendTextToChatGPT(_text);
              }
              _text = ''; // Reset the text
            }
          }),
          listenMode: stt.ListenMode.dictation,
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
        );
      }
    } else {
      setState(() => _isListening = false);
      _micAnimationController.stop();
      _speech.stop();
    }
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _addMessage("user", text);
      _sendTextToChatGPT(text);
      _textController.clear();
    }
  }

  void _addMessage(String sender, String text, {String? imageUrl}) {
    setState(() {
      final message = {"sender": sender, "text": text};
      if (imageUrl != null) {
        message["imageUrl"] = imageUrl;
      }
      _messages.add(message);

      if (sender == "bot") {
        _isTyping = false;
      }
    });

    // Scroll to the bottom after adding a message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendTextToChatGPT(String query) async {
    setState(() => _isTyping = true);

    try {
      final request = ChatCompleteText(
        messages: [
          Messages(
                  role: Role.system,
                  content:
                      "You are a Teacher from my digital college. Your name is Genius. Your Job is to help students")
              .toJson(),
          Messages(role: Role.user, content: query).toJson(),
        ],
        maxToken: 150,
        model: Gpt4ChatModel(),
      );
      final response = await _openAI.onChatCompletion(request: request);
      final responseText =
          response?.choices.first.message?.content.trim() ?? "No response";

      _addMessage("bot", responseText);
      _speak(responseText);
    } catch (e) {
      setState(() => _isTyping = false);
      if (mounted) {
        RestClient().error('Error: Unable to get response. Please try again.');
      }

      // Handle the error
      debugPrint("error: $e");
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  Future<void> _pickImageWithQuery(String query) async {
    setState(() => _isTyping = true);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: TeacherTheme.primaryColor),
                title: const Text('Photo Library'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.gallery, query);
                },
              ),
              // Camera option only for Android and iOS, not for macOS
              if (!Platform.isMacOS)
                ListTile(
                  leading: const Icon(Icons.camera_alt,
                      color: TeacherTheme.primaryColor),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.camera, query);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source, String query) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      final File imageFile = File(image.path);

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: TeacherTheme.primaryColor),
                    SizedBox(width: 20),
                    Text("Processing image..."),
                  ],
                ),
              ),
            );
          },
        );
      }

      // Step 1: Upload the image to your Laravel server and get the URL
      String? imageUrl = await _uploadImageAndGetUrl(imageFile);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (imageUrl != null) {
        _addMessage("user", query, imageUrl: imageUrl);

        // Step 2: Construct the message with text and image URL content
        final messages = [
          {
            "role": "system",
            "content": formatLaTeX("""
                      You are a Teacher from My Digital College on the South African CAPS (Curriculum and Assessment Policy Statement). Your name is Genius. Format responses using markdown for text and specific placeholders for LaTeX expressions:
                      - If a topic is not part of the CAPS curriculum, politely say: “This topic is not covered in your CAPS curriculum.”
                      - Inline LaTeX Use : `{latex} ... {latex}`
                      - Block LaTeX Use : `{latex-block} ... {latex-block}`
                      Avoid using dollar signs (`{latex}`) in LaTeX expressions.
                    """)
          },
          {
            "role": "user",
            "content": [
              {"type": "text", "text": query},
              {
                "type": "image_url",
                "image_url": {"url": imageUrl}
              }
            ]
          }
        ];

        try {
          // Step 3: Make the API call to ChatGPT
          final response = await http.post(
            Uri.parse("https://api.openai.com/v1/chat/completions"),
            headers: {
              "Content-Type": "application/json",
              "Authorization":
                  "Bearer OPENAI_API_KEY_PLACEHOLDER",
            },
            body: jsonEncode({"model": "gpt-4o-mini", "messages": messages}),
          );

          // Step 4: Process the response
          if (response.statusCode == 200) {
            final responseBody = jsonDecode(response.body);
            final botMessage = responseBody['choices'][0]['message']
                    ['content'] ??
                "No response";
            _addMessage("bot", botMessage.trim());
            _speak(botMessage.trim());
          } else {
            throw Exception("API Error: ${response.statusCode}");
          }
        } catch (e) {
          setState(() => _isTyping = false);
          if (mounted) {
            RestClient().error('Error processing image: ${e.toString()}');
          }
        }
      } else {
        setState(() => _isTyping = false);
        // Handle error if image upload failed
        if (mounted) {
          RestClient().error("Failed to upload image. Please try again.");
        }
      }
    } else {
      setState(() => _isTyping = false);
    }
  }

  String formatLaTeX(String text) {
    return text.replaceAll('{latex}', r'$').replaceAll('{latex-block}', r'$$');
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    _textController.dispose();
    _scrollController.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    if (_isListening) {
      _speech.stop();
      _micAnimationController.stop();
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(),
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Hero(
            tag: 'teacher_avatar',
            child: CircleAvatar(
              radius: 30.0,
              backgroundImage: AssetImage('assets/Images/teacher.png'),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        title: const Text(
          "Genius - Live Teacher",
          style: TeacherTheme.appBarTextStyle,
        ),
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(
                Icons.stop_circle,
                color: Colors.redAccent,
              ),
              tooltip: 'Stop speaking',
              onPressed: _stopSpeaking,
            ),
          AnimatedBuilder(
            animation: _micAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _micAnimation.value : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: _isListening
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        )
                      : null,
                  child: IconButton(
                    icon: Icon(
                      _isListening
                          ? CupertinoIcons.mic_fill
                          : CupertinoIcons.mic_circle,
                      color: _isListening ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: _listen,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Typing indicator when bot is processing
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isTyping ? 40 : 0,
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _isTyping
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  TeacherTheme.primaryColor),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Genius is typing...',
                            style: TextStyle(
                              color: TeacherTheme.secondaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),

              // Messages List
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              _messages[_messages.length - 1 - index];
                          final isUserMessage = message['sender'] == 'user';
                          return _buildMessageBubble(message, isUserMessage);
                        },
                      ),
              ),

              // Speech recognition indicator
              if (_isListening && _text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mic,
                        color: TeacherTheme.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _text,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Input Area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.grey.shade100,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _textController,
                                  maxLines: 5,
                                  minLines: 1,
                                  keyboardType: TextInputType.multiline,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: "Ask Genius a question...",
                                    hintStyle:
                                        TextStyle(color: Colors.grey.shade500),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: kIsWeb ||
                                    (!Platform.isMacOS &&
                                        defaultTargetPlatform !=
                                            TargetPlatform.macOS),
                                child: IconButton(
                                  icon: const Icon(Icons.attach_file),
                                  color: TeacherTheme.secondaryColor,
                                  onPressed: () => _pickImageWithQuery(
                                      _textController.text.trim()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _sendText,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                TeacherTheme.primaryColor,
                                TeacherTheme.accentColor
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 3D icon in top right corner
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_rounded,
            size: 80,
            color: TeacherTheme.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "Welcome to Live Teacher",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: TeacherTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Ask any question to Genius, your digital teacher assistant",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.mic),
            label: const Text("Start Speaking"),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _listen,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUserMessage) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: TeacherTheme.bubbleDecoration(isUserMessage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the sender info
            if (!isUserMessage)
              const Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: AssetImage('assets/Images/teacher.png'),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Genius',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: TeacherTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

            // Display the image if `imageUrl` exists
            if (message.containsKey('imageUrl') && message['imageUrl'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message['imageUrl'],
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        color: Colors.grey.shade200,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Failed to load image',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                TeacherTheme.primaryColor),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Display the processed markdown with LaTeX
            if (message.containsKey('text') && message['text'] != null)
              MarkdownBody(
                selectable: true,
                data: message['text'],
                styleSheet: MarkdownStyleSheet(
                  p: TeacherTheme.messageTextStyle,
                  h1: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: TeacherTheme.primaryColor),
                  h2: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TeacherTheme.primaryColor),
                  h3: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: TeacherTheme.primaryColor),
                  code: TextStyle(
                      backgroundColor: Colors.grey.shade100,
                      fontFamily: 'monospace'),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                builders: {
                  'latex': LatexElementBuilder() as dynamic,
                },
                extensionSet: md.ExtensionSet(
                  [LatexBlockSyntax()],
                  [LatexInlineSyntax()],
                ),
              ),

            // Timestamp (optional)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'now',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImageAndGetUrl(File imageFile) async {
    final uri =
        Uri.parse("https://www.midigitalacademy.com/crm/api/upload_temp_image");
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        final data = jsonDecode(res.body);
        return data['url']; // Return the image URL
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
