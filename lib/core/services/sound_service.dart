import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _initAudio();
  }

  final AudioPlayer _player;
  final AudioPlayer _sfxPlayer = AudioPlayer();

  static const String onboardingSuccessAsset = 'audio/success_bell.mp3';
  static const String gameTapAsset = 'audio/ding.wav';
  static const String gameFailAsset = 'audio/wrong.mp3';
  static const String gameTimeoutAsset = 'audio/timeout.mp3';
  static const String gameLevelUpAsset = 'audio/level-up.mp3';
  static const String gameOverAsset = 'audio/game-over.mp3';
  static const String gameTickAsset = 'audio/tick-tock.wav';
  static const String gameSuccessAsset = 'audio/correct.mp3';

  Future<void> _initAudio() async {
    try {
      await _player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
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

  Future<void> playGameSuccess() async {
    try {
      await _sfxPlayer.setVolume(0.5);
      await _sfxPlayer.play(AssetSource(gameSuccessAsset));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playGameTap() async {
    try {
      await _sfxPlayer.setVolume(0.18);
      await _sfxPlayer.play(AssetSource(gameTapAsset));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playGameTick() async {
    try {
      await _sfxPlayer.setVolume(0.1);
      await _sfxPlayer.play(AssetSource(gameTickAsset));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playGameFail() async {
    try {
      await _sfxPlayer.setVolume(0.35);
      await _sfxPlayer.play(AssetSource(gameFailAsset));
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> playGameTimeout() async {
    try {
      await _sfxPlayer.setVolume(0.4);
      await _sfxPlayer.play(AssetSource(gameTimeoutAsset));
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> playGameLevelUp() async {
    try {
      await _sfxPlayer.setVolume(0.5);
      await _sfxPlayer.play(AssetSource(gameLevelUpAsset));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playGameOver() async {
    try {
      await _sfxPlayer.setVolume(0.5);
      await _sfxPlayer.play(AssetSource(gameOverAsset));
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }
}
