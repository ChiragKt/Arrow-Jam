import 'package:audioplayers/audioplayers.dart';

enum GameSound { tapClear, collision, levelWin }

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  bool _muted = false;

  // Use a small pool of players per sound so rapid taps don't cut each other off.
  final _clearPlayers     = <AudioPlayer>[];
  final _collisionPlayers = <AudioPlayer>[];
  final _winPlayers       = <AudioPlayer>[];

  int _clearIdx     = 0;
  int _collisionIdx = 0;
  int _winIdx       = 0;

  bool _ready = false;

  Future<void> init() async {
    try {
      // Pre-create players and cache the sources so first-play latency is low.
      for (int i = 0; i < 4; i++) {
        final p = AudioPlayer();
        await p.setSource(AssetSource('sounds/tap_clear.mp3'));
        await p.setVolume(0.75);
        _clearPlayers.add(p);
      }
      for (int i = 0; i < 4; i++) {
        final p = AudioPlayer();
        await p.setSource(AssetSource('sounds/collision.mp3'));
        await p.setVolume(0.85);
        _collisionPlayers.add(p);
      }
      for (int i = 0; i < 2; i++) {
        final p = AudioPlayer();
        await p.setSource(AssetSource('sounds/level_win.mp3'));
        await p.setVolume(0.9);
        _winPlayers.add(p);
      }
      _ready = true;
    } catch (e) {
      // Assets missing or platform issue — game works silently.
    }
  }

  void setMuted(bool muted) => _muted = muted;

  Future<void> play(GameSound sound) async {
    if (_muted || !_ready) return;
    try {
      switch (sound) {
        case GameSound.tapClear:
          final p = _clearPlayers[_clearIdx % _clearPlayers.length];
          _clearIdx++;
          await p.seek(Duration.zero);
          await p.resume();
        case GameSound.collision:
          final p = _collisionPlayers[_collisionIdx % _collisionPlayers.length];
          _collisionIdx++;
          await p.seek(Duration.zero);
          await p.resume();
        case GameSound.levelWin:
          final p = _winPlayers[_winIdx % _winPlayers.length];
          _winIdx++;
          await p.seek(Duration.zero);
          await p.resume();
      }
    } catch (_) {
      // Never crash the game over audio.
    }
  }

  Future<void> dispose() async {
    for (final p in [..._clearPlayers, ..._collisionPlayers, ..._winPlayers]) {
      await p.dispose();
    }
    _clearPlayers.clear();
    _collisionPlayers.clear();
    _winPlayers.clear();
    _ready = false;
  }
}
