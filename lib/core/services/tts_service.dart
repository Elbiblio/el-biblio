import 'dart:io';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as path;
import '../network/dio_client.dart';

/// Hybrid TTS Service using Fish Audio API with flutter_tts fallback
/// 1. Fish Audio API (cloud TTS with 3 voice options - online, proxied through backend)
/// 2. System TTS (flutter_tts - offline fallback)
/// 3. Pre-recorded audio files (final fallback)
class TTSService {
  late final DioClient _dioClient;
  late final AudioPlayer _audioPlayer;
  late final FlutterTts _flutterTts;
  final Logger _logger = Logger();
  
  String? _selectedVoice;
  bool _isInitialized = false;
  bool _useOfflineMode = false;
  Directory? _cacheDir;

  TTSService() {
    _dioClient = DioClient(Logger());
    _audioPlayer = AudioPlayer();
    _flutterTts = FlutterTts();
  }

  // Fish Audio voice options
  static const Map<String, String> _fishVoices = {
    'default': '3ad4d432023c47ee9e6c7805b973630a',
    'alternative1': '051eccd6d8894155a0c544b8e5c0fd72',
    'alternative2': 'b347db033a6549378b48d00acb0d06cd',
  };
  
  // Cache for TTS audio files
  final Map<String, String> _audioCache = {};
  String _currentVoice = 'default';

  /// Initialize TTS service with connectivity check and offline fallback
  Future<void> initialize({String? selectedVoice}) async {
    if (_isInitialized) return;

    try {
      // Get cache directory
      _cacheDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(path.join(_cacheDir!.path, 'tts_cache'));
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _useOfflineMode = connectivityResult.contains(ConnectivityResult.none);
      
      if (!_useOfflineMode) {
        // Initialize Fish Audio API (online mode)
        _selectedVoice = selectedVoice ?? 'default';
        _currentVoice = _selectedVoice!;
        _logger.i('TTS initialized in online mode with Fish Audio API');
      } else {
        // Initialize flutter_tts (offline mode)
        await _initializeOfflineTTS();
        _logger.i('TTS initialized in offline mode with flutter_tts');
      }

      _isInitialized = true;
    } catch (e) {
      _logger.e('Failed to initialize TTS: $e');
      // Fall back to offline mode if online initialization fails
      await _initializeOfflineTTS();
      _useOfflineMode = true;
      _isInitialized = true;
    }
  }

  /// Initialize offline TTS using flutter_tts
  Future<void> _initializeOfflineTTS() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.setVolume(0.7);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      _logger.w('Failed to initialize offline TTS: $e');
      // Will fall back to pre-recorded audio
    }
  }

  /// Update voice selection
  void setVoice(String voiceKey) {
    if (_fishVoices.containsKey(voiceKey)) {
      _currentVoice = voiceKey;
      _logger.i('TTS voice changed to: $_currentVoice');
      // Clear cache when voice changes
      clearCache();
    } else {
      _logger.w('Invalid voice key: $voiceKey');
    }
  }

  /// Get available voices
  Map<String, String> getAvailableVoices() {
    return Map.from(_fishVoices);
  }

  /// Get current voice key
  String getCurrentVoice() {
    return _currentVoice;
  }

  /// Speak text using hybrid TTS approach
  Future<bool> speak(
    String text, {
    double speechRate = 0.8,
    double volume = 0.7,
    bool isBibleVerse = false,
  }) async {
    if (!_isInitialized) {
      _logger.w('TTS not initialized, calling initialize()');
      await initialize();
    }

    try {
      if (_useOfflineMode) {
        return await _speakOffline(text, speechRate, volume, isBibleVerse);
      } else {
        final success = await _speakOnline(text, speechRate, volume, isBibleVerse);
        if (!success) {
          // Online failed without throwing — try offline before giving up
          return await _speakOffline(text, speechRate, volume, isBibleVerse);
        }
        return success;
      }
    } catch (e) {
      _logger.e('TTS failed, trying offline fallback: $e');
      try {
        return await _speakOffline(text, speechRate, volume, isBibleVerse);
      } catch (_) {
        return await _fallbackToPreRecorded(text, isBibleVerse);
      }
    }
  }

  /// Speak using Fish Audio API (online, proxied through backend)
  Future<bool> _speakOnline(
    String text,
    double speechRate,
    double volume,
    bool isBibleVerse,
  ) async {
    try {
      final cacheKey = _getCacheKey(text, _currentVoice, isBibleVerse);
      final cachedFile = await _getCachedAudio(cacheKey);
      
      if (cachedFile != null) {
        await _audioPlayer.play(DeviceFileSource(cachedFile.path));
        return true;
      }

      final referenceId = _fishVoices[_currentVoice]!;
      
      // Call backend proxy endpoint instead of direct Fish Audio API
      final response = await _dioClient.post(
        '/tts/generate',
        data: {
          'text': text,
          'reference_id': referenceId,
          'format': 'mp3',
          'voice': _currentVoice,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Backend should return the audio data (base64 encoded or binary)
        final audioData = response.data['audio_data'];
        List<int> audioBytes;
        
        if (audioData is String) {
          // Base64 encoded audio
          audioBytes = base64.decode(audioData);
        } else if (audioData is List) {
          // Already decoded bytes
          audioBytes = List<int>.from(audioData);
        } else {
          _logger.w('Invalid audio data format from backend');
          return false;
        }
        
        final audioFile = await _cacheAudio(cacheKey, audioBytes);
        _audioCache[cacheKey] = audioFile.path;

        // Play the audio
        await _audioPlayer.play(DeviceFileSource(audioFile.path));
        _logger.i('Generated and played Fish Audio via backend: $text');
        return true;
      } else {
        _logger.w('Backend TTS API returned error: ${response.statusCode} - ${response.data}');
        return false;
      }
    } catch (e) {
      _logger.w('Backend TTS failed: $e');
      // If backend API is not available (404), fall back to offline mode
      if (e.toString().contains('404') || e.toString().contains('NotFoundHttpException')) {
        _logger.i('Backend TTS API not found, switching to offline mode');
        _useOfflineMode = true;
        await _initializeOfflineTTS();
        return await _speakOffline(text, speechRate, volume, isBibleVerse);
      }
      return false;
    }
  }

  /// Speak using flutter_tts (offline)
  Future<bool> _speakOffline(
    String text,
    double speechRate,
    double volume,
    bool isBibleVerse,
  ) async {
    try {
      await _flutterTts.setSpeechRate(speechRate);
      await _flutterTts.setVolume(volume);
      
      final result = await _flutterTts.speak(text);
      return result == 1; // flutter_tts returns 1 for success
    } catch (e) {
      _logger.w('Offline TTS failed: $e');
      return await _fallbackToPreRecorded(text, isBibleVerse);
    }
  }

  /// Generate cache key for audio files
  String _getCacheKey(String text, String voice, bool isBibleVerse) {
    final prefix = isBibleVerse ? 'bible' : 'tts';
    final content = '$prefix:$voice:$text';
    return sha256.convert(utf8.encode(content)).toString();
  }

  /// Get cached audio file if exists
  Future<File?> _getCachedAudio(String cacheKey) async {
    final filePath = path.join(_cacheDir!.path, '$cacheKey.mp3');
    final file = File(filePath);
    
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Cache audio data to file
  Future<File> _cacheAudio(String cacheKey, List<int> audioData) async {
    final filePath = path.join(_cacheDir!.path, '$cacheKey.mp3');
    final file = File(filePath);
    await file.writeAsBytes(audioData);
    return file;
  }

  /// Get pre-recorded asset path for common phrases
  String? _getPreRecordedAssetPath(String text, bool isBibleVerse) {
    // Map common phrases to pre-recorded audio files
    final audioMap = <String, String>{
      '1': 'audio/countdown/1.mp3',
      '2': 'audio/countdown/2.mp3',
      '3': 'audio/countdown/3.mp3',
      '4': 'audio/countdown/4.mp3',
      '5': 'audio/countdown/5.mp3',
      '6': 'audio/countdown/6.mp3',
      '7': 'audio/countdown/7.mp3',
      '8': 'audio/countdown/8.mp3',
      '9': 'audio/countdown/9.mp3',
      '10': 'audio/countdown/10.mp3',
      'Begin your meditation': 'audio/prompts/begin_meditation.mp3',
      'Focus on your breath': 'audio/prompts/focus_breath.mp3',
      'Return to awareness': 'audio/prompts/return_awareness.mp3',
    };

    return audioMap[text];
  }

  /// Fallback to pre-recorded audio files
  Future<bool> _fallbackToPreRecorded(String text, bool isBibleVerse) async {
    try {
      // Try to find matching pre-recorded audio
      final assetPath = _getPreRecordedAssetPath(text, isBibleVerse);
      if (assetPath != null) {
        await _audioPlayer.play(AssetSource(assetPath));
        return true;
      }
      
      _logger.w('No pre-recorded audio found for: $text');
      return false;
    } catch (e) {
      _logger.e('Pre-recorded audio failed: $e');
      return false;
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      _logger.w('Failed to stop TTS: $e');
    }
  }

  /// Clear audio cache
  Future<void> clearCache() async {
    for (final filePath in _audioCache.values) {
      try {
        await File(filePath).delete();
      } catch (e) {
        _logger.w('Failed to delete cached file: $filePath');
      }
    }
    _audioCache.clear();
    _logger.i('TTS cache cleared');
  }

  /// Get cache size information
  Map<String, dynamic> getCacheInfo() {
    final cacheSize = _audioCache.length;
    return {
      'cached_items': cacheSize,
      'current_voice': _currentVoice,
      'available_voices': _fishVoices.keys.toList(),
    };
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    clearCache();
  }
}
