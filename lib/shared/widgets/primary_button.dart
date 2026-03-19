import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.expanded = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
      ),
    );

    if (icon == null) {
      return Semantics(
        button: true,
        label: semanticLabel ?? label,
        child: FilledButton(
          onPressed: onPressed,
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
