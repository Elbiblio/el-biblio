import 'package:flutter/material.dart';

/// The header section with just the app logo
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Image.asset(
        'assets/images/penheart.png',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image doesn't exist
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2C3333), // --text-primary
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFD4AF37), // --gold-accent
              size: 60,
            ),
          );
        },
      ),
    );
  }
}
