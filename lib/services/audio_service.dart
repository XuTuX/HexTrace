import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static const String _backgroundBgmAsset = 'bgm/background_bgm.mp3';
  static const String _homeBgmAsset = 'bgm/home_background.mp3';
  static const String _clearSfxAsset = 'bgm/clear_bgm.mp3';
  static const String _clickSfxAsset = 'bgm/click.mp3';
  static const double _gameBgmVolume = 0.18;
  static const double _homeBgmVolume = 0.18;
  static const double _clearSfxVolume = 0.36;
  static const double _clickSfxVolume = 0.36;

  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final Set<AudioPlayer> _notePlayers = <AudioPlayer>{};

  bool _isBgmEnabled = true;
  bool _isSfxEnabled = true;
  bool _shouldPlayBgm = false;
  bool _isBgmPausedByLifecycle = false;
  String? _currentBgmAsset;
  double _currentBgmVolume = _gameBgmVolume;

  Future<void> initialize({
    required bool isBgmEnabled,
    required bool isSfxEnabled,
  }) async {
    _isBgmEnabled = isBgmEnabled;
    _isSfxEnabled = isSfxEnabled;
    await _runSafely('initialize audio players', () async {
      await AudioPlayer.global.setAudioContext(AudioContextConfig(
        route: AudioContextConfigRoute.system,
        focus: AudioContextConfigFocus.mixWithOthers,
        respectSilence: true,
        stayAwake: false,
      ).build());

      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_currentBgmVolume);
      await _sfxPlayer.setVolume(_clearSfxVolume);
    });
  }

  Future<void> startBGM() async {
    await _startBgmAsset(
      asset: _backgroundBgmAsset,
      volume: _gameBgmVolume,
      action: 'start game BGM',
    );
  }

  Future<void> startHomeBGM() async {
    await _startBgmAsset(
      asset: _homeBgmAsset,
      volume: _homeBgmVolume,
      action: 'start home BGM',
    );
  }

  Future<void> _startBgmAsset({
    required String asset,
    required double volume,
    required String action,
  }) async {
    _shouldPlayBgm = true;
    _isBgmPausedByLifecycle = false;
    _currentBgmAsset = asset;
    _currentBgmVolume = volume;
    if (!_isBgmEnabled) {
      await _runSafely('stop disabled BGM', _bgmPlayer.stop);
      return;
    }

    await _playBackgroundBgm(action);
  }

  Future<void> stopBGM() async {
    _shouldPlayBgm = false;
    _isBgmPausedByLifecycle = false;
    await _runSafely('stop BGM', _bgmPlayer.stop);
  }

  Future<void> pauseBGM() async {
    if (!_shouldPlayBgm) {
      return;
    }

    _isBgmPausedByLifecycle = true;
    await _runSafely('pause BGM', _bgmPlayer.pause);
  }

  Future<void> resumeBGMIfNeeded() async {
    if (!_shouldPlayBgm ||
        !_isBgmEnabled ||
        !_isBgmPausedByLifecycle ||
        _currentBgmAsset == null) {
      return;
    }

    _isBgmPausedByLifecycle = false;
    await _playBackgroundBgm('resume BGM');
  }

  Future<void> playClearSound() async {
    if (!_isSfxEnabled) {
      return;
    }

    await _runSafely('play clear sound', () async {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_clearSfxVolume);
      await _sfxPlayer.play(AssetSource(_clearSfxAsset));
    });
  }

  Future<void> playNote(int index) async {
    if (!_isSfxEnabled) {
      return;
    }

    final player = AudioPlayer();
    _notePlayers.add(player);
    player.onPlayerComplete.listen((_) async {
      _notePlayers.remove(player);
      await _runSafely('dispose completed note player', player.dispose);
    });

    try {
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setVolume(_clickSfxVolume);
      await player.play(AssetSource(_clickSfxAsset));
    } catch (error, stackTrace) {
      debugPrint('AudioService failed to play click sound: $error');
      debugPrintStack(stackTrace: stackTrace);
      _notePlayers.remove(player);
      await _runSafely('dispose failed note player', player.dispose);
    }
  }

  Future<void> setBgmEnabled(bool enabled) async {
    _isBgmEnabled = enabled;
    if (!enabled) {
      _isBgmPausedByLifecycle = false;
      await _runSafely('stop disabled BGM', _bgmPlayer.stop);
      return;
    }

    if (_shouldPlayBgm) {
      _isBgmPausedByLifecycle = false;
      await _playBackgroundBgm('enable BGM');
    }
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _isSfxEnabled = enabled;
    if (enabled) {
      return;
    }

    await _runSafely('stop clear sound player', _sfxPlayer.stop);
    await _stopActiveNotes();
  }

  Future<void> _playBackgroundBgm(String action) async {
    final asset = _currentBgmAsset;
    if (asset == null) {
      return;
    }

    await _runSafely(action, () async {
      await _bgmPlayer.stop();
      await _bgmPlayer.setVolume(_currentBgmVolume);
      await _bgmPlayer.play(AssetSource(asset));
    });
  }

  Future<void> _stopActiveNotes() async {
    final players = List<AudioPlayer>.from(_notePlayers);
    _notePlayers.clear();

    for (final player in players) {
      await _runSafely('stop active note player', () async {
        await player.stop();
        await player.dispose();
      });
    }
  }

  Future<void> _runSafely(
    String action,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      debugPrint('AudioService failed to $action: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
