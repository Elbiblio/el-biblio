import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/meditation_enums.dart';
import '../domain/models/meditation_templates.dart';
import '../domain/models/guided_meditation_phases.dart';
import '../domain/services/meditation_guide_builder.dart';
import '../domain/services/guided_meditation_builder.dart';
import '../data/repositories/meditation_session_api_repository.dart';
import '../data/repositories/meditation_session_repository.dart';
import '../data/services/meditation_audio_service.dart';
import '../data/services/global_audio_manager.dart';
import '../domain/models/chant_tracks.dart';
import '../domain/models/meditation_session.dart';
import '../../today/domain/models/daily_anchors.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/tts_service.dart';
import 'meditation_state.dart';
import '../../../core/services/disturbance_service.dart';
import '../../../core/services/wake_lock_service.dart';
import '../../../core/services/xp_service.dart';

/// Manages the full meditation session lifecycle.
///
/// Mirrors the old MeditationStore + MeditationOrchestrator but keeps
/// everything in a single Riverpod notifier for simplicity.
class MeditationNotifier extends StateNotifier<MeditationState> {
  MeditationNotifier({
    required MeditationSessionRepository sessionRepository,
    required MeditationSessionApiRepository sessionApiRepository,
    required Ref ref,
  })  : _sessionRepository = sessionRepository,
        _sessionApiRepository = sessionApiRepository,
        _ref = ref,
        super(MeditationState.initial()) {
    _audioService = MeditationAudioService(_bgPlayer);
    _ttsService = TTSService();
    _initAudio();
  }

  final Logger _logger = Logger();
  final Ref _ref;
  Timer? _countdownTimer;
  Timer? _sessionTimer;
  Timer? _breathTimer;
  Timer? _promptTimer;
  Timer? _guidedPhaseTimer;

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer();
  late final MeditationAudioService _audioService;
  late final TTSService _ttsService;
  
  // DND and Wake Lock services
  final DisturbanceService _dndService = DisturbanceService();
  final WakeLockService _wakeLockService = WakeLockService();
  final GlobalAudioManager _globalAudioManager = GlobalAudioManager();
  final MeditationSessionRepository _sessionRepository;
  final MeditationSessionApiRepository _sessionApiRepository;

  MeditationPhase? _phaseBeforePause;
  DateTime? _activeSessionStartedAt;
  bool _hasEnteredActivePhase = false;
  bool _isEnding = false;
  bool _isSpeaking = false;
  // int _nextPromptIndex = 0; // Unused in guided meditation
  // int? _lastPromptSpokenAt; // Unused in guided meditation
  static const double _countdownSpeechRate = 0.4;
  static const double _promptSpeechRate = 0.65;

  Future<void> _initAudio() async {
    try {
      // Background audio context for music/sounds
      final bgContext = AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      );
      await _bgPlayer.setAudioContext(bgContext);
      
      // Bell and tick audio context for alarm-like sounds (audible in DND)
      final alarmContext = AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      );
      await _bellPlayer.setAudioContext(alarmContext);
      await _tickPlayer.setAudioContext(alarmContext);
    } catch (_) {
      // Audio context setup failed, continue anyway
    }

    // Initialize TTS service with user's selected voice
    final settings = _ref.read(settingsProvider);
    await _ttsService.initialize(selectedVoice: settings.selectedTTSVoice);
  }

  // ── Setup actions ──────────────────────────────────────────────────────

  void setStyle(MeditationStyle style) {
    state = state.copyWith(
      style: style,
      virtueName: style == MeditationStyle.affirmation ? state.virtueName : null,
      bibleTemplate: style == MeditationStyle.bible ? state.bibleTemplate : null,
      customBibleVerses:
          style == MeditationStyle.bible ? state.customBibleVerses : null,
      affirmationCategory:
          style == MeditationStyle.affirmation ? state.affirmationCategory : null,
      virtueAffirmation:
          style == MeditationStyle.affirmation ? state.virtueAffirmation : null,
      habitAffirmation:
          style == MeditationStyle.affirmation ? state.habitAffirmation : null,
      chosenChantId: style == MeditationStyle.chant ? state.chosenChantId : null,
    );
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
    _rebuildGuide();
  }

  void setChant(String chantId) {
    state = state.copyWith(chosenChantId: chantId);
    _rebuildGuide();
    _logger.d('Chant set: ${state.chosenChantId}');
  }

  void setCenteringWord(String word) {
    state = state.copyWith(centeringWord: word.trim().isEmpty ? 'Jesus' : word.trim());
    _rebuildGuide();
  }

  void setVirtueName(String? name) {
    state = state.copyWith(virtueName: name);
    _rebuildGuide();
  }

  void setBibleTemplate(BibleTemplate template) {
    state = state.copyWith(
      bibleTemplate: template,
      customBibleVerses: template == BibleTemplate.custom
          ? state.customBibleVerses
          : null,
    );
    _rebuildGuide();
  }

  void setAffirmationCategory(AffirmationCategory category) {
    final defaultVirtue = state.virtueAffirmation ?? VirtueAffirmation.selfControl;
    final defaultHabit = state.habitAffirmation ?? HabitAffirmation.lust;

    state = state.copyWith(
      affirmationCategory: category,
      virtueAffirmation:
          category == AffirmationCategory.growVirtue ? defaultVirtue : null,
      habitAffirmation:
          category == AffirmationCategory.stopHabit ? defaultHabit : null,
      virtueName: category == AffirmationCategory.growVirtue
          ? defaultVirtue.title
          : defaultHabit.title,
    );
    _rebuildGuide();
  }

  void setVirtueAffirmation(VirtueAffirmation affirmation) {
    state = state.copyWith(
      virtueAffirmation: affirmation,
      virtueName: affirmation.title,
    );
    _rebuildGuide();
  }

  void setHabitAffirmation(HabitAffirmation affirmation) {
    state = state.copyWith(
      habitAffirmation: affirmation,
      virtueName: affirmation.title,
    );
    _rebuildGuide();
  }

  void setCustomBibleVerses(String verses) {
    final sanitized = verses.trim();
    state = state.copyWith(
      bibleTemplate: state.bibleTemplate ?? BibleTemplate.custom,
      customBibleVerses: sanitized.isEmpty ? null : sanitized,
    );
    _rebuildGuide();
  }

  // ── Session lifecycle ──────────────────────────────────────────────────

  Future<void> startSession() async {
    if (!state.isReadyToBegin) return;
    if (state.phase == MeditationPhase.countdown ||
        state.phase == MeditationPhase.active) {
      return;
    }

    // Stop any preview audio that might be playing
    await _stopAllAudio();

    // Create guided meditation content
    await _createGuidedContent();
    
    _rebuildGuide();
    _phaseBeforePause = null;
    _activeSessionStartedAt = null;
    _hasEnteredActivePhase = false;

    state = state.copyWith(
      phase: MeditationPhase.countdown,
      countdown: 5,
      elapsedSeconds: 0,
      currentGuidedPhase: GuidedPhase.breathing,
    );

    // DND will be enabled after countdown completes in _beginActivePhase
    _startCountdownTimer();
  }

  /// Create guided meditation content for the current session
  Future<void> _createGuidedContent() async {
    final guidedContent = GuidedMeditationBuilder.build(
      style: state.style,
      totalDurationMinutes: state.selectedMinutes,
      bibleTemplate: state.bibleTemplate,
      affirmationCategory: state.affirmationCategory,
      virtueAffirmation: state.virtueAffirmation,
      habitAffirmation: state.habitAffirmation,
      customBibleVerses: state.customBibleVerses,
      centeringWord: state.centeringWord,
    );

    state = state.copyWith(guidedContent: guidedContent);
    _logger.d('Created guided meditation content for ${state.style}');
  }

  Future<void> _beginActivePhase() async {
    _hasEnteredActivePhase = true;
    _activeSessionStartedAt ??= DateTime.now();
    state = state.copyWith(
      phase: MeditationPhase.active,
      elapsedSeconds: 0,
      currentGuidedPhase: GuidedPhase.breathing,
    );

    // Play start bell sound as session begins
    await _playStartBell();

    // Enable DND and wake lock now that countdown is complete
    await _enableSessionFeatures();

    _startSessionTimer();
    _startBreathCycle();
    _startGuidedPhaseTracking();
    _playBackground();
  }

  /// Start tracking guided meditation phases
  void _startGuidedPhaseTracking() {
    _guidedPhaseTimer?.cancel();
    
    _guidedPhaseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase != MeditationPhase.active || state.guidedContent == null) {
        _guidedPhaseTimer?.cancel();
        return;
      }

      final currentPhase = state.guidedContent!.getCurrentPhase(state.elapsedSeconds);
      if (currentPhase != state.currentGuidedPhase) {
        // Phase has changed, speak transition
        _speakPhaseTransition(currentPhase);
        state = state.copyWith(currentGuidedPhase: currentPhase);
      }
    });
  }

  /// Speak the transition to a new guided phase
  Future<void> _speakPhaseTransition(GuidedPhase newPhase) async {
    final phaseContent = state.guidedContent?.getPhaseContent(newPhase);
    if (phaseContent?.spokenText != null) {
      await _speakPrompt(phaseContent!.spokenText);
    }
  }

  void pause() {
    if (state.phase != MeditationPhase.active &&
        state.phase != MeditationPhase.countdown) {
      return;
    }
    _phaseBeforePause = state.phase;
    _countdownTimer?.cancel();
    _sessionTimer?.cancel();
    _breathTimer?.cancel();
    _promptTimer?.cancel();
    _guidedPhaseTimer?.cancel();
    _bgPlayer.pause();
    state = state.copyWith(phase: MeditationPhase.paused);
  }

  void resume() {
    if (state.phase != MeditationPhase.paused) return;

    if (_phaseBeforePause == MeditationPhase.countdown &&
        state.countdown > 0) {
      state = state.copyWith(phase: MeditationPhase.countdown);
      _startCountdownTimer();
      _phaseBeforePause = null;
      return;
    }

    state = state.copyWith(phase: MeditationPhase.active);
    _startSessionTimer();
    _startBreathCycle();
    _startGuidedPhaseTracking();
    _bgPlayer.resume();
    _phaseBeforePause = null;
  }

  Future<void> endSession() async {
    if (_isEnding || state.phase == MeditationPhase.setup) {
      return;
    }
    _isEnding = true;

    // Extract completion metadata upfront before any state changes
    final phaseAtEnd = state.phase;
    final didEnterActivePhase = _hasEnteredActivePhase;
    final hasCompletableProgress =
        didEnterActivePhase || state.elapsedSeconds > 0;
    final endedAt = DateTime.now();
    final elapsedMinutes = (state.elapsedSeconds + 59) ~/ 60;
    final completedMinutes = elapsedMinutes < 1
        ? 1
        : (elapsedMinutes > state.selectedMinutes
            ? state.selectedMinutes
            : elapsedMinutes);
    
    // Capture session data for background tasks
    final sessionData = {
      'completedMinutes': completedMinutes,
      'style': state.style,
      'virtueName': state.virtueName,
      'startedAt': _activeSessionStartedAt,
      'endedAt': endedAt,
      'hasProgress': hasCompletableProgress,
    };

    try {
      _cancelAllTimers();
      await _stopAllAudio();

      // Transition to complete immediately
      state = state.copyWith(
        phase: MeditationPhase.complete,
        sessionCount: state.sessionCount + (hasCompletableProgress ? 1 : 0),
        elapsedSeconds: hasCompletableProgress
            ? state.elapsedSeconds
            : (phaseAtEnd == MeditationPhase.countdown ? 0 : state.elapsedSeconds),
      );

      // Run background tasks without blocking
      if (hasCompletableProgress) {
        unawaited(_runBackgroundCompletionTasks(sessionData));
      }

      // Disable DND and wake lock when session ends
      await _disableSessionFeatures();

      _phaseBeforePause = null;
      _activeSessionStartedAt = null;
      _hasEnteredActivePhase = false;
      _logger.d('Complete phase set. Current phase: ${state.phase}');
    } finally {
      _isEnding = false;
    }
  }

  Future<void> resetToSetup() async {
    _cancelAllTimers();
    await _stopAllAudio();
    
    // Disable DND and wake lock when resetting to setup
    await _disableSessionFeatures();
    
    state = state.copyWith(
      phase: MeditationPhase.setup,
      countdown: 5,
      elapsedSeconds: 0,
      breathPhase: BreathPhase.breathIn,
    );
    _phaseBeforePause = null;
    _activeSessionStartedAt = null;
    _hasEnteredActivePhase = false;
  }

  Future<void> startQuickAffirmation(VirtueType virtue) async {
    await resetToSetup();
    setStyle(MeditationStyle.affirmation);
    setAffirmationCategory(AffirmationCategory.growVirtue);
    setSelectedMinutes(1);
    final affirmation = _mapVirtueToAffirmation(virtue);
    setVirtueAffirmation(affirmation);
    setVirtueName(affirmation.title);
    await startSession();
  }

  // ── Audio Management ─────────────────────────────────────────────────────

  /// Play start bell sound when meditation begins
  Future<void> _playStartBell() async {
    try {
      await _bellPlayer.play(AssetSource('audio/bell-meditation.mp3'));
    } catch (e) {
      await _bellPlayer.play(AssetSource('audio/bell-meditation.mp3'));
    }
  }

  /// Play countdown tick sound and voice
  Future<void> _playCountdownTick(int number) async {
    try {
      await Future.delayed(const Duration(milliseconds: 120));
      // Play tick sound first
      await _tickPlayer.play(AssetSource('audio/tick-tock.wav'));
      
      // Then speak the number with a slight delay
      if (number > 0) {
        await Future.delayed(const Duration(milliseconds: 320));
        await _speakCountdownNumber(number);
      }
    } catch (e) {
      _logger.w('Failed to play countdown tick: $e');
      // Still try to speak the number even if sound fails
      if (number > 0) {
        await _speakCountdownNumber(number);
      }
    }
  }

  /// Speak countdown number
  Future<void> _speakCountdownNumber(int number) async {
    try {
      await _ttsService.speak(number.toString(), speechRate: _countdownSpeechRate);
    } catch (e) {
      _logger.w('Failed to speak countdown number: $e');
    }
  }

  /// Play final countdown with bells when meditation ends
  // Future<void> _playFinalCountdown() async {
  //   // Stop any remaining background audio first
  //   await _bgPlayer.stop();
  //   
  //   // Play 3-2-1 countdown with bells and voice
  //   for (int i = 3; i >= 1; i--) {
  //     try {
  //       // Play meditation bell for each number
  //       await _bellPlayer.play(AssetSource('audio/bell-meditation.mp3'));
  //       await Future.delayed(const Duration(milliseconds: 800));
  //       
  //       // Speak the number
  //       await _speakCountdownNumber(i);
  //       await Future.delayed(const Duration(milliseconds: 1200));
  //     } catch (e) {
  //       _logger.w('Failed to play final countdown number $i: $e');
  //       // Continue with next number even if one fails
  //     }
  //   }
  //   
  //   // Play final completion bell
  //   try {
  //     await Future.delayed(const Duration(milliseconds: 500));
  //     await _bellPlayer.play(AssetSource('audio/success_bell.mp3'));
  //   } catch (e) {
  //     _logger.w('Failed to play completion bell: $e');
  //   }
  // }

  /// Speak a meditation prompt using TTS with audio ducking
  Future<void> _speakPrompt(String text) async {
    if (_isSpeaking) return; // Skip if already speaking
    
    try {
      _isSpeaking = true;
      
      // Duck background audio for TTS
      if (state.style != MeditationStyle.chant) {
        await _bgPlayer.setVolume(0.2);
      }
      
      await _ttsService.speak(text, speechRate: _promptSpeechRate);
      _logger.d('Speaking prompt: $text');
      
      // Restore background volume after TTS completes
      Future.delayed(const Duration(seconds: 4), () async {
        _isSpeaking = false;
        if (state.style != MeditationStyle.chant) {
          await _bgPlayer.setVolume(0.4);
        }
      });
    } catch (e) {
      _logger.e('Failed to speak prompt: $e');
      _isSpeaking = false;
      // Restore volume on error
      if (state.style != MeditationStyle.chant) {
        await _bgPlayer.setVolume(0.4);
      }
    }
  }

  /// Start periodic prompts during meditation
  // void _startPromptTimer() {
  //   _promptTimer?.cancel();

  //   // Avoid overlaying TTS prompts on chant audio playback.
  //   if (state.style == MeditationStyle.chant) return;
    
  //   // Only start prompts for sessions longer than 5 minutes
  //   if (state.totalSeconds < 300) return;
    
  //   // Reset prompt tracking for new session
  //   _nextPromptIndex = 0;
  //   _lastPromptSpokenAt = null;
    
  //   // Use fixed intervals: first prompt at 2 minutes, then every 3 minutes
  //   _promptTimer = Timer.periodic(const Duration(seconds: 3 * 60), (_) {
  //     if (state.phase == MeditationPhase.active) {
  //       _checkAndSpeakPrompt();
  //     }
  //   });
  // }

  /// Check if it's time to speak the next prompt
  // void _checkAndSpeakPrompt() {
  //   final now = DateTime.now().millisecondsSinceEpoch;
  //   final elapsedSeconds = state.elapsedSeconds;
    
  //   // Skip if already speaking
  //   if (_isSpeaking) return;
    
  //   // First prompt at 2 minutes (120 seconds)
  //   if (_lastPromptSpokenAt == null && elapsedSeconds >= 120) {
  //     _speakNextPrompt();
  //     return;
  //   }
    
  //   // Subsequent prompts every 3 minutes after the first
  //   if (_lastPromptSpokenAt != null) {
  //     final timeSinceLastPrompt = (now - _lastPromptSpokenAt!) / 1000;
  //     if (timeSinceLastPrompt >= 3 * 60) {
  //       _speakNextPrompt();
  //     }
  //   }
  // }

  /// Speak the next prompt from the guide with better timing
  // void _speakNextPrompt() {
  //   final prompts = state.guide?.prompts;
  //   if (prompts == null || prompts.isEmpty) return;
    
  //   // Use monotonic progression to prevent regression
  //   final promptIndex = _nextPromptIndex.clamp(0, prompts.length - 1);
  //   final prompt = prompts[promptIndex];
    
  //   _lastPromptSpokenAt = DateTime.now().millisecondsSinceEpoch;
  //   _nextPromptIndex = (_nextPromptIndex + 1) % prompts.length;
    
  //   _speakPrompt(prompt);
  // }

  /// Stop all audio players to prevent conflicts
  Future<void> _stopAllAudio() async {
    try {
      await _bgPlayer.stop();
      await _bellPlayer.stop();
      await _tickPlayer.stop();
      await _audioService.stop();
      
      // Also stop any preview audio that might be playing
      await _globalAudioManager.stopAllAudio();
      
      _logger.d('All audio stopped');
    } catch (e) {
      _logger.e('Error stopping audio: $e');
    }
  }

  // ── Session Features (DND & Wake Lock) ───────────────────────────────────

  /// Enable DND and wake lock for meditation session
  Future<void> _enableSessionFeatures() async {
    var dndStatus = DndStatus.unsupported;
    try {
      if (_dndService.isSupported) {
        // Use priority DND to allow meditation audio cues while blocking other interruptions
        final dndSuccess = await _dndService.enablePriorityDnd();
        dndStatus = dndSuccess ? DndStatus.enabled : DndStatus.failed;
        if (dndSuccess) {
          _logger.i('Priority DND mode enabled for meditation');
        } else {
          _logger.w('Failed to enable priority DND mode');
        }
      }

      final wakeLockSuccess = await _wakeLockService.enableWakeLock();
      if (wakeLockSuccess) {
        _logger.i('Wake lock enabled for meditation');
      } else {
        _logger.w('Failed to enable wake lock');
      }
    } catch (e) {
      dndStatus = _dndService.isSupported ? DndStatus.failed : DndStatus.unsupported;
      _logger.e('Error enabling session features: $e');
    } finally {
      if (mounted) {
        state = state.copyWith(dndStatus: dndStatus);
      }
    }
  }

  /// Disable DND and wake lock when session ends
  Future<void> _disableSessionFeatures() async {
    try {
      // Disable DND mode
      final disabled = await _dndService.disableDnd();
      if (disabled) {
        _logger.d('DND mode disabled');
      } else {
        _logger.w('Failed to disable DND mode');
      }

      // Disable wake lock
      await _wakeLockService.disableWakeLock();
      _logger.d('Wake lock disabled');
    } catch (e) {
      _logger.e('Error disabling session features: $e');
    } finally {
      if (mounted) {
        state = state.copyWith(dndStatus: DndStatus.unknown);
      }
    }
  }

  // ── Internal timers ────────────────────────────────────────────────────

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (state.phase != MeditationPhase.countdown) {
        _countdownTimer?.cancel();
        _countdownTimer = null;
        return;
      }

      if (state.countdown <= 1) {
        _countdownTimer?.cancel();
        _countdownTimer = null;
        await _beginActivePhase();
      } else {
        final nextCountdown = state.countdown - 1;
        state = state.copyWith(countdown: nextCountdown);
        await _playCountdownTick(nextCountdown);
      }
    });
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.elapsedSeconds + 1;
      if (next >= state.totalSeconds) {
        // Don't update elapsed time when session completes - let endSession handle it
        _sessionTimer?.cancel();
        _sessionTimer = null;
        unawaited(endSession());
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
      bibleTemplate: state.bibleTemplate,
      affirmationCategory: state.affirmationCategory,
      virtueAffirmation: state.virtueAffirmation,
      habitAffirmation: state.habitAffirmation,
      customBibleVerses: state.customBibleVerses,
    );
    state = state.copyWith(guide: guide);
  }


  String? _currentBibleLabel() {
    if (state.bibleTemplate == null) return null;
    if (state.bibleTemplate == BibleTemplate.custom) {
      if ((state.customBibleVerses ?? '').isEmpty) return 'Custom Verses';
      return 'Custom Verses';
    }
    return state.bibleTemplate!.label;
  }

  String? _sessionFocusLabel() {
    if (state.style == MeditationStyle.affirmation) {
      if (state.affirmationCategory == AffirmationCategory.growVirtue) {
        return state.virtueAffirmation?.title;
      }
      if (state.affirmationCategory == AffirmationCategory.stopHabit) {
        return state.habitAffirmation?.title;
      }
    }
    if (state.style == MeditationStyle.bible) {
      return _currentBibleLabel();
    }
    return state.style == MeditationStyle.chant ? 'Chant' : null;
  }

  VirtueAffirmation _mapVirtueToAffirmation(VirtueType virtue) {
    switch (virtue) {
      case VirtueType.humility:
        return VirtueAffirmation.humility;
      case VirtueType.love:
        return VirtueAffirmation.compassion;
      case VirtueType.faith:
        return VirtueAffirmation.faithfulness;
      case VirtueType.knowledge:
        return VirtueAffirmation.selfControl;
    }
  }

  VirtueType _sessionVirtueType() {
    switch (state.style) {
      case MeditationStyle.quietReflection:
        return VirtueType.faith;
      case MeditationStyle.bible:
        return VirtueType.knowledge;
      case MeditationStyle.affirmation:
        return state.affirmationCategory == AffirmationCategory.growVirtue
            ? VirtueType.love
            : VirtueType.faith;
      case MeditationStyle.chant:
        return VirtueType.faith;
    }
  }

  void _cancelAllTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _breathTimer?.cancel();
    _breathTimer = null;
    _promptTimer?.cancel();
    _promptTimer = null;
    _guidedPhaseTimer?.cancel();
    _guidedPhaseTimer = null;
  }

  Future<void> _playBackground() async {
    // Handle chant mode separately
    if (state.style == MeditationStyle.chant) {
      await _playChantAudio();
      return;
    }
    
    final sound = state.backgroundSound;
    if (sound == BackgroundSound.silent) {
      _logger.d('Background sound set to silent');
      return;
    }
    
    final filename = switch (sound) {
      BackgroundSound.ambient => 'ambient.mp3',
      BackgroundSound.heartbeat => 'heartbeat.mp3',
      BackgroundSound.silent => '', // Should not reach here due to early return
    };
    
    if (filename.isEmpty) return;
    
    _logger.d('Playing background sound: $filename');

    try {
      // playBackgroundSound handles download, validation, and fallbacks internally
      await _audioService.playBackgroundSound(filename);
      _logger.i('Background sound started: $filename');
    } catch (e) {
      _logger.e('Failed to play background sound: $e');
      _handleAudioError('Background sound', 'Unable to play background audio');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _sessionTimer?.cancel();
    _breathTimer?.cancel();
    _promptTimer?.cancel();
    _bgPlayer.dispose();
    _bellPlayer.dispose();
    _tickPlayer.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  // ── Chant audio handling with fallback ───────────────────────────────────────

  Future<void> _playChantAudio() async {
    if (state.chosenChantId == null) {
      _logger.w('No chant ID selected');
      return;
    }
    
    final chant = ChantTracks.getById(state.chosenChantId);
    if (chant == null) {
      _logger.e('Chant not found: ${state.chosenChantId}');
      _handleAudioError('Chant lookup', 'Chant not found');
      return;
    }
    
    _logger.d('Attempting to play chant: ${chant.label}');
    
    // Try voice first, then instrumental as fallback
    final audioSources = [
      {'key': chant.voiceKey, 'type': 'voice'},
      {'key': chant.instrumentalKey, 'type': 'instrumental'},
    ].where((source) => source['key'] != null).toList();
    
    for (final source in audioSources) {
      final audioKey = source['key']!;
      final type = source['type']!;
      
      try {
        final filename = audioKey.split('/').last;
        _logger.d('Trying $type chant: $audioKey');
        
        // Try streaming first for instant playback
        if (audioKey.startsWith('http')) {
          try {
            await _audioService.playChant(
              audioKey,
              filename,
              loop: true,
              volume: 0.7,
            );
            _logger.i('Playing chant: ${chant.label} ($type)');
            return; // Success
          } catch (e) {
            _logger.w('Failed to play $type chant from $audioKey: $e');
            continue; // Try next source
          }
        } else {
          // Asset file
          await _audioService.playChant(
            audioKey,
            filename,
            loop: true,
            volume: 0.7,
          );
          _logger.i('Playing chant: ${chant.label} ($type)');
          return; // Success
        }
      } catch (e) {
        _logger.w('Failed to play $type chant: $e');
        continue; // Try next source
      }
    }
    
    // All attempts failed
    _logger.e('All chant audio sources failed for: ${chant.label}');
    _handleAudioError('Chant playback', 'Unable to play chant audio');
  }

  /// Handle audio errors with appropriate logging and user feedback
  void _handleAudioError(String operation, String error) {
    _logger.e('Audio error during $operation: $error');
    
    // Only show user-facing errors for critical failures
    if (operation.contains('chant') || operation.contains('background')) {
      _showUserNotification('Audio Issue', '$operation failed');
    }
  }

  /// Show user notification for audio issues
  ///
  /// Note: This is intentionally log-only since the notifier doesn't have
  /// access to BuildContext for showing SnackBars. Audio issues are rare
  /// edge cases, and the meditation UI already shows session state clearly.
  /// If needed, the screen can add error handling callbacks.
  void _showUserNotification(String title, String message) {
    _logger.i('User notification: $title - $message');
  }

  /// Run background completion tasks without blocking UI
  Future<void> _runBackgroundCompletionTasks(Map<String, dynamic> sessionData) async {
    try {
      final completedMinutes = sessionData['completedMinutes'] as int;
      final style = sessionData['style'] as MeditationStyle;
      final virtueName = sessionData['virtueName'] as String?;
      final startedAt = sessionData['startedAt'] as DateTime?;
      final endedAt = sessionData['endedAt'] as DateTime;

      // Add XP for completed meditation
      await XPService.instance.addXP(
        type: XPActivityType.meditation,
        description: 'Completed $completedMinutes-minute ${style.label} meditation',
        metadata: {
          'duration_minutes': completedMinutes,
          'style': style.name,
          'virtue_focus': virtueName,
        },
      );

      // Save session to local repository
      String title = '$completedMinutes Min ${style.label}';
      if (style == MeditationStyle.chant && state.chosenChantId != null) {
        final chant = ChantTracks.getById(state.chosenChantId);
        if (chant != null) {
          title = '$completedMinutes Min Chant: ${chant.label}';
        }
      }

      final virtueType = _sessionVirtueType();
      final session = MeditationSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: style.description,
        durationMinutes: completedMinutes,
        guided: style != MeditationStyle.quietReflection,
        audioUrl: '', // Could map background sound here
        virtueType: virtueType,
        completedCount: 1,
        // Store complete configuration for session restoration
        style: style,
        backgroundSound: state.backgroundSound,
        breathPace: state.breathPace,
        centeringWord: state.centeringWord,
        virtueName: state.virtueName,
        chosenChantId: state.chosenChantId,
        bibleTemplate: state.bibleTemplate,
        affirmationCategory: state.affirmationCategory,
        virtueAffirmation: state.virtueAffirmation,
        habitAffirmation: state.habitAffirmation,
        customBibleVerses: state.customBibleVerses,
      );

      await _sessionRepository.saveSession(session);

      // Sync to API
      await _sessionApiRepository.createSession(
        durationMinutes: completedMinutes,
        virtue: _sessionFocusLabel() ?? style.label,
        startedAt: startedAt,
        endedAt: endedAt,
      );

      _logger.d('Background completion tasks finished successfully');
    } catch (e) {
      _logger.e('Error in background completion tasks: $e');
    }
  }
}

final meditationProvider =
    StateNotifierProvider<MeditationNotifier, MeditationState>((ref) {
  return MeditationNotifier(
    sessionRepository: ref.watch(meditationSessionRepositoryProvider),
    sessionApiRepository: ref.watch(meditationSessionApiRepositoryProvider),
    ref: ref,
  );
});
