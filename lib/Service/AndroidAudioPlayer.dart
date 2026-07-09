import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'AudioPlayerInterface.dart';

class AndroidAudioPlayer implements AudioPlayerInterface {
  late AudioPlayer _audioPlayer;

  AndroidAudioPlayer() {
    _audioPlayer = AudioPlayer();
  }

  @override
  Stream<bool> get playingStream =>
      _audioPlayer.playerStateStream.map((state) => state.playing);

  @override
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  @override
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  @override
  bool get isPlaying => _audioPlayer.playing;

  @override
  Duration get position => _audioPlayer.position;

  @override
  Duration get duration => _audioPlayer.duration ?? Duration.zero;

  @override
  Future<void> setUrl(String url) async {
    await _audioPlayer.setUrl(url);
  }

  @override
  Future<void> play() async {
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  @override
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
