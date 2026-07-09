import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class RestClient {
  final String baseUrl = "https://www.mydigitalcollege.co.za/crm/api";

  guestPost(endpoint, param) async {
    var headers = {'Accept': 'application/json'};
    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl$endpoint"));
    request.fields.addAll(param);
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print(responseBody);
      return jsonDecode(responseBody);
    } else {
      print(response.reasonPhrase);
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
      print(response.reasonPhrase);
    }
  }

  authPost(endpoint, param) async {
    final token = await getCurrentToken();
    var headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    };
    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl$endpoint"));
    request.fields.addAll(param);
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      print(response.reasonPhrase);
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
              print('JSON decode error: $e');
              return null;
            }
          } else {
            print('Response is not valid JSON (likely HTML error page)');
            return null;
          }
        } else {
          print(
              'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Request failed'}');
          return null;
        }
      } catch (e) {
        print('Network request error: $e');
        // Fallback to cached data if available
        final cachedData = await getCachedResponse(endpoint);
        if (cachedData != null) {
          try {
            return jsonDecode(cachedData);
          } catch (e) {
            print('Cached JSON decode error: $e');
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
          print('Cached JSON decode error: $e');
          return null;
        }
      } else {
        print('No cached data available');
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
      print('Response cached successfully for $endpoint');
    } catch (e) {
      print('Error caching response: $e');
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
      print('Error reading cached data: $e');
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
          print('Internet connectivity test failed: $e');
          // If the connectivity test fails but we have a connection, return true anyway
          // as the issue might be with the test URL rather than actual connectivity
          return true;
        }
      } else {
        // No network available
        return false;
      }
    } catch (e) {
      print('Error checking connectivity: $e');
      // If connectivity check fails, assume we have internet and let the actual requests fail gracefully
      return true;
    }
  }

  success(message) async {
    // Fluttertoast doesn't support Windows, so just print for Windows
    if (Platform.isWindows) {
      print('SUCCESS: $message');
      return;
    }
    return Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  error(message) async {
    // Fluttertoast doesn't support Windows, so just print for Windows
    if (Platform.isWindows) {
      print('ERROR: $message');
      return;
    }
    return Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
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
