import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool enabled = true;

  Future<void> tick() => _play('tick.wav', volume: 0.18);
  Future<void> success() => _play('success.wav', volume: 0.22);
  Future<void> complete() => _play('complete.wav', volume: 0.28);

  Future<void> _play(String asset, {double volume = 0.2}) async {
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource('sounds/$asset'));
    } catch (_) {
      // Audio is a progressive enhancement; never block the UI.
    }
  }
}
