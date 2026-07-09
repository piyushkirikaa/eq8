import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'Library/RestClient.dart';
import 'Library/StyleConfig.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'SignIn.dart';

class forgot extends StatefulWidget {
  const forgot({super.key});

  @override
  State<forgot> createState() => _forgotState();
}

class _forgotState extends State<forgot> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
      );

      if (!mounted) return;

      hideLoadingIndicator();

      if (response != null &&
          (response["status"] == 'success' ||
           response["message"] == 'Email send failed')) {
        RestClient().success("Email sent Successfully with Password Reset Information.");
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
          RestClient().error("No Such User Linked Email Id. Check Email Id and try again.");
        } else {
          final errorMessage = response?["message"] ??
              'Failed to send reset link. Please try again.';
          RestClient().error(errorMessage);
        }
      }
    } catch (e) {
      if (!mounted) return;

      hideLoadingIndicator();
      RestClient().error('Network error. Please check your connection.');
    }
  }

  void showErrorMessage(String message) {
    if (Platform.isWindows) {
      // Show dialog on Windows since Fluttertoast doesn't support it
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

  void showLoadingIndicator({String? message}) {
    context.loaderOverlay.show(progress: message ?? "Please wait...");
  }

  void hideLoadingIndicator() {
    context.loaderOverlay.hide();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
    } else {
      return SizedBox(
        width: width,
        child: Image.asset(
          'assets/Images/BG/bg_login.png',
          fit: BoxFit.fill,
        ),
      );
    }
  }

  Color hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }
}
