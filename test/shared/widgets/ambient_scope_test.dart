import 'package:elbiblio/core/di/app_providers.dart';
import 'package:elbiblio/core/services/sound_service.dart';
import 'package:elbiblio/shared/widgets/ambient_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stub all audioplayers method-channel calls so [AudioPlayer] construction
/// doesn't hang waiting for a platform response in the test environment.
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

/// A minimal [SoundService] subclass that records [playAmbient] /
/// [stopAmbient] calls without performing actual audio I/O.
///
/// Extends the real class so [soundServiceProvider.overrideWithValue] typing
/// works without changing production code.  All AudioPlayer calls are made
/// no-ops by the channel stub set up in [_stubAudioPlayersChannel].
class _FakeSoundService extends SoundService {
  _FakeSoundService() : super(soundEnabled: false);

  final List<String> calls = [];

  @override
  Future<void> playAmbient(String asset, {double volume = 0.10}) async {
    calls.add('playAmbient:$asset');
  }

  @override
  Future<void> stopAmbient() async {
    calls.add('stopAmbient');
  }

  @override
  Future<void> dispose() async {
    // Skip real AudioPlayer dispose in tests.
  }
}

void main() {
  setUpAll(_stubAudioPlayersChannel);

  testWidgets('AmbientScope calls playAmbient on mount', (tester) async {
    final fake = _FakeSoundService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [soundServiceProvider.overrideWithValue(fake)],
        child: const MaterialApp(
          home: AmbientScope(
            asset: SoundService.ambientHomeAsset,
            volume: 0.1,
            child: Scaffold(body: Text('test')),
          ),
        ),
      ),
    );

    await tester.pump(); // postFrameCallback fires

    expect(
      fake.calls,
      contains('playAmbient:${SoundService.ambientHomeAsset}'),
    );
  });

  testWidgets('AmbientScope mounts and unmounts without throwing', (tester) async {
    final fake = _FakeSoundService();
    final showAmbient = ValueNotifier<bool>(true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [soundServiceProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: showAmbient,
            builder: (_, show, __) => show
                ? const AmbientScope(
                    asset: SoundService.ambientHomeAsset,
                    child: Scaffold(body: Text('test')),
                  )
                : const Scaffold(body: Text('replacement')),
          ),
        ),
      ),
    );
    await tester.pump(); // postFrameCallback → playAmbient

    expect(
      fake.calls,
      contains('playAmbient:${SoundService.ambientHomeAsset}'),
    );

    // Removing AmbientScope calls _stopAmbient; expect no exception.
    showAmbient.value = false;
    await tester.pump(); // should complete without throwing
  });

  testWidgets('AmbientScope renders its child', (tester) async {
    final fake = _FakeSoundService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [soundServiceProvider.overrideWithValue(fake)],
        child: const MaterialApp(
          home: AmbientScope(
            asset: SoundService.ambientBibleAsset,
            child: Scaffold(body: Text('child widget')),
          ),
        ),
      ),
    );

    expect(find.text('child widget'), findsOneWidget);
  });

}
