import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();

  bool _sfxEnabled = true;
  bool _musicEnabled = true;

  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;

  void toggleSfx() {
    _sfxEnabled = !_sfxEnabled;
    if (!_sfxEnabled) _sfxPlayer.stop();
    notifyListeners();
  }

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      _playBgMusic();
    } else {
      _bgPlayer.stop();
    }
    notifyListeners();
  }

  Future<void> _playBgMusic() async {
    // Background music (add your own asset: assets/sounds/bg_music.mp3)
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.play(AssetSource('sounds/bg_music.mp3'), volume: 0.3);
    } catch (_) {
      // Asset may not exist — silently ignore
    }
  }

  Future<void> playMove() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('sounds/move.mp3'), volume: 0.6);
    } catch (_) {}
  }

  Future<void> playWall() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('sounds/wall.mp3'), volume: 0.5);
    } catch (_) {}
  }

  Future<void> playWin() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('sounds/win.mp3'), volume: 0.8);
    } catch (_) {}
  }

  Future<void> playLose() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('sounds/lose.mp3'), volume: 0.8);
    } catch (_) {}
  }

  Future<void> startMusic() async {
    if (_musicEnabled) await _playBgMusic();
  }

  void dispose() {
    _sfxPlayer.dispose();
    _bgPlayer.dispose();
    super.dispose();
  }
}
