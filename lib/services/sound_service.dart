import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Plays short UI sound effects + triggers haptic feedback.
///
/// Audio files are optional. Drop MP3s named below into `assets/sounds/`
/// and they'll be used automatically. If they're missing, we silent-fail
/// so the app never crashes — haptic feedback still fires.
///
/// Expected files:
///   assets/sounds/coin.wav       — coin drop / reward
///   assets/sounds/success.wav    — task complete / level up
///   assets/sounds/pop.wav        — generic button tap
///   assets/sounds/oink.wav       — pig interaction (optional)
///
/// Free sources: https://freesound.org, https://pixabay.com/sound-effects/
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  final AudioPlayer _player = AudioPlayer(playerId: 'ipon_sfx');
  bool _enabled = true;

  bool get enabled => _enabled;
  set enabled(bool v) => _enabled = v;

  Future<void> _play(String asset) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (e) {
      if (kDebugMode) debugPrint('SoundService: missing asset "$asset" ($e)');
    }
  }

  Future<void> coin() async {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    _play('sounds/coin.wav');
  }

  Future<void> success() async {
    HapticFeedback.mediumImpact();
    _play('sounds/success.wav');
  }

  Future<void> levelUp() async {
    HapticFeedback.heavyImpact();
    _play('sounds/success.wav');
  }

  Future<void> pop() async {
    HapticFeedback.selectionClick();
    _play('sounds/pop.wav');
  }

  Future<void> pigTap() async {
    HapticFeedback.lightImpact();
    _play('sounds/oink.wav');
  }
}
