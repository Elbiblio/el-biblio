import 'dart:io';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class ImprovedAudioService {
  final Logger _logger = Logger();
  final SoLoud _soloud;
  
  // Store active sound handles for management
  SoundHandle? _currentHandle;
  AudioSource? _currentSource;
  
  ImprovedAudioService() : _soloud = SoLoud.instance {
    _logger.d('Audio service initialized on platform: ${Platform.operatingSystem}');
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await _soloud.init();
      _logger.d('SoLoud audio engine initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize SoLoud audio engine: $e');
    }
  }

  Future<String> _getAudioDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/meditation_sounds');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir.path;
  }

  Future<String> _getChantDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final chantDir = Directory('${directory.path}/meditation_chants');
    if (!await chantDir.exists()) {
      await chantDir.create(recursive: true);
    }
    return chantDir.path;
  }

  Future<String> _getAudioPath(String filename, {bool isChant = false}) async {
    final dir = isChant ? await _getChantDir() : await _getAudioDir();
    return '$dir/$filename';
  }

  Future<bool> _isAudioDownloaded(String filename, {bool isChant = false}) async {
    final path = await _getAudioPath(filename, isChant: isChant);
    return await File(path).exists();
  }

  Future<bool> downloadAudio(String url, String filename, {bool isChant = false, Function(int, int)? onProgress}) async {
    try {
      _logger.d('Starting download: $filename from $url');
      
      final dio = Dio();
      final filePath = await _getAudioPath(filename, isChant: isChant);
      
      _logger.d('Download path: $filePath');
      
      await dio.download(
        url,
        filePath,
        onReceiveProgress: onProgress,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://elbiblio.com/',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      _logger.i('Download completed successfully: $filename');
      dio.close();
      
      // Verify the downloaded file
      final file = File(filePath);
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Downloaded audio file is empty or missing');
      }
      
      _logger.i('Audio downloaded successfully: $filename (${await file.length()} bytes)');
      return true;
    } catch (e) {
      _logger.e('Failed to download audio: $e');
      return false;
    }
  }

  Future<bool> playLocalAudio(String filename, {bool isChant = false}) async {
    try {
      final path = await _getAudioPath(filename, isChant: isChant);
      _logger.d('Playing local audio: $path');
      
      if (!await File(path).exists()) {
        _logger.e('Local audio file not found: $path');
        return false;
      }
      
      // Stop current playback if any
      await stop();
      
      // Load and play the local file
      _currentSource = await _soloud.loadFile(path);
      _currentHandle = await _soloud.play(_currentSource!);
      
      _logger.i('Local audio playback started: $filename');
      return true;
    } catch (e) {
      _logger.e('Failed to play local audio: $e');
      return false;
    }
  }

  Future<bool> playStreamingAudio(String url, {bool loop = false}) async {
    try {
      _logger.d('Playing streaming audio: $url');
      
      // Stop current playback if any
      await stop();
      
      // Load and play from URL with optimized settings for instant playback
      _currentSource = await _soloud.loadUrl(url);
      _currentHandle = await _soloud.play(_currentSource!);
      
      // Set volume slightly lower for streaming to reduce initial load
      _soloud.setVolume(_currentHandle!, 0.8);
      
      if (loop) {
        _soloud.setLooping(_currentHandle!, true);
      }
      
      _logger.i('Streaming audio started successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to play streaming audio: $e');
      return false;
    }
  }

  // Preload chant audio for instant playback
  Future<AudioSource?> preloadChant(String url) async {
    try {
      _logger.d('Preloading chant: $url');
      
      // For asset files, preload directly
      if (url.startsWith('assets/')) {
        return await _soloud.loadAsset(url);
      }
      
      // For remote URLs, preload the beginning for faster start
      return await _soloud.loadUrl(url);
    } catch (e) {
      _logger.e('Failed to preload chant: $e');
      return null;
    }
  }

  // Play preloaded chant instantly
  Future<bool> playPreloadedChant(AudioSource source, {bool loop = false}) async {
    try {
      _logger.d('Playing preloaded chant');
      
      // Stop current playback if any
      await stop();
      
      _currentSource = source;
      _currentHandle = await _soloud.play(_currentSource!);
      
      if (loop) {
        _soloud.setLooping(_currentHandle!, true);
      }
      
      _logger.i('Preloaded chant playback started successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to play preloaded chant: $e');
      return false;
    }
  }

  Future<bool> playChant(
    String urlOrAsset,
    String filename, {
    bool isVoice = true,
    bool loop = false,
  }) async {
    try {
      _logger.d('Playing chant: $filename (${isVoice ? "voice" : "instrumental"}) from: $urlOrAsset');
      
      // Check if it's an asset path
      if (urlOrAsset.startsWith('assets/')) {
        try {
          _logger.d('Playing chant from asset: $urlOrAsset');
          
          // Stop current playback if any
          await stop();
          
          // Load and play the asset
          _currentSource = await _soloud.loadAsset(urlOrAsset);
          _currentHandle = await _soloud.play(_currentSource!);

          if (loop) {
            _soloud.setLooping(_currentHandle!, true);
          }
          
          _logger.d('Asset playback successful');
          return true;
        } catch (e) {
          _logger.e('Failed to play chant from asset: $e');
          return false;
        }
      }
      
      // Try local file first
      if (await _isAudioDownloaded(filename, isChant: true)) {
        _logger.d('Found local file, playing from cache: $filename');
        return await playLocalAudio(filename, isChant: true);
      }
      
      _logger.d('No local file found, trying remote playback for: $urlOrAsset');
      
      // Download and play (for remote URLs)
      if (urlOrAsset.startsWith('http')) {
        _logger.d('Attempting download and play for remote URL');
        final downloaded = await downloadAudio(urlOrAsset, filename, isChant: true);
        if (downloaded) {
          _logger.d('Download successful, playing local file');
          return await playLocalAudio(filename, isChant: true);
        }
        
        _logger.d('Download failed, trying streaming fallback');
        // Fallback to streaming
        return await playStreamingAudio(urlOrAsset, loop: loop);
      }
      
      _logger.e('Invalid chant source: $urlOrAsset');
      return false;
    } catch (e) {
      _logger.e('Failed to play chant: $e');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      if (_currentHandle != null) {
        await _soloud.stop(_currentHandle!);
        _currentHandle = null;
      }
      
      if (_currentSource != null) {
        await _soloud.disposeSource(_currentSource!);
        _currentSource = null;
      }
      
      _logger.d('Audio stopped');
    } catch (e) {
      _logger.e('Failed to stop audio: $e');
    }
  }

  Future<void> pause() async {
    try {
      if (_currentHandle != null) {
        _soloud.setPause(_currentHandle!, true);
        _logger.d('Audio paused');
      }
    } catch (e) {
      _logger.e('Failed to pause audio: $e');
    }
  }

  Future<void> resume() async {
    try {
      if (_currentHandle != null) {
        _soloud.setPause(_currentHandle!, false);
        _logger.d('Audio resumed');
      }
    } catch (e) {
      _logger.e('Failed to resume audio: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      if (_currentHandle != null) {
        _soloud.setVolume(_currentHandle!, volume);
        _logger.d('Volume set to: $volume');
      }
    } catch (e) {
      _logger.e('Failed to set volume: $e');
    }
  }

  bool get isPlaying {
    if (_currentHandle == null) return false;
    try {
      return _soloud.getActiveVoiceCount() > 0 && 
             !_soloud.getPause(_currentHandle!);
    } catch (e) {
      _logger.e('Failed to check playing state: $e');
      return false;
    }
  }

  // Audio session management
  Future<bool> requestAudioFocus() async {
    try {
      // SoLoud handles audio focus automatically on most platforms
      return true;
    } catch (e) {
      _logger.e('Failed to request audio focus: $e');
      return false;
    }
  }

  Future<void> dispose() async {
    try {
      await stop();
      // SoLoud doesn't have a dispose method in the same way
      // Just clean up our resources
      _logger.d('Audio service disposed');
    } catch (e) {
      _logger.e('Failed to dispose audio service: $e');
    }
  }
}