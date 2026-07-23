import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';


class RestClient {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final String baseUrl = "https://www.mydigitalcollege.co.za/crm/api";
  static DateTime? _lastOfflineToastTime;

  guestPost(endpoint, param) async {
    try {
      var headers = {'Accept': 'application/json'};
      var request =
          http.MultipartRequest('POST', Uri.parse("$baseUrl$endpoint"));
      request.fields.addAll(param);
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        debugPrint(responseBody);
        try {
          return jsonDecode(responseBody);
        } catch (e) {
          debugPrint('Invalid JSON response: $e');
          return {
            'status': 'error',
            'message': 'The server returned an invalid response.',
            'data': 'The server returned an invalid response.'
          };
        }
      }
      debugPrint(response.reasonPhrase);
      return {
        'status': 'error',
        'message': response.reasonPhrase ?? 'Request failed',
        'data': responseBody,
      };
    } catch (e) {
      debugPrint('guestPost connection error: $e');
      final isConnected = await checkInternetConnection();
      if (!isConnected) {
        return {
          'status': 'error',
          'message': 'Please connect to the internet to continue learning.',
          'data': 'Please connect to the internet to continue learning.'
        };
      }
      return {
        'status': 'error',
        'message': 'Network error. Please try again',
        'data': 'Network error. Please try again'
      };
    }
  }

  guestGet(endpoint, param) async {
    var headers = {'Accept': 'application/json'};
    var request = http.MultipartRequest('GET', Uri.parse("$baseUrl$endpoint"));
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return jsonDecode(responseBody);
    } else {
      debugPrint(response.reasonPhrase);
    }
  }

  authPost(endpoint, param) async {
    try {
      final token = await getCurrentToken();
      var headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      };
      var request =
          http.MultipartRequest('POST', Uri.parse("$baseUrl$endpoint"));
      request.fields.addAll(param);
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        debugPrint(response.reasonPhrase);
        return {
          'status': 'error',
          'message': response.reasonPhrase ?? 'Request failed',
          'data': responseBody
        };
      }
    } catch (e) {
      debugPrint('authPost connection error: $e');
      final isConnected = await checkInternetConnection();
      if (!isConnected) {
        return {
          'status': 'error',
          'message': 'Please connect to the internet to continue learning.',
          'data': 'Please connect to the internet to continue learning.'
        };
      }
      return {
        'status': 'error',
        'message': 'Network error. Please try again',
        'data': 'Network error. Please try again'
      };
    }
  }

  Future authGet(String endpoint, dynamic param) async {
    final token = await getCurrentToken();
    var headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    // Check if there's an internet connection
    var isConnected = await checkInternetConnection();
    if (isConnected) {
      // If there's an internet connection, send a live request
      try {
        var response = await sendLiveRequest(endpoint, headers);
        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();

          // Cache the response
          await cacheResponse(endpoint, responseBody);

          // Validate JSON before parsing
          if (responseBody.trim().startsWith('{') ||
              responseBody.trim().startsWith('[')) {
            try {
              return jsonDecode(responseBody);
            } catch (e) {
              debugPrint('JSON decode error: $e');
              return null;
            }
          } else {
            debugPrint('Response is not valid JSON (likely HTML error page)');
            return null;
          }
        } else {
          debugPrint(
              'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Request failed'}');
          return null;
        }
      } catch (e) {
        debugPrint('Network request error: $e');
        // Fallback to cached data if available
        final cachedData = await getCachedResponse(endpoint);
        if (cachedData != null) {
          try {
            return jsonDecode(cachedData);
          } catch (e) {
            debugPrint('Cached JSON decode error: $e');
            return null;
          }
        }
        return null;
      }
    } else {
      // If there's no internet connection, try to access cached data
      final cachedData = await getCachedResponse(endpoint);
      if (cachedData != null) {
        try {
          return jsonDecode(cachedData);
        } catch (e) {
          debugPrint('Cached JSON decode error: $e');
          return null;
        }
      } else {
        debugPrint('No cached data available');
        return null;
      }
    }
  }

  // Function to send a live request
  Future<http.StreamedResponse> sendLiveRequest(
      String endpoint, Map<String, String> headers) async {
    var request = http.MultipartRequest('GET', Uri.parse("$baseUrl$endpoint"));
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    return response;
  }

  // Function to cache the response
  Future<void> cacheResponse(String endpoint, String responseBody) async {
    try {
      await DefaultCacheManager().putFile(
          "$baseUrl$endpoint", Uint8List.fromList(utf8.encode(responseBody)));
      debugPrint('Response cached successfully for $endpoint');
    } catch (e) {
      debugPrint('Error caching response: $e');
    }
  }

  // Function to get cached response
  Future<String?> getCachedResponse(String endpoint) async {
    try {
      final file =
          await DefaultCacheManager().getSingleFile("$baseUrl$endpoint");
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('Error reading cached data: $e');
    }
    return null;
  }

  // Function to check internet connection
  Future<bool> checkInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult =
          await (Connectivity().checkConnectivity());

      // Check for any type of connection (mobile, wifi, ethernet, etc.)
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet) ||
          connectivityResult.contains(ConnectivityResult.other)) {
        // Additional check: Try to make a simple HTTP request to verify actual internet access
        try {
          final response = await http.get(
            Uri.parse('https://www.google.com'),
            headers: {'Accept': 'text/html'},
          ).timeout(const Duration(seconds: 5));

          return response.statusCode == 200;
        } catch (e) {
          debugPrint('Internet connectivity test failed: $e');
          // If the connectivity test fails but we have a connection, return true anyway
          // as the issue might be with the test URL rather than actual connectivity
          return true;
        }
      } else {
        // No network available
        return false;
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      // If connectivity check fails, assume we have internet and let the actual requests fail gracefully
      return true;
    }
  }

  success(message) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      OverlayToastManager().show(context, message.toString(), isError: false);
    } else {
      final state = scaffoldMessengerKey.currentState;
      if (state != null) {
        state.hideCurrentSnackBar();
        state.showSnackBar(
          SnackBar(
            content: Text(
              message.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );
      } else {
        return Fluttertoast.showToast(
            msg: message.toString(),
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 5,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    }
  }

  error(message) async {
    if (message == 'Please connect to the internet to continue learning.') {
      final now = DateTime.now();
      if (_lastOfflineToastTime != null &&
          now.difference(_lastOfflineToastTime!).inSeconds < 5) {
        return; // Throttle offline message
      }
      _lastOfflineToastTime = now;
    }

    final context = navigatorKey.currentContext;
    if (context != null) {
      OverlayToastManager().show(context, message.toString(), isError: true);
    } else {
      final state = scaffoldMessengerKey.currentState;
      if (state != null) {
        state.hideCurrentSnackBar();
        state.showSnackBar(
          SnackBar(
            content: Text(
              message.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );
      } else {
        return Fluttertoast.showToast(
            msg: message.toString(),
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 5,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    }
  }

  storeUser(email, userId, token, role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token.toString());
    await prefs.setString('email', email.toString());
    await prefs.setString('user_id', userId.toString());
    await prefs.setString('role', role.toString());
  }

  getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('email'),
      'token': prefs.getString('token'),
      'role': prefs.getString('role'),
      'user_id': prefs.getString('user_id'),
    };
  }

  getCurrentToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('email');
    prefs.remove('user_id');
    prefs.remove('role');
    prefs.remove('token');
    return true;
  }

  loader() {
    return const Padding(
      padding: EdgeInsets.only(top: 15),
      child: SpinKitCubeGrid(
        color: Colors.yellow,
        size: 50.0,
      ),
    );
  }
}

class ToastNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    OverlayToastManager().dismissActiveToast();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    OverlayToastManager().dismissActiveToast();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    OverlayToastManager().dismissActiveToast();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    OverlayToastManager().dismissActiveToast();
  }
}

class OverlayToastManager {
  static final OverlayToastManager _instance = OverlayToastManager._internal();
  factory OverlayToastManager() => _instance;
  OverlayToastManager._internal();

  OverlayEntry? _currentEntry;
  Timer? _dismissTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  GlobalKey<_CustomToastWidgetState>? _toastKey;

  void show(BuildContext context, String message, {required bool isError}) {
    dismissActiveToast();

    // Start listening to connectivity changes ONLY while toast is visible
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final bool isOnline = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet) ||
          results.contains(ConnectivityResult.other);
      if (isOnline) {
        dismissActiveToast();
      }
    });

    _toastKey = GlobalKey<_CustomToastWidgetState>();

    final entry = OverlayEntry(
      builder: (context) {
        return CustomToastWidget(
          key: _toastKey,
          message: message,
          isError: isError,
          onDismiss: dismissActiveToast,
        );
      },
    );

    final overlay = Overlay.of(context);
    overlay.insert(entry);
    _currentEntry = entry;

    _dismissTimer = Timer(const Duration(seconds: 5), () {
      dismissActiveToast();
    });
  }

  void dismissActiveToast() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    final entry = _currentEntry;
    final state = _toastKey?.currentState;

    if (entry != null) {
      _currentEntry = null;
      _toastKey = null;

      if (state != null && state.mounted) {
        state.animateOut().then((_) {
          entry.remove();
        });
      } else {
        entry.remove();
      }
    }
  }
}

class CustomToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const CustomToastWidget({
    super.key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<CustomToastWidget> createState() => _CustomToastWidgetState();
}

class _CustomToastWidgetState extends State<CustomToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> animateOut() async {
    if (mounted) {
      await _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOfflineMessage =
        widget.message.toLowerCase().contains('connect to the internet') ||
        widget.message.toLowerCase().contains('unavailable') ||
        widget.message.toLowerCase().contains('no internet') ||
        widget.message.toLowerCase().contains('network error') ||
        widget.message.toLowerCase().contains('connection') ||
        widget.message.toLowerCase().contains('offline');

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isError
                          ? const Color(0xE6D32F2F) // Crimson red with E6 opacity
                          : const Color(0xE62E7D32), // Emerald green with E6 opacity
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOfflineMessage
                              ? Icons.wifi_off_outlined
                              : (widget.isError
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline),
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
