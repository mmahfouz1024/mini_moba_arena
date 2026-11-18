import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _fx = AudioPlayer();
  bool soundEnabled = true;
  bool hapticsEnabled = true;

  Future<void> playEffect(String assetName) async {
    if (!soundEnabled) return;
    try {
      await _fx.stop();
      await _fx.play(AssetSource('audio/$assetName'), volume: 0.55);
    } catch (_) {
      // Ignore audio failures in headless tests.
    }
  }

  void lightHaptic() {
    if (hapticsEnabled) HapticFeedback.lightImpact();
  }

  void heavyHaptic() {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
  }
}
