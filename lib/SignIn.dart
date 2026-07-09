import 'package:flutter/material.dart';
import '../../Library/RestClient.dart';
import '../../Parent/ParentDashboard.dart';
import '../../Student/Dashboard.dart';
import '../../Signup.dart';
import '../../forgot.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'Service/Analytics.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'Library/StyleConfig.dart';
import 'Student/MainNav.dart';
import 'dart:io' show Platform;

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  bool _checkbox = false;
  String _email = "";
  String _password = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    navigateToDashboardIfLoggedIn();
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

    return Scaffold(
      body: SingleChildScrollView(
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
                        'Sign in to midigitalacademy'.toUpperCase(),
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
                    height: 40,
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
                        hintText: "Enter Your Email or ID",
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
                    height: 40,
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
                              'Forgot password',
                              style: TextStyle(),
                            )),
                      ],
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(left: 35, right: 35),
                    child: OutlinedButton(
                      onPressed: login,
                      style: StyleConfig.actionButtonStyle,
                      child: const Text("SIGN IN",
                          style: TextStyle(color: Colors.white)),
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

  Future<void> login() async {
    if (_email.isEmpty) {
      showErrorMessage("Please enter your email address or student ID.");
      return;
    } else if (_password.isEmpty) {
      showErrorMessage("Please enter your password.");
      return;
    }

    showLoadingIndicator();
    bool loginSuccess = false;

    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else {
        deviceId = 'unknown';
      }

      final response = await RestClient().guestPost('/sign-in', {
        'email': _email,
        'password': _password,
        'env': 'android',
        'device_id': deviceId
      });
      if (response["status"] == 'success') {
        loginSuccess = true;
        final role = response["data"]["role"].toString();
        final token = response["data"]["api_token"].toString();
        final email = response["data"]["email"].toString();
        final userId = response["data"]["user_id"].toString();
        // store the user information
        await RestClient().storeUser(email, userId, token, role);
        await Analytics().logEvent('login', {});
        showLoadingIndicator(message: "Loading next page...");
        navigateToDashboard(role);
      } else {
        // Login failed, show error message
        String errorMessage = response["data"].toString();
        // Make server error messages more user-friendly
        if (errorMessage.toLowerCase().contains('invalid username password')) {
          errorMessage =
              'The email/ID or password you entered is incorrect. Please try again.';
        }
        showErrorMessage(errorMessage);
      }
    } catch (e) {
      // Handle any errors during login
      showErrorMessage(
          "We encountered an issue while signing you in. Please check your internet connection and try again.");
    } finally {
      if (!loginSuccess) {
        hideLoadingIndicator();
      }
    }
  }

  void showErrorMessage(String message) {
    if (Platform.isWindows) {
      // Show dialog on Windows since Fluttertoast doesn't support it
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 10),
                const Text('Authentication Error'),
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
    }
  }
}
