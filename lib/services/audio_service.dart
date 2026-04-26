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
  static const int _clickSfxMinPlayers = 6;
  static const int _clickSfxMaxPlayers = 8;
  static const int _clearSfxMinPlayers = 2;
  static const int _clearSfxMaxPlayers = 3;

  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  AudioPool? _clickSfxPool;
  AudioPool? _clearSfxPool;
  Future<void> _bgmOperation = Future<void>.value();
  Future<void>? _sfxPoolsReady;

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
        respectSilence: false,
        stayAwake: false,
      ).build());

      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_currentBgmVolume);
    });

    if (_isSfxEnabled) {
      await _ensureSfxPools();
    }
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
      await _queueBgmOperation('stop disabled BGM', _bgmPlayer.stop);
      return;
    }

    await _playBackgroundBgm(action);
  }

  Future<void> stopBGM() async {
    _shouldPlayBgm = false;
    _isBgmPausedByLifecycle = false;
    await _queueBgmOperation('stop BGM', _bgmPlayer.stop);
  }

  Future<void> pauseBGM() async {
    if (!_shouldPlayBgm) {
      return;
    }

    _isBgmPausedByLifecycle = true;
    await _queueBgmOperation('pause BGM', () async {
      if (_shouldPlayBgm && _isBgmPausedByLifecycle) {
        await _bgmPlayer.pause();
      }
    });
  }

  Future<void> resumeBGMIfNeeded() async {
    if (!_shouldPlayBgm || !_isBgmEnabled || _currentBgmAsset == null) {
      return;
    }

    _isBgmPausedByLifecycle = false;
    await _playBackgroundBgm('resume BGM');
  }

  Future<void> playClearSound() async {
    if (!_isSfxEnabled) {
      return;
    }

    await _ensureSfxPools();
    if (!_isSfxEnabled) {
      return;
    }

    final pool = _clearSfxPool;
    if (pool == null) {
      return;
    }

    await _runSafely(
      'play clear sound',
      () => pool.start(volume: _clearSfxVolume),
    );
  }

  Future<void> playNote(int index) async {
    if (!_isSfxEnabled) {
      return;
    }

    await _ensureSfxPools();
    if (!_isSfxEnabled) {
      return;
    }

    final pool = _clickSfxPool;
    if (pool == null) {
      return;
    }

    await _runSafely(
      'play click sound',
      () => pool.start(volume: _clickSfxVolume),
    );
  }

  Future<void> setBgmEnabled(bool enabled) async {
    _isBgmEnabled = enabled;
    if (!enabled) {
      _isBgmPausedByLifecycle = false;
      await _queueBgmOperation('stop disabled BGM', _bgmPlayer.stop);
      return;
    }

    if (_shouldPlayBgm) {
      _isBgmPausedByLifecycle = false;
      await _playBackgroundBgm('enable BGM');
    }
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _isSfxEnabled = enabled;
    if (!enabled) {
      await _disposeSfxPools();
      return;
    }

    await _ensureSfxPools();
  }

  Future<void> _playBackgroundBgm(String action) async {
    if (_currentBgmAsset == null) {
      return;
    }

    await _queueBgmOperation(action, () async {
      final asset = _currentBgmAsset;
      if (!_shouldPlayBgm || !_isBgmEnabled || asset == null) {
        return;
      }

      await _bgmPlayer.stop();
      await _bgmPlayer.setVolume(_currentBgmVolume);
      await _bgmPlayer.play(AssetSource(asset));
    });
  }

  Future<void> _queueBgmOperation(
    String action,
    Future<void> Function() operation,
  ) {
    _bgmOperation = _bgmOperation.then((_) {
      return _runSafely(action, operation);
    });
    return _bgmOperation;
  }

  Future<void> _ensureSfxPools() {
    if (!_isSfxEnabled) {
      return Future<void>.value();
    }

    if (_clickSfxPool != null && _clearSfxPool != null) {
      return Future<void>.value();
    }

    final pending = _sfxPoolsReady;
    if (pending != null) {
      return pending;
    }

    late final Future<void> ready;
    ready = _createSfxPools().whenComplete(() {
      if (identical(_sfxPoolsReady, ready)) {
        _sfxPoolsReady = null;
      }
    });
    _sfxPoolsReady = ready;
    return ready;
  }

  Future<void> _createSfxPools() async {
    await _runSafely('preload SFX players', () async {
      final clickPool = await AudioPool.createFromAsset(
        path: _clickSfxAsset,
        minPlayers: _clickSfxMinPlayers,
        maxPlayers: _clickSfxMaxPlayers,
      );
      AudioPool? clearPool;

      try {
        clearPool = await AudioPool.createFromAsset(
          path: _clearSfxAsset,
          minPlayers: _clearSfxMinPlayers,
          maxPlayers: _clearSfxMaxPlayers,
        );
      } catch (_) {
        await clickPool.dispose();
        rethrow;
      }

      if (!_isSfxEnabled) {
        await Future.wait([
          clickPool.dispose(),
          clearPool.dispose(),
        ]);
        return;
      }

      await _disposeSfxPools();
      _clickSfxPool = clickPool;
      _clearSfxPool = clearPool;
    });
  }

  Future<void> _disposeSfxPools() async {
    final clickPool = _clickSfxPool;
    final clearPool = _clearSfxPool;
    _clickSfxPool = null;
    _clearSfxPool = null;

    await _runSafely('dispose SFX players', () async {
      await Future.wait([
        if (clickPool != null) clickPool.dispose(),
        if (clearPool != null) clearPool.dispose(),
      ]);
    });
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
