import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static const String _backgroundBgmAsset = 'bgm/background_bgm.mp3';
  static const String _clearSfxAsset = 'bgm/clear_bgm.mp3';

  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final Set<AudioPlayer> _notePlayers = <AudioPlayer>{};

  bool _isBgmEnabled = true;
  bool _isSfxEnabled = true;
  bool _shouldPlayBgm = false;

  final List<String> _scaleNotes = [
    'bgm/C4.mp3',
    'bgm/D4.mp3',
    'bgm/E4.mp3',
    'bgm/F4.mp3',
    'bgm/G4.mp3',
    'bgm/A4.mp3',
    'bgm/B4.mp3',
    'bgm/C5.mp3',
  ];

  Future<void> initialize({
    required bool isBgmEnabled,
    required bool isSfxEnabled,
  }) async {
    _isBgmEnabled = isBgmEnabled;
    _isSfxEnabled = isSfxEnabled;
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> startBGM() async {
    _shouldPlayBgm = true;
    if (!_isBgmEnabled) {
      await _bgmPlayer.stop();
      return;
    }

    await _bgmPlayer.stop();
    await _bgmPlayer.play(AssetSource(_backgroundBgmAsset));
  }

  Future<void> stopBGM() async {
    _shouldPlayBgm = false;
    await _bgmPlayer.stop();
  }

  Future<void> playClearSound() async {
    if (!_isSfxEnabled) {
      return;
    }

    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource(_clearSfxAsset));
  }

  Future<void> playNote(int index) async {
    if (!_isSfxEnabled) {
      return;
    }

    final noteIndex = index % _scaleNotes.length;
    final player = AudioPlayer();
    _notePlayers.add(player);
    player.onPlayerComplete.listen((_) {
      _notePlayers.remove(player);
      player.dispose();
    });
    await player.play(AssetSource(_scaleNotes[noteIndex]));
  }

  Future<void> setBgmEnabled(bool enabled) async {
    _isBgmEnabled = enabled;
    if (!enabled) {
      await _bgmPlayer.stop();
      return;
    }

    if (_shouldPlayBgm) {
      await _bgmPlayer.stop();
      await _bgmPlayer.play(AssetSource(_backgroundBgmAsset));
    }
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _isSfxEnabled = enabled;
    if (enabled) {
      return;
    }

    await _sfxPlayer.stop();
    await _stopActiveNotes();
  }

  Future<void> _stopActiveNotes() async {
    final players = List<AudioPlayer>.from(_notePlayers);
    _notePlayers.clear();

    for (final player in players) {
      await player.stop();
      await player.dispose();
    }
  }
}
