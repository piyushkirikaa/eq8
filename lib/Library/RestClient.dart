import 'dart:convert';
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
    print(headers);
    // Check if there's an internet connection
    var isConnected = await checkInternetConnection();
    if (isConnected) {
      // If there's an internet connection, send a live request
      var response = await sendLiveRequest(endpoint, headers);
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        // Cache the response
        await cacheResponse(endpoint, responseBody);
        return jsonDecode(responseBody);
      } else {
        print(response.reasonPhrase ?? 'Request failed');
      }
    } else {
      // If there's no internet connection, try to access cached data
      final cachedData = await getCachedResponse(endpoint);
      if (cachedData != null) {
        return jsonDecode(cachedData);
      } else {
        print('No cached data available');
      }
    }
    return null;
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
    final file = await DefaultCacheManager().putFile(
        "$baseUrl$endpoint", Uint8List.fromList(utf8.encode(responseBody)));
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
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      return true;
    } else {
      // No network available
      return false;
    }
  }

  success(message) async {
    return Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  error(message) async {
    return Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
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
