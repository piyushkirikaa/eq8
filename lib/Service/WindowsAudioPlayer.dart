import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'AudioPlayerInterface.dart';

class WindowsAudioPlayer implements AudioPlayerInterface {
  late AudioPlayer _audioPlayer;
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _positionTimer;

  WindowsAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _setupListeners();
  }

  void _setupListeners() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      _playingController.add(_isPlaying);

      if (_isPlaying) {
        _startPositionTimer();
      } else {
        _stopPositionTimer();
      }
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _duration = duration;
      _durationController.add(duration);
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      _position = position;
      _positionController.add(position);
    });
  }

  void _startPositionTimer() {
    _stopPositionTimer();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPlaying) {
        _positionController.add(_position);
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  Future<void> setUrl(String url) async {
    await _audioPlayer.setSourceUrl(url);
  }

  @override
  Future<void> play() async {
    await _audioPlayer.resume();
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
    _stopPositionTimer();
    await _playingController.close();
    await _positionController.close();
    await _durationController.close();
    await _audioPlayer.dispose();
  }
}
