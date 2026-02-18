import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/meditation_enums.dart';
import '../domain/services/meditation_guide_builder.dart';
import 'meditation_state.dart';

/// Manages the full meditation session lifecycle.
///
/// Mirrors the old MeditationStore + MeditationOrchestrator but keeps
/// everything in a single Riverpod notifier for simplicity.
class MeditationNotifier extends StateNotifier<MeditationState> {
  MeditationNotifier() : super(MeditationState.initial()) {
    _initAudio();
  }

  Timer? _countdownTimer;
  Timer? _sessionTimer;
  Timer? _breathTimer;

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();

  Future<void> _initAudio() async {
    try {
      final context = AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      );
      await _bgPlayer.setAudioContext(context);
      await _bellPlayer.setAudioContext(context);
    } catch (_) {
      // Audio context setup failed, continue anyway
    }
  }

  // ── Setup actions ──────────────────────────────────────────────────────

  void setStyle(MeditationStyle style) {
    state = state.copyWith(style: style);
    _rebuildGuide();
  }

  void setSelectedMinutes(int minutes) {
    state = state.copyWith(selectedMinutes: minutes);
    _rebuildGuide();
  }

  void setBackgroundSound(BackgroundSound sound) {
    state = state.copyWith(backgroundSound: sound);
  }

  void setBreathPace(BreathPace pace) {
    state = state.copyWith(breathPace: pace);
  }

  void setCenteringWord(String word) {
    state = state.copyWith(centeringWord: word.trim().isEmpty ? 'Jesus' : word.trim());
    _rebuildGuide();
  }

  void setVirtueName(String? name) {
    state = state.copyWith(virtueName: name);
    _rebuildGuide();
  }

  // ── Session lifecycle ──────────────────────────────────────────────────

  void startSession() {
    if (!state.isReadyToBegin) return;

    _rebuildGuide();

    state = state.copyWith(
      phase: MeditationPhase.countdown,
      countdown: 5,
      elapsedSeconds: 0,
    );

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.countdown <= 1) {
        _countdownTimer?.cancel();
        _countdownTimer = null;
        _beginActivePhase();
      } else {
        state = state.copyWith(countdown: state.countdown - 1);
      }
    });
  }

  void _beginActivePhase() {
    state = state.copyWith(
      phase: MeditationPhase.active,
      elapsedSeconds: 0,
    );

    _startSessionTimer();
    _startBreathCycle();
    _playBackground();
  }

  void pause() {
    if (state.phase != MeditationPhase.active &&
        state.phase != MeditationPhase.countdown) {
      return;
    }
    _countdownTimer?.cancel();
    _sessionTimer?.cancel();
    _breathTimer?.cancel();
    _bgPlayer.pause();
    state = state.copyWith(phase: MeditationPhase.paused);
  }

  void resume() {
    if (state.phase != MeditationPhase.paused) return;
    state = state.copyWith(phase: MeditationPhase.active);
    _startSessionTimer();
    _startBreathCycle();
    _bgPlayer.resume();
  }

  void endSession() {
    _cancelAllTimers();
    _bgPlayer.stop();
    _bellPlayer.play(AssetSource('audio/success_bell.mp3'));
    state = state.copyWith(
      phase: MeditationPhase.complete,
      sessionCount: state.sessionCount + 1,
    );
  }

  void resetToSetup() {
    _cancelAllTimers();
    _bgPlayer.stop();
    _bellPlayer.stop();
    state = state.copyWith(
      phase: MeditationPhase.setup,
      countdown: 5,
      elapsedSeconds: 0,
      breathPhase: BreathPhase.breathIn,
    );
  }

  // ── Internal timers ────────────────────────────────────────────────────

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.elapsedSeconds + 1;
      if (next >= state.totalSeconds) {
        endSession();
      } else {
        state = state.copyWith(elapsedSeconds: next);
      }
    });
  }

  void _startBreathCycle() {
    _breathTimer?.cancel();
    _runBreathPhase(BreathPhase.breathIn);
  }

  void _runBreathPhase(BreathPhase phase) {
    if (state.phase != MeditationPhase.active) return;

    state = state.copyWith(breathPhase: phase);

    final pace = state.breathPace;
    final durationMs = switch (phase) {
      BreathPhase.breathIn => pace.inMs,
      BreathPhase.hold => pace.holdMs,
      BreathPhase.breathOut => pace.outMs,
    };

    _breathTimer = Timer(Duration(milliseconds: durationMs), () {
      final next = switch (phase) {
        BreathPhase.breathIn => BreathPhase.hold,
        BreathPhase.hold => BreathPhase.breathOut,
        BreathPhase.breathOut => BreathPhase.breathIn,
      };
      _runBreathPhase(next);
    });
  }

  void _rebuildGuide() {
    final guide = MeditationGuideBuilder.build(
      style: state.style,
      selectedMinutes: state.selectedMinutes,
      sessionCount: state.sessionCount,
      virtueName: state.virtueName,
      centeringWord: state.centeringWord,
    );
    state = state.copyWith(guide: guide);
  }

  void _cancelAllTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _breathTimer?.cancel();
    _breathTimer = null;
  }

  Future<void> _playBackground() async {
    final sound = state.backgroundSound;
    if (sound == BackgroundSound.silent) return;
    final asset = switch (sound) {
      BackgroundSound.ambient => 'audio/ambient.mp3',
      BackgroundSound.heartbeat => 'audio/heartbeat.mp3',
      BackgroundSound.silent => '',
    };
    if (asset.isEmpty) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.4);
      await _bgPlayer.play(AssetSource(asset));
    } catch (_) {
      // Asset not yet available — session continues silently
    }
  }

  @override
  void dispose() {
    _cancelAllTimers();
    _bgPlayer.dispose();
    _bellPlayer.dispose();
    super.dispose();
  }
}

final meditationProvider =
    StateNotifierProvider<MeditationNotifier, MeditationState>((ref) {
  return MeditationNotifier();
});
