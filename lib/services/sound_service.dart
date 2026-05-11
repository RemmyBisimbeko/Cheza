import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SoundService {
  final _player = AudioPlayer();
  bool _muted = false;

  bool get isMuted => _muted;
  void toggleMute() => _muted = !_muted;

  Future<void> playCardPlay() => _play('sounds/card_play.mp3');
  Future<void> playCardDraw() => _play('sounds/card_draw.mp3');
  Future<void> playWin() => _play('sounds/win.mp3');
  Future<void> playLose() => _play('sounds/lose.mp3');
  Future<void> playShuffle() => _play('sounds/shuffle.mp3');

  Future<void> _play(String path) async {
    if (_muted) return;
    try {
      await _player.play(AssetSource(path));
    } catch (_) {
      // Silently fail if sound file missing
    }
  }

  void dispose() => _player.dispose();
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});
