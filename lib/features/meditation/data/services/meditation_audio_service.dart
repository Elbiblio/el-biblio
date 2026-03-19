import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class MeditationAudioService {
  final Logger _logger = Logger();
  final AudioPlayer _player;
  
  static const String _baseUrl = 'https://api.elbiblio.com/sounds/';
  
  MeditationAudioService(this._player);

  AudioPlayer get player => _player;

  // Check network connectivity
  Future<bool> _isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _logger.e('Network connectivity check failed: $e');
      return false;
    }
  }

  // Test audio availability with fallback hierarchy
  Future<Map<String, bool>> testAudioAvailability(String filename) async {
    final results = <String, bool>{};
    
    // Test local file
    final localPath = await _getAudioPath(filename);
    results['local'] = await File(localPath).exists() && await _validateAudioFile(localPath);
    
    // Test asset
    try {
      await _player.play(AssetSource('audio/$filename'));
      await _player.stop();
      results['asset'] = true;
    } catch (e) {
      results['asset'] = false;
    }
    
    // Test streaming (only if network is available)
    results['streaming'] = await _isNetworkAvailable();
    
    return results;
  }

  Future<String> _getAudioDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/meditation_sounds');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir.path;
  }

  Future<String> _getAudioPath(String filename) async {
    final dir = await _getAudioDir();
    return '$dir/$filename';
  }

  Future<bool> _isAudioDownloaded(String filename) async {
    final path = await _getAudioPath(filename);
    return await File(path).exists();
  }

  Future<bool> _validateAudioFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      
      // Check file size (should be > 1KB for audio)
      final size = await file.length();
      final isValid = size > 1024;
      
      if (!isValid) {
        _logger.w('Invalid audio file: $path (size: $size bytes)');
      }
      
      return isValid;
    } catch (e) {
      _logger.e('Error validating audio file $path: $e');
      return false;
    }
  }

  Future<void> downloadAudio(String filename, {Function(int, int)? onProgress}) async {
    if (await _isAudioDownloaded(filename)) {
      // Validate existing file
      final path = await _getAudioPath(filename);
      if (await _validateAudioFile(path)) {
        _logger.d('Audio $filename already downloaded and validated');
        return;
      } else {
        _logger.w('Existing audio file $filename is invalid, re-downloading');
        // Delete invalid file and re-download
        await File(path).delete();
      }
    }

    try {
      final path = await _getAudioPath(filename);
      final url = '$_baseUrl$filename';
      
      _logger.d('Downloading meditation audio from $url to $path');
      
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'audio/mpeg',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://elbiblio.com/',
          'CF-Connecting_IP': '173.245.48.90', // Added this line
        },
      ));
      
      await dio.download(
        url,
        path,
        onReceiveProgress: onProgress,
      );
      
      dio.close();
      
      // Verify the downloaded file
      if (!await _validateAudioFile(path)) {
        throw Exception('Downloaded audio file is invalid or corrupted');
      }
      
      _logger.i('Meditation audio downloaded and validated successfully: $filename');
    } catch (e) {
      _logger.e('Failed to download meditation audio: $e');
      throw Exception('Failed to download meditation audio: $e');
    }
  }

  Future<void> playBackgroundSound(String filename) async {
    try {
      // Try local file first with validation
      final localPath = await _getAudioPath(filename);
      if (await File(localPath).exists()) {
        // Validate the local file before playing
        if (await _validateAudioFile(localPath)) {
          await _player.setReleaseMode(ReleaseMode.loop);
          await _player.setVolume(0.4);
          await _player.play(DeviceFileSource(localPath));
          _logger.d('Playing background sound from local file: $filename');
          return;
        } else {
          _logger.w('Local background sound file is invalid, deleting: $filename');
          await File(localPath).delete();
        }
      }
      
      // Fallback to asset
      try {
        final assetPath = 'audio/$filename';
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(0.4);
        await _player.play(AssetSource(assetPath));
        _logger.d('Playing background sound from asset: $filename');
        return;
      } catch (assetError) {
        _logger.e('Failed to play background sound from asset: $assetError');
        
        // Final fallback: try streaming if we have network connectivity
        if (await _isNetworkAvailable()) {
          try {
            final url = '$_baseUrl$filename';
            await _player.setReleaseMode(ReleaseMode.loop);
            await _player.setVolume(0.4);
            await _player.play(UrlSource(url));
            _logger.d('Playing background sound from streaming URL: $filename');
            return;
          } catch (streamError) {
            _logger.e('Failed to stream background sound: $streamError');
          }
        } else {
          _logger.w('No network connectivity available for streaming fallback');
        }
        throw Exception('All fallback methods failed for background sound: $filename');
      }
    } catch (e) {
      _logger.e('Failed to play background sound: $e');
      throw Exception('Failed to play background sound: $e');
    }
  }

  Future<void> playBellSound(String filename) async {
    try {
      // Try local file first with validation
      final localPath = await _getAudioPath(filename);
      if (await File(localPath).exists()) {
        // Validate the local file before playing
        if (await _validateAudioFile(localPath)) {
          await _player.play(DeviceFileSource(localPath));
          _logger.d('Playing bell sound from local file: $filename');
          return;
        } else {
          _logger.w('Local bell sound file is invalid, deleting: $filename');
          await File(localPath).delete();
        }
      }
      
      // Fallback to asset
      try {
        final assetPath = 'audio/$filename';
        await _player.play(AssetSource(assetPath));
        _logger.d('Playing bell sound from asset: $filename');
        return;
      } catch (assetError) {
        _logger.e('Failed to play bell sound from asset: $assetError');
        
        // Final fallback: try streaming if we have network connectivity
        if (await _isNetworkAvailable()) {
          try {
            final url = '$_baseUrl$filename';
            await _player.play(UrlSource(url));
            _logger.d('Playing bell sound from streaming URL: $filename');
            return;
          } catch (streamError) {
            _logger.e('Failed to stream bell sound: $streamError');
          }
        } else {
          _logger.w('No network connectivity available for streaming fallback');
        }
        throw Exception('All fallback methods failed for bell sound: $filename');
      }
    } catch (e) {
      _logger.e('Failed to play bell sound: $e');
      throw Exception('Failed to play bell sound: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      _logger.e('Failed to stop audio: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume);
    } catch (e) {
      _logger.e('Failed to set volume: $e');
    }
  }

  Future<List<String>> getAvailableSounds() async {
    return [
      'ambient.mp3',
      'heartbeat.mp3',
      'bell-meditation.mp3',
      'success_bell.mp3',
    ];
  }

  Future<bool> isSoundAvailable(String filename) async {
    // Check if either local file or asset exists
    final localPath = await _getAudioPath(filename);
    return await File(localPath).exists();
  }

  // Chant-specific methods
  Future<String> _getChantDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final chantDir = Directory('${directory.path}/meditation_chants');
    if (!await chantDir.exists()) {
      await chantDir.create(recursive: true);
    }
    return chantDir.path;
  }

  Future<String> _getChantPath(String filename) async {
    final dir = await _getChantDir();
    return '$dir/$filename';
  }

  Future<bool> _isChantDownloaded(String filename) async {
    final path = await _getChantPath(filename);
    return await File(path).exists();
  }

  Future<void> downloadChant(String url, String filename, {Function(int, int)? onProgress}) async {
    if (await _isChantDownloaded(filename)) {
      // Validate existing chant file
      final path = await _getChantPath(filename);
      if (await _validateAudioFile(path)) {
        _logger.d('Chant $filename already downloaded and validated');
        return;
      } else {
        _logger.w('Existing chant file $filename is invalid, re-downloading');
        // Delete invalid file and re-download
        await File(path).delete();
      }
    }

    try {
      final path = await _getChantPath(filename);
      
      _logger.d('Downloading chant from $url to $path');
      
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'audio/mpeg',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://elbiblio.com/',
        },
      ));
      
      await dio.download(
        url,
        path,
        onReceiveProgress: onProgress,
      );
      
      dio.close();
      
      // Verify the downloaded chant file
      if (!await _validateAudioFile(path)) {
        throw Exception('Downloaded chant file is invalid or corrupted');
      }
      
      _logger.i('Chant downloaded and validated successfully: $filename');
    } catch (e) {
      _logger.e('Failed to download chant: $e');
      throw Exception('Failed to download chant: $e');
    }
  }

  Future<void> playChant(
    String url,
    String filename, {
    bool loop = false,
    double volume = 0.65,
  }) async {
    final localPath = await _getChantPath(filename);

    Future<void> playLocal() async {
      await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _player.setVolume(volume);
      await _player.play(DeviceFileSource(localPath));
    }

    try {
      // Try local file first with validation
      if (await File(localPath).exists()) {
        // Validate the local chant file before playing
        if (await _validateAudioFile(localPath)) {
          await playLocal();
          _logger.d('Playing chant from local file: $filename');
          return;
        } else {
          _logger.w('Local chant file is invalid, deleting: $filename');
          await File(localPath).delete();
        }
      }
      
      // Download and play
      _logger.d('Downloading chant for playback: $filename');
      await downloadChant(url, filename);
      await playLocal();
      _logger.d('Playing chant after download: $filename');
    } catch (e) {
      _logger.e('Failed to play chant locally: $e');
      // Fallback to streaming so session isn't silent
      if (await _isNetworkAvailable()) {
        try {
          _logger.d('Attempting streaming fallback for chant: $filename');
          await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
          await _player.setVolume(volume);
          await _player.play(UrlSource(url));
          _logger.d('Chant streaming fallback successful: $filename');
        } catch (streamError) {
          _logger.e('Failed to stream chant: $streamError');
          throw Exception('All fallback methods failed for chant: $filename');
        }
      } else {
        _logger.w('No network connectivity available for chant streaming fallback');
        throw Exception('All fallback methods failed for chant: $filename');
      }
    }
  }
}
