import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _initAudio();
  }

  final AudioPlayer _player;

  static const String onboardingSuccessAsset = 'audio/success_bell.mp3';

  Future<void> _initAudio() async {
    try {
      await _player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
    } catch (_) {
      // Audio context setup failed, continue anyway
    }
  }

  Future<void> playOnboardingSuccess({double volume = 0.7}) async {
    try {
      await _player.setVolume(volume);
      await _player.play(AssetSource(onboardingSuccessAsset));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }
}
