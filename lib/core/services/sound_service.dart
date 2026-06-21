import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService({required bool soundEnabled}) : _soundEnabled = soundEnabled {
    _initAudio();
  }

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _soundEnabled;
  bool _isAmbientPlaying = false;
  bool _isDndActive = false;
  bool _isAppPaused = false;
  String? _currentAmbientAsset;

  // ── Semantic asset constants ─────────────────────────────────────────────
  static const String welcomeShinyAsset = 'audio/welcome-shiny.mp3';
  static const String tapAsset = 'audio/ui-tap.mp3';
  static const String successAsset = 'audio/ui-success.mp3';
  static const String completeAsset = 'audio/ui-complete.mp3';
  static const String errorAsset = 'audio/ui-error.mp3';
  static const String transitionAsset = 'audio/transition-whoosh.mp3';
  static const String pageTurnAsset = 'audio/page-turn.mp3';
  static const String paperRustleAsset = 'audio/paper-rustle.mp3';
  static const String ambientHomeAsset = 'audio/ambient/ambient-home.mp3';
  static const String ambientTodayAsset = 'audio/ambient/ambient-today.mp3';
  static const String ambientBibleAsset = 'audio/ambient/ambient-bible.mp3';
  static const String ambientCommunityAsset = 'audio/ambient/community.mp3';
  static const String bellMeditationAsset = 'audio/bell-meditation.mp3';
  static const String chimeGentleAsset = 'audio/chime-gentle.mp3';
  static const String successBellAsset = 'audio/success_bell.mp3';
  static const String levelUpAsset = 'audio/level-up.mp3';
  static const String correctAsset = 'audio/correct.mp3';
  static const String wrongAsset = 'audio/wrong.mp3';

  // ── Game-specific asset constants ────────────────────────────────────────
  static const String gameTimeoutAsset = 'audio/timeout.mp3';
  static const String gameOverAsset = 'audio/game-over.mp3';
  static const String gameTickAsset = 'audio/tick-tock.wav';

  bool get soundEnabled => _soundEnabled;

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      unawaited(stopAmbient());
      unawaited(_sfxPlayer.stop());
    }
  }

  void setDndActive(bool active) {
    _isDndActive = active;
    if (active) {
      unawaited(stopAmbient());
    }
  }

  void setAppPaused(bool paused) {
    _isAppPaused = paused;
    if (paused) {
      unawaited(_ambientPlayer.pause());
    } else if (_isAmbientPlaying && _currentAmbientAsset != null) {
      unawaited(_ambientPlayer.resume());
    }
  }

  Future<void> _initAudio() async {
    try {
      await _ambientPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
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
      await _sfxPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
    } catch (_) {
      // Continue silently; audio is not launch-critical.
    }
  }

  Future<void> _playSfx(String asset, {double volume = 0.5}) async {
    if (!_soundEnabled || _isDndActive || _isAppPaused) return;
    try {
      await _sfxPlayer.setVolume(volume);
      await _sfxPlayer.play(AssetSource(asset));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  // ── Semantic SFX methods ─────────────────────────────────────────────────
  Future<void> playTap() => _playSfx(tapAsset, volume: 0.18);
  Future<void> playSuccess() => _playSfx(successAsset, volume: 0.5);
  Future<void> playComplete() => _playSfx(completeAsset, volume: 0.5);
  Future<void> playError() => _playSfx(errorAsset, volume: 0.35);
  Future<void> playTransition() => _playSfx(transitionAsset, volume: 0.25);
  Future<void> playPageTurn() => _playSfx(pageTurnAsset, volume: 0.22);
  Future<void> playPaperRustle() => _playSfx(paperRustleAsset, volume: 0.2);
  Future<void> playWelcomeShiny() => _playSfx(welcomeShinyAsset, volume: 0.7);
  Future<void> playBellMeditation() => _playSfx(bellMeditationAsset, volume: 0.5);
  Future<void> playChimeGentle() => _playSfx(chimeGentleAsset, volume: 0.5);
  Future<void> playSuccessBell() => _playSfx(successBellAsset, volume: 0.5);
  Future<void> playLevelUp() => _playSfx(levelUpAsset, volume: 0.5);
  Future<void> playCorrect() => _playSfx(correctAsset, volume: 0.5);
  Future<void> playWrong() => _playSfx(wrongAsset, volume: 0.35);

  // ── Game-specific sounds (no generic semantic equivalent) ───────────────
  Future<void> playGameTick() => _playSfx(gameTickAsset, volume: 0.1);
  Future<void> playGameTimeout() => _playSfx(gameTimeoutAsset, volume: 0.4);
  Future<void> playGameOver() => _playSfx(gameOverAsset, volume: 0.5);
  Future<void> playJourneyAmbience({double volume = 0.12}) =>
      playAmbient(ambientHomeAsset, volume: volume);
  Future<void> stopJourneyAmbience() => stopAmbient();

  // ── Ambient methods ──────────────────────────────────────────────────────
  Future<void> playAmbient(String asset, {double volume = 0.10}) async {
    if (!_soundEnabled || _isDndActive || _isAppPaused) return;
    if (_isAmbientPlaying && _currentAmbientAsset == asset) return;

    try {
      await stopAmbient();
      _isAmbientPlaying = true;
      _currentAmbientAsset = asset;
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(volume);
      await _ambientPlayer.play(AssetSource(asset));
    } catch (_) {
      _isAmbientPlaying = false;
      _currentAmbientAsset = null;
    }
  }

  Future<void> stopAmbient() async {
    if (!_isAmbientPlaying) return;
    try {
      await _ambientPlayer.stop();
      await _ambientPlayer.setReleaseMode(ReleaseMode.release);
    } catch (_) {
    } finally {
      _isAmbientPlaying = false;
      _currentAmbientAsset = null;
    }
  }

  /// Stop all currently playing audio (ambient + SFX).
  Future<void> stopAll() async {
    await stopAmbient();
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stopAll();
    await _ambientPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
