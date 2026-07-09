import 'dart:io';
import 'package:flutter/foundation.dart';
import 'AudioPlayerInterface.dart';
import 'AndroidAudioPlayer.dart';
import 'WindowsAudioPlayer.dart';

class AudioPlayerFactory {
  static AudioPlayerInterface createAudioPlayer() {
    if (kIsWeb) {
      // For web, we can use WindowsAudioPlayer as audioplayers supports web
      return WindowsAudioPlayer();
    } else if (Platform.isWindows) {
      return WindowsAudioPlayer();
    } else {
      // For Android, iOS, macOS, Linux - use just_audio
      return AndroidAudioPlayer();
    }
  }
}
