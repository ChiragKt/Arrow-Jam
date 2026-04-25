import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum GameSound { tapClear, collision, levelWin }

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  bool _sfxMuted = false;
  bool _musicMuted = false;
  bool _hapticsMuted = false;

  // ── SFX pool (stacked so rapid taps don't cut each other off) ─────────────
  final _clearPlayers     = <AudioPlayer>[];
  final _collisionPlayers = <AudioPlayer>[];
  final _winPlayers       = <AudioPlayer>[];

  int _clearIdx     = 0;
  int _collisionIdx = 0;
  int _winIdx       = 0;

  // ── Background music ──────────────────────────────────────────────────────
  AudioPlayer? _musicPlayer;
  bool _musicReady = false;

  bool _ready = false;

  Future<void> init() async {
    try {
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
    } catch (_) {}

    // Background music — silent fail if asset is missing
    try {
      _musicPlayer = AudioPlayer();
      await _musicPlayer!.setSource(AssetSource('sounds/ambient.mp3'));
      await _musicPlayer!.setVolume(0.35);
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      _musicReady = true;
      if (!_musicMuted) {
        await _musicPlayer!.resume();
      }
    } catch (_) {}
  }

  // ── Controls ─────────────────────────────────────────────────────────────

  void setSfxMuted(bool muted) => _sfxMuted = muted;

  /// Call whenever `settings.musicEnabled` changes.
  void setMusicMuted(bool muted) {
    _musicMuted = muted;
    if (!_musicReady) return;
    if (muted) {
      _musicPlayer?.pause();
    } else {
      _musicPlayer?.resume();
    }
  }

  void setHapticsMuted(bool muted) => _hapticsMuted = muted;

  // ── SFX ──────────────────────────────────────────────────────────────────

  Future<void> play(GameSound sound) async {
    if (_sfxMuted || !_ready) return;
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
    } catch (_) {}
  }

  // ── Haptics ───────────────────────────────────────────────────────────────

  Future<void> lightImpact() async {
    if (_hapticsMuted) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> mediumImpact() async {
    if (_hapticsMuted) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> selectionClick() async {
    if (_hapticsMuted) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final p in [..._clearPlayers, ..._collisionPlayers, ..._winPlayers]) {
      await p.dispose();
    }
    _clearPlayers.clear();
    _collisionPlayers.clear();
    _winPlayers.clear();
    await _musicPlayer?.dispose();
    _musicPlayer = null;
    _ready = false;
    _musicReady = false;
  }
}
