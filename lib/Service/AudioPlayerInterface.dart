import 'dart:async';

abstract class AudioPlayerInterface {
  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;

  Future<void> setUrl(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> dispose();

  bool get isPlaying;
  Duration get position;
  Duration get duration;
}
