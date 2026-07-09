import 'dart:async';
import 'package:flutter/material.dart';
import '../Library/RestClient.dart';

class DeviceStatusSheet extends StatefulWidget {
  final Color backgroundColor;

  const DeviceStatusSheet({
    super.key,
    this.backgroundColor = Colors.blue,
  });

  @override
  State<DeviceStatusSheet> createState() => _DeviceStatusSheetState();
}

class _DeviceStatusSheetState extends State<DeviceStatusSheet> {
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
          Navigator.of(context).pop();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: widget.backgroundColor,
      child: Stack(
        children: [
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Device Status'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(15),
                  child: Center(child: _deviceStatusWidget()),
                ),
              ],
            ),
          ),
          // Top right countdown
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_secondsLeft',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceStatusWidget() {
    return FutureBuilder(
      future: RestClient().checkInternetConnection(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            "Checking...",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        } else if (snapshot.hasError) {
          return const Text(
            "We are unable to check device status.",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        } else {
          if (snapshot.data == true) {
            return const Text(
              "Awesome! You're connected. All system go!.",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            );
          } else {
            return const Text(
              "Oops! Looks like you're offline. Check your connection, and let's get back on track.",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            );
          }
        }
      },
    );
  }
}
