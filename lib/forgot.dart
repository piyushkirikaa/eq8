import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'Library/RestClient.dart';
import 'Library/StyleConfig.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'SignIn.dart';
import 'Library/BouncingScrollIndicator.dart';

class forgot extends StatefulWidget {
  const forgot({super.key});

  @override
  State<forgot> createState() => _forgotState();
}

class _forgotState extends State<forgot> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _imageOpacity = 0.0;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollHint = true;
  final GlobalKey _cancelButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _imageOpacity = 1.0;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool isIpadLandscape = Platform.isIOS &&
        MediaQuery.of(context).size.shortestSide >= 600 &&
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (!isIpadLandscape) return;

    final btnContext = _cancelButtonKey.currentContext;
    if (btnContext == null) return;
    final renderBox = btnContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // The button is fully visible if its bottom edge is above the screen bottom edge
    final isFullyVisible = (position.dy + size.height) <= screenHeight;

    if (isFullyVisible && _showScrollHint) {
      setState(() {
        _showScrollHint = false;
      });
    } else if (!isFullyVisible && !_showScrollHint) {
      setState(() {
        _showScrollHint = true;
      });
    }
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Send password reset link
  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    showLoadingIndicator(message: "Please wait...");

    try {
      final response = await RestClient().guestPost(
        '/forgot-password',
        {'email': _emailController.text.trim()},
      ).timeout(const Duration(seconds: 25));

      if (!mounted) return;

      hideLoadingIndicator();

      if (response != null && response["status"] == 'success') {
        showSuccessMessage(
            "Email sent successfully with password reset information.");
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignIn()),
            );
          }
        });
      } else {
        if (response != null && response["message"] == "User not found") {
          showErrorMessage(
              "No Such User Linked Email Id. Check Email Id and try again.");
        } else {
          final errorMessage = response?["message"] ??
              'Failed to send reset link. Please try again.';
          showErrorMessage(errorMessage);
        }
      }
    } on TimeoutException {
      if (!mounted) return;

      hideLoadingIndicator();
      showErrorMessage(
          'Password reset is taking too long. Please check your connection and try again.');
    } catch (e) {
      if (!mounted) return;

      hideLoadingIndicator();
      showErrorMessage('Network error. Please check your connection.');
    }
  }

  void showErrorMessage(String message) {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Show dialog on desktop where Fluttertoast can be unreliable.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 10),
                const Text('Error'),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 15),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
          );
        },
      );
    } else {
      // Use toast for Android/iOS
      RestClient().error(message);
    }
  }

  void showSuccessMessage(String message) {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green[700]),
                const SizedBox(width: 10),
                const Text('Success'),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 15),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
          );
        },
      );
    } else {
      RestClient().success(message);
    }
  }

  void showLoadingIndicator({String? message}) {
    context.loaderOverlay.show(progress: message ?? "Please wait...");
  }

  void hideLoadingIndicator() {
    context.loaderOverlay.hide();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    final bool isIpadLandscape = Platform.isIOS &&
        MediaQuery.of(context).size.shortestSide >= 600 &&
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                logo(width),
                Container(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        SizedBox(
                          height: 60,
                          width: width,
                          child: Center(
                            child: Text(
                              'Forgot Password?'.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
    
                        // Subtitle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Enter your email address and we\'ll send you a link to reset your password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
    
                        // Email Input Field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextFormField(
                            controller: _emailController,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 22.5, horizontal: 15),
                              prefixIcon: const Icon(Icons.email_outlined),
                              hintText: "Enter your email address",
                              hintStyle: const TextStyle(),
                              filled: true,
                              focusColor: Colors.blueAccent,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: const BorderSide(width: 1),
                              ),
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: const BorderSide(
                                    width: 1, style: BorderStyle.solid),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide:
                                    BorderSide(color: Colors.red[400]!, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide:
                                    BorderSide(color: Colors.red[600]!, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
    
                        // Send Reset Link Button
                        Container(
                          width: width,
                          margin: const EdgeInsets.only(left: 35, right: 35),
                          child: OutlinedButton(
                            onPressed: _sendResetLink,
                            style: StyleConfig.actionButtonStyle,
                            child: const Text(
                              "SEND RESET LINK",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
    
                        // Cancel Request Button
                        Container(
                          key: _cancelButtonKey,
                          width: width,
                          margin: const EdgeInsets.only(left: 35, right: 35),
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignIn()),
                              );
                            },
                            style: StyleConfig.actionButtonStyle,
                            child: const Text(
                              "CANCEL REQUEST",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
    
                        // Back to Sign In
                        SizedBox(
                          height: 40,
                          width: width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Remember your password? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const SignIn()),
                                  );
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            right: 40,
            child: AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: (isIpadLandscape && _showScrollHint) ? 1.0 : 0.0,
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !(isIpadLandscape && _showScrollHint),
                child: const BouncingScrollIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget logo(width) {
    if (Platform.isWindows) {
      return Container(
        margin: const EdgeInsets.only(top: 50, bottom: 20),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: hexToColor("#0c132f"),
          border: Border.all(
            color: Colors.white,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        width: 150,
        child: Image.asset(
          'assets/Images/logo.png',
          fit: BoxFit.fill,
        ),
      );
    } else if (Platform.isMacOS) {
      // Undo the change to macOS immediately, using the original contain behavior
      final screenHeight = MediaQuery.of(context).size.height;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.42),
        child: SizedBox(
          width: width,
          child: AnimatedOpacity(
            opacity: _imageOpacity,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            child: Image.asset(
              'assets/Images/BG/bg_login.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    } else {
      // Mobile & Tablet (iOS & Android)
      return SizedBox(
        width: width,
        height:
            width, // Perfect square container (no cropping, no gaps on top or sides)
        child: AnimatedOpacity(
          opacity: _imageOpacity,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
          child: Image.asset(
            'assets/Images/BG/bg_login.png',
            fit: BoxFit.fitWidth,
          ),
        ),
      );
    }
  }

  Color hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }
}
