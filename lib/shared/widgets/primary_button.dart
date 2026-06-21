import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/app_providers.dart';

enum PrimaryButtonSound { none, tap }

class PrimaryButton extends ConsumerWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.expanded = false,
    this.semanticLabel,
    this.sound = PrimaryButtonSound.tap,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final String? semanticLabel;
  final PrimaryButtonSound sound;

  VoidCallback? _wrap(WidgetRef ref, VoidCallback? cb) {
    if (cb == null || sound == PrimaryButtonSound.none) return cb;
    return () {
      ref.read(soundServiceProvider).playTap();
      cb();
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrappedPress = _wrap(ref, onPressed);

    final button = Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: FilledButton.icon(
        onPressed: wrappedPress,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
      ),
    );

    if (icon == null) {
      return Semantics(
        button: true,
        label: semanticLabel ?? label,
        child: FilledButton(
          onPressed: wrappedPress,
          child: Text(label),
        ),
      );
    }

    if (!expanded) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
