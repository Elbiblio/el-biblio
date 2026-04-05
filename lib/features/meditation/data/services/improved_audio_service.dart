import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class ImprovedAudioService {
  final Logger _logger = Logger();
  final AudioPlayer _player = AudioPlayer();

  ImprovedAudioService() {
    _logger.d('Audio service initialized on platform: ${Platform.operatingSystem}');
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

      await stop();
      await _player.play(DeviceFileSource(path));

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

      await stop();
      await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _player.setVolume(0.8);
      await _player.play(UrlSource(url));

      _logger.i('Streaming audio started successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to play streaming audio: $e');
      return false;
    }
  }

  /// Preload chant audio by downloading it locally for instant playback.
  /// Returns the local file path if successful, null otherwise.
  Future<String?> preloadChant(String url) async {
    try {
      _logger.d('Preloading chant: $url');

      if (url.startsWith('assets/')) {
        // Asset files are already available locally
        return url;
      }

      // Download to local cache for instant playback
      final filename = url.split('/').last;
      final filePath = await _getAudioPath(filename, isChant: true);

      if (await File(filePath).exists()) {
        return filePath;
      }

      final success = await downloadAudio(url, filename, isChant: true);
      return success ? filePath : null;
    } catch (e) {
      _logger.e('Failed to preload chant: $e');
      return null;
    }
  }

  /// Play a preloaded chant from a local path or asset.
  Future<bool> playPreloadedChant(String path, {bool loop = false}) async {
    try {
      _logger.d('Playing preloaded chant');

      await stop();
      await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);

      if (path.startsWith('assets/')) {
        await _player.play(AssetSource(path.replaceFirst('assets/', '')));
      } else {
        await _player.play(DeviceFileSource(path));
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

          await stop();
          await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
          await _player.play(AssetSource(urlOrAsset.replaceFirst('assets/', '')));

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
      await _player.stop();
      _logger.d('Audio stopped');
    } catch (e) {
      _logger.e('Failed to stop audio: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _logger.d('Audio paused');
    } catch (e) {
      _logger.e('Failed to pause audio: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _player.resume();
      _logger.d('Audio resumed');
    } catch (e) {
      _logger.e('Failed to resume audio: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume);
      _logger.d('Volume set to: $volume');
    } catch (e) {
      _logger.e('Failed to set volume: $e');
    }
  }

  bool get isPlaying {
    try {
      return _player.state == PlayerState.playing;
    } catch (e) {
      _logger.e('Failed to check playing state: $e');
      return false;
    }
  }

  Future<bool> requestAudioFocus() async {
    return true;
  }

  Future<void> dispose() async {
    try {
      await _player.stop();
      await _player.dispose();
      _logger.d('Audio service disposed');
    } catch (e) {
      _logger.e('Failed to dispose audio service: $e');
    }
  }
}
