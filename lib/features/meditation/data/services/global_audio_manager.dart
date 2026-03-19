import 'dart:async';
import 'package:logger/logger.dart';
import 'improved_audio_service.dart';

/// Global audio manager to prevent multiple audio streams from playing simultaneously
class GlobalAudioManager {
  static final GlobalAudioManager _instance = GlobalAudioManager._internal();
  factory GlobalAudioManager() => _instance;
  GlobalAudioManager._internal();

  final Logger _logger = Logger();
  ImprovedAudioService? _currentAudioService;
  final StreamController<void> _stoppedController = StreamController<void>.broadcast();

  Stream<void> get onAudioStopped => _stoppedController.stream;
  
  /// Get the current active audio service or create a new one
  ImprovedAudioService getAudioService() {
    _currentAudioService ??= ImprovedAudioService();
    return _currentAudioService!;
  }

  /// Stop all audio and dispose of current service
  Future<void> stopAllAudio() async {
    if (_currentAudioService == null) return;

    try {
      await _currentAudioService!.stop();
      _logger.d('Stopped all preview audio');
    } catch (e) {
      _logger.e('Error stopping preview audio: $e');
    } finally {
      await _currentAudioService!.dispose();
      _currentAudioService = null;
      if (!_stoppedController.isClosed) {
        _stoppedController.add(null);
      }
    }
  }

  /// Dispose of the current audio service
  Future<void> dispose() async {
    if (_currentAudioService != null) {
      await _currentAudioService!.dispose();
      _currentAudioService = null;
    }
    await _stoppedController.close();
  }

  /// Check if any audio is currently playing
  bool get isPlaying => _currentAudioService?.isPlaying ?? false;
}
