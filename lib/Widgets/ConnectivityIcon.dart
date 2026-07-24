import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:EQ8/Library/RestClient.dart';

class ConnectivityIcon extends StatefulWidget {
  const ConnectivityIcon({super.key});

  @override
  State<ConnectivityIcon> createState() => _ConnectivityIconState();
}

class _ConnectivityIconState extends State<ConnectivityIcon> {
  bool? _isVerifiedOnline;
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _performInitialCheck();

    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      
      final hasHardwareConnection = result.any((r) => r != ConnectivityResult.none);
      
      if (!hasHardwareConnection) {
        // Hardware is disconnected, instantly show offline
        setState(() {
          _isVerifiedOnline = false;
          _isChecking = false;
        });
      } else {
        // Hardware connected, verify with HTTP ping
        setState(() {
          _isChecking = true;
        });
        _verifyConnection();
      }
    });
  }

  Future<void> _performInitialCheck() async {
    await _verifyConnection();
  }

  Future<void> _verifyConnection() async {
    final isConnected = await RestClient().checkInternetConnection();
    if (mounted) {
      setState(() {
        _isVerifiedOnline = isConnected;
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Icon(Icons.wifi_find_outlined);
    }
    
    if (_isVerifiedOnline == true) {
      return const Icon(Icons.wifi);
    } else {
      return const Icon(Icons.wifi_off);
    }
  }
}
