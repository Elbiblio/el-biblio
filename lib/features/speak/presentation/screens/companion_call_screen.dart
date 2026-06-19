import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../companion/application/companion_notifier.dart';
import '../../../companion/domain/models/companion_character.dart';

/// Full-screen companion call experience.
///
/// Not a real phone call — an immersive 30-second interaction where the
/// companion speaks via TTS and the user responds with tap buttons.
/// Triggered by escalation at day 5+ miss, or user tapping "Call" on
/// companion.
class CompanionCallScreen extends ConsumerStatefulWidget {
  final String? threadKey;

  const CompanionCallScreen({super.key, this.threadKey});

  @override
  ConsumerState<CompanionCallScreen> createState() =>
      _CompanionCallScreenState();
}

class _CompanionCallScreenState extends ConsumerState<CompanionCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _interactionActive = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleAction(String action) {
    if (!_interactionActive) return;
    setState(() => _interactionActive = false);

    switch (action) {
      case 'done':
        _endCall('I\'m with you. Let\'s try again tomorrow. One day at a time.');
      case 'help':
        _endCall('Let\'s talk this through in chat. I\'m right here.');
      case 'later':
        _endCall('I\'ll check in on you later. You\'re not alone.');
    }
  }

  void _endCall(String message) {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.of(context).pop(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final character = ref.watch(
      companionProvider.select((s) => s.activeCharacter ?? CompanionCharacter.naomi),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Companion orb
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 196,
                    height: 196,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          character.gradientStops.first.withValues(alpha: 0.8),
                          character.gradientStops.last.withValues(alpha: 0.2),
                          Colors.black,
                        ],
                        stops: const [0.3, 0.6, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: character.gradientStops.first.withValues(alpha: 0.3),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.headphones,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Companion name
            Text(
              character.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // Status indicator
            Text(
              'Speaking...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),

            const Spacer(flex: 1),

            // Action buttons
            if (_interactionActive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _CallButton(
                      label: 'I\'ll do this',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      onTap: () => _handleAction('done'),
                    ),
                    const SizedBox(height: 12),
                    _CallButton(
                      label: 'I need help',
                      icon: Icons.help_outline,
                      color: Colors.orange,
                      onTap: () => _handleAction('help'),
                    ),
                    const SizedBox(height: 12),
                    _CallButton(
                      label: 'Remind me later',
                      icon: Icons.notifications_none,
                      color: Colors.grey,
                      onTap: () => _handleAction('later'),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Call ended',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Return to chat',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CallButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
