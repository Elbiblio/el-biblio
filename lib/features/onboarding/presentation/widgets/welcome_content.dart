import 'package:flutter/material.dart';

/// The main content area with logo, tagline, and image
class WelcomeContent extends StatelessWidget {
  const WelcomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'A life in harmony,\nspiritually and physically.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w300,
              height: 1.5,
              color: const Color(0xFF5C6363),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          const WelcomeLandscapeImage(),
          const WelcomeTimeBadge(),
        ],
      ),
    );
  }
}

/// The landscape image with gradient overlay
class WelcomeLandscapeImage extends StatelessWidget {
  const WelcomeLandscapeImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F0E5), Color(0xFFD8E5D5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9AB8A2).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuB0d2_oS3TTE7ck-aJbhIkb_Oo5tmrwtbevohOesgVPwfNgQro3KkHk-4SlZerskmrLreZ1zUThFBtIJoUovhkxj8qMdzFAGK42fhlkG3WT1tpbU8BAW-GxcC9XHsN8XbnGmVopT6dVTuxs0cR6Bm0F_wRgoRQ47esFvFBOccJZ6SLyKNPpXYfbbETINeON7-dANltkpkcjdAO2Zi-uyPJOO0IxAD2QLOL0oxglEOFyBr8wKX3qxX9X9gympuPNmwElLAAYTc0tpRM',
                  fit: BoxFit.cover,
                  colorBlendMode: BlendMode.multiply,
                  color: Colors.black.withValues(alpha: 0.05),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const ColoredBox(color: Colors.white);
                  },
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.white.withValues(alpha: 0.6)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The time badge showing "3-5 minutes daily"
class WelcomeTimeBadge extends StatelessWidget {
  const WelcomeTimeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: const Color(0xFF2C3333).withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule,
            size: 12,
            color: Color(0xFF7D9A85), // --sage-dark
          ),
          const SizedBox(width: 6),
          Text(
            'One Intention. Three Check-Ins.\nOne Clear Conscience.',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5C6363), // --text-secondary
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
