import 'package:flutter/material.dart';
import '../../Library/RestClient.dart';
import '../../Parent/ParentDashboard.dart';
import '../../forgot.dart';
import 'dart:async';
import 'package:loader_overlay/loader_overlay.dart';
import 'Service/Analytics.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'Library/StyleConfig.dart';
import 'Student/MainNav.dart';
import 'dart:io' show Platform;
import 'Library/BouncingScrollIndicator.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  bool _checkbox = false;
  String _email = "";
  String _password = "";
  double _imageOpacity = 0.0;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollHint = true;
  final GlobalKey _signInButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    navigateToDashboardIfLoggedIn();
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
    super.dispose();
  }

  void _onScroll() {
    final bool isIpadLandscape = Platform.isIOS &&
        MediaQuery.of(context).size.shortestSide >= 600 &&
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (!isIpadLandscape) return;

    final btnContext = _signInButtonKey.currentContext;
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    final outlineInputBorderStyle = OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(width: 1));

    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(width: 1, style: BorderStyle.solid),
    );

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 50,
                        width: width,
                        child: Center(
                          child: Text(
                            'Sign in to mi digital academy'.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        height: 65,
                        width: width,
                        margin: const EdgeInsets.only(left: 15, right: 15),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _email = value;
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(0),
                            prefixIcon: const Icon(Icons.email_outlined),
                            hintText: "Enter your Username",
                            hintStyle: const TextStyle(),
                            filled: true,
                            focusColor: Colors.blueAccent,
                            enabledBorder: outlineInputBorderStyle,
                            fillColor: Colors.white,
                            border: borderStyle,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      Container(
                        height: 20,
                      ),
                      Container(
                        height: 65,
                        width: width,
                        margin: const EdgeInsets.only(left: 15, right: 15),
                        child: TextField(
                          obscureText: true,
                          onChanged: (value) {
                            setState(() {
                              _password = value;
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(0),
                            prefixIcon: const Icon(Icons.password_outlined),
                            hintText: "Password",
                            hintStyle: const TextStyle(),
                            filled: true,
                            focusColor: Colors.blueAccent,
                            enabledBorder: outlineInputBorderStyle,
                            fillColor: Colors.white,
                            border: borderStyle,
                          ),
                          keyboardType: TextInputType.visiblePassword,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 5, right: 15, top: 1),
                        height: 60,
                        width: width,
                        child: Row(
                          children: [
                            Checkbox(
                              value: _checkbox,
                              onChanged: (value) {
                                setState(() {
                                  _checkbox = value!;
                                });
                              },
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(),
                            ),
                            const Spacer(),
                            GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const forgot()),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(),
                                )),
                          ],
                        ),
                      ),
                      Container(
                        key: _signInButtonKey,
                        height: 67.5,
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(left: 35, right: 35),
                        child: OutlinedButton(
                          onPressed: login,
                          style: StyleConfig.actionButtonStyle,
                          child: const Text("SIGN IN",
                              style: TextStyle(color: Colors.white, fontSize: 22.5)),
                        ),
                      ),
                      // SizedBox(
                      //   height: 60,
                      //   width: 340,
                      //   child:Row(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     crossAxisAlignment: CrossAxisAlignment.center,
                      //     children: [
                      //       const Text(
                      //         "Don't have an account?",
                      //         style: TextStyle(
                      //
                      //         ),
                      //       ),
                      //       GestureDetector(
                      //         onTap: (){
                      //           Navigator.push(
                      //             context,
                      //             MaterialPageRoute(builder: (context) => const SignUp()),
                      //           );
                      //         },
                      //         child: const Text('SIGN UP',style: TextStyle(
                      //             decoration: TextDecoration.underline
                      //         )),
                      //       ),
                      //     ],
                      //   ) ,
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 50)
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
            borderRadius: const BorderRadius.all(Radius.circular(20))),
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

  String get _apiEnv {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  Future<String> _deviceId() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return androidInfo.id;
      }
      if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios';
      }
    } catch (e) {
      debugPrint('Unable to read device id: $e');
    }
    return 'unknown';
  }

  Future<void> login() async {
    if (_email.isEmpty) {
      showErrorMessage("Enter your Username");
      return;
    } else if (_password.isEmpty) {
      showErrorMessage("Please enter your password.");
      return;
    }

    showLoadingIndicator();
    bool loginSuccess = false;

    try {
      final deviceId = await _deviceId();

      final response = await RestClient().guestPost('/sign-in', {
        'email': _email,
        'password': _password,
        'env': _apiEnv,
        'device_id': deviceId
      }).timeout(const Duration(seconds: 25));
      if (!mounted) return;

      print(response);

      if (response != null && response["status"] == 'success') {
        loginSuccess = true;
        final role = response["data"]["role"].toString();
        final token = response["data"]["api_token"].toString();
        final email = response["data"]["email"].toString();
        final userId = response["data"]["user_id"].toString();
        // store the user information
        await RestClient().storeUser(email, userId, token, role);
        unawaited(Analytics()
            .logEvent('login', {})
            .timeout(const Duration(seconds: 5))
            .catchError((_) {}));
        showLoadingIndicator(message: "Loading next page...");
        navigateToDashboard(role);
      } else {
        // Login failed, show error message
        debugPrint('Sign-in rejected: $response');

        String? messageStr = response?["message"]?.toString();
        String? dataStr = response?["data"]?.toString();

        String errorMessage = messageStr ??
            dataStr ??
            'Sign in failed. Please check your details and try again.';

        // Make server error messages more user-friendly
        if ((messageStr != null &&
                messageStr
                    .toLowerCase()
                    .contains('invalid username password')) ||
            (dataStr != null &&
                dataStr.toLowerCase().contains('invalid username password'))) {
          errorMessage =
              'Oops! We couldn\'t Sign You In. please check your Username or Password.';
        }
        showErrorMessage(errorMessage);
      }
    } on TimeoutException {
      showErrorMessage(
          "Signing in is taking too long. Please check your connection and try again.");
    } catch (e) {
      // Handle any errors during login
      debugPrint('Sign-in failed: $e');
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        showErrorMessage("Sign in failed: $e");
      } else {
        showErrorMessage("Sign in failed. Please try again.");
      }
    } finally {
      if (!loginSuccess) {
        hideLoadingIndicator();
      }
    }
  }

  void showErrorMessage(String message) {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Show dialog on desktop where Fluttertoast can be unreliable.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message ==
                            'Oops! We couldn\'t Sign You In. please check your Username or Password.'
                        ? 'Sign In Failed'
                        : 'Authentication Error',
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue[700],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      // Use toast for Android/iOS
      RestClient().error(message);
    }
  }

  void showLoadingIndicator({String? message}) {
    context.loaderOverlay.show(progress: message ?? "Signing in...");
  }

  void hideLoadingIndicator() {
    context.loaderOverlay.hide();
  }

  void navigateToDashboard(role) {
    if (role == "student") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNav()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ParentDashboard()),
      );
    }
  }

  void navigateToDashboardIfLoggedIn() async {
    final token = await RestClient().getCurrentToken();
    final role = await RestClient().getRole();
    if (token != null) {
      navigateToDashboard(role);
    } else {
      if (mounted) {
        context.loaderOverlay.hide();
      }
    }
  }
}
