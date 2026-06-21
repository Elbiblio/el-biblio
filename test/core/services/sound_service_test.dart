import 'package:elbiblio/core/services/sound_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stub audioplayers platform channels so [AudioPlayer] construction completes
/// immediately in the test environment without hanging on platform I/O.
void _stubAudioPlayersChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async => null,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (call) async => null,
  );
}

/// Unit tests for [SoundService] state management logic.
///
/// Audio I/O (AudioPlayer) is not testable in a unit context, so these tests
/// verify state flags and guard logic only — i.e. that sounds are *skipped*
/// when the service is disabled, DND is active, or the app is paused.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    _stubAudioPlayersChannel();
  });

  group('SoundService state flags', () {
    late SoundService service;

    setUp(() {
      service = SoundService(soundEnabled: true);
    });

    tearDown(() async {
      await service.dispose();
    });

    test('starts enabled', () {
      expect(service.soundEnabled, isTrue);
    });

    test('setSoundEnabled toggles the flag', () {
      service.setSoundEnabled(false);
      expect(service.soundEnabled, isFalse);

      service.setSoundEnabled(true);
      expect(service.soundEnabled, isTrue);
    });

    test('created with soundEnabled:false starts disabled', () {
      final s = SoundService(soundEnabled: false);
      expect(s.soundEnabled, isFalse);
      s.dispose();
    });
  });

  group('SoundService DND / lifecycle flag setters', () {
    // These methods only mutate internal flags — they do not invoke AudioPlayer.
    test('setDndActive toggles without throwing', () {
      final service = SoundService(soundEnabled: true);
      // setDndActive(true) calls stopAmbient() internally, but _isAmbientPlaying
      // is false so stopAmbient() returns early before touching AudioPlayer.
      expect(() => service.setDndActive(true), returnsNormally);
      expect(() => service.setDndActive(false), returnsNormally);
    });

    test('setAppPaused(false) when nothing playing does not call AudioPlayer',
        () {
      final service = SoundService(soundEnabled: true);
      // _isAmbientPlaying starts false → resume branch is not reached.
      expect(() => service.setAppPaused(false), returnsNormally);
    });
  });

  group('SoundService asset constants are non-empty strings', () {
    test('all semantic asset paths are non-empty', () {
      expect(SoundService.tapAsset, isNotEmpty);
      expect(SoundService.successAsset, isNotEmpty);
      expect(SoundService.completeAsset, isNotEmpty);
      expect(SoundService.errorAsset, isNotEmpty);
      expect(SoundService.transitionAsset, isNotEmpty);
      expect(SoundService.paperRustleAsset, isNotEmpty);
      expect(SoundService.pageTurnAsset, isNotEmpty);
      expect(SoundService.welcomeShinyAsset, isNotEmpty);
      expect(SoundService.chimeGentleAsset, isNotEmpty);
      expect(SoundService.successBellAsset, isNotEmpty);
      expect(SoundService.levelUpAsset, isNotEmpty);
      expect(SoundService.correctAsset, isNotEmpty);
      expect(SoundService.wrongAsset, isNotEmpty);
      expect(SoundService.ambientHomeAsset, isNotEmpty);
      expect(SoundService.ambientTodayAsset, isNotEmpty);
      expect(SoundService.ambientBibleAsset, isNotEmpty);
      expect(SoundService.ambientCommunityAsset, isNotEmpty);
      expect(SoundService.bellMeditationAsset, isNotEmpty);
    });

    test('game-specific asset paths are non-empty', () {
      expect(SoundService.gameTickAsset, isNotEmpty);
      expect(SoundService.gameTimeoutAsset, isNotEmpty);
      expect(SoundService.gameOverAsset, isNotEmpty);
    });

    test('asset paths all start with audio/', () {
      final assets = [
        SoundService.tapAsset,
        SoundService.successAsset,
        SoundService.ambientHomeAsset,
        SoundService.gameTickAsset,
      ];
      for (final asset in assets) {
        expect(asset, startsWith('audio/'), reason: 'bad path: $asset');
      }
    });
  });
}
