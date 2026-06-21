import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/app_providers.dart';

/// Wraps an immersive screen and starts/stops an ambient audio loop on
/// init/dispose, automatically respecting the global [soundEnabled] setting.
///
/// Usage:
/// ```dart
/// AmbientScope(
///   asset: SoundService.ambientBibleAsset,
///   child: MyScreen(),
/// )
/// ```
class AmbientScope extends ConsumerStatefulWidget {
  const AmbientScope({
    super.key,
    required this.asset,
    required this.child,
    this.volume = 0.10,
  });

  final String asset;
  final Widget child;
  final double volume;

  @override
  ConsumerState<AmbientScope> createState() => _AmbientScopeState();
}

class _AmbientScopeState extends ConsumerState<AmbientScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAmbient();
    });
  }

  @override
  void dispose() {
    _stopAmbient();
    super.dispose();
  }

  void _startAmbient() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) return;
    ref
        .read(soundServiceProvider)
        .playAmbient(widget.asset, volume: widget.volume);
  }

  void _stopAmbient() {
    ref.read(soundServiceProvider).stopAmbient();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
