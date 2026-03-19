import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'responsive_layout_builder.dart';

class OnboardingIllustrations {
  static Widget welcomeIllustration(BuildContext context, {double? size}) {
    final actualSize = size ?? ResponsiveSpacing.getGoldenRatioLarge(
      MediaQuery.of(context).size.width * 0.3
    );
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Image.asset(
              'assets/images/penheart.png',
              width: actualSize,
              height: actualSize,
              fit: BoxFit.contain,
              color: Theme.of(context).colorScheme.primary,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        );
      },
    );
  }

  static Widget purposeIllustration(BuildContext context, {double? size}) {
    final actualSize = size ?? ResponsiveSpacing.getGoldenRatioLarge(
      MediaQuery.of(context).size.width * 0.25
    );
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: (1 - value) * 0.1,
          child: Opacity(
            opacity: value,
            child: SvgPicture.string(
              _purposeSvg,
              width: actualSize,
              height: actualSize,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  static Widget compassIllustration(BuildContext context, {double? size}) {
    final actualSize = size ?? ResponsiveSpacing.getGoldenRatioLarge(
      MediaQuery.of(context).size.width * 0.2
    );
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 0.05,
          child: Opacity(
            opacity: value,
            child: SvgPicture.string(
              _compassSvg,
              width: actualSize,
              height: actualSize,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  static Widget rhythmIllustration(BuildContext context, {double? size}) {
    final actualSize = size ?? ResponsiveSpacing.getGoldenRatioLarge(
      MediaQuery.of(context).size.width * 0.25
    );
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: SvgPicture.string(
            _rhythmSvg,
            width: actualSize,
            height: actualSize,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  static Widget socialIllustration(BuildContext context, {double? size}) {
    final actualSize = size ?? ResponsiveSpacing.getGoldenRatioLarge(
      MediaQuery.of(context).size.width * 0.25
    );
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: SvgPicture.string(
              _socialSvg,
              width: actualSize,
              height: actualSize,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  static Widget reviewIllustration(BuildContext context, {double? size}) {
    final actualSize = size ?? ResponsiveSpacing.getGoldenRatioLarge(
      MediaQuery.of(context).size.width * 0.2
    );
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: SvgPicture.string(
              _reviewSvg,
              width: actualSize,
              height: actualSize,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  static Widget habitsIllustration(BuildContext context, {double? size}) {
    final actualSize = size ?? ResponsiveSpacing.getGoldenRatioLarge(MediaQuery.of(context).size.width * 0.3);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              width: actualSize,
              height: actualSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(actualSize * 0.2),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: actualSize * 0.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget phoneIllustration(BuildContext context, {double? size}) {
    final actualSize = size ?? ResponsiveSpacing.getGoldenRatioLarge(MediaQuery.of(context).size.width * 0.3);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              width: actualSize,
              height: actualSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(actualSize * 0.15),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.phone_android_outlined,
                size: actualSize * 0.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Purpose illustration - Growing tree with roots
const String _purposeSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="treeGradient" x1="0%" y1="100%" x2="0%" y2="0%">
      <stop offset="0%" style="stop-color:#92400E;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#16A34A;stop-opacity:0.6" />
    </linearGradient>
    <radialGradient id="leavesGradient" cx="50%" cy="30%" r="40%">
      <stop offset="0%" style="stop-color:#86EFAC;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#22C55E;stop-opacity:0.4" />
    </radialGradient>
  </defs>
  
  <!-- Roots -->
  <g opacity="0.4">
    <path d="M100,180 Q90,160 85,140" fill="none" stroke="#92400E" stroke-width="2" stroke-linecap="round" />
    <path d="M100,180 Q110,160 115,140" fill="none" stroke="#92400E" stroke-width="2" stroke-linecap="round" />
    <path d="M100,180 Q100,165 100,150" fill="none" stroke="#92400E" stroke-width="2" stroke-linecap="round" />
  </g>
  
  <!-- Trunk -->
  <rect x="90" y="120" width="20" height="60" fill="url(#treeGradient)" rx="2" />
  
  <!-- Branches -->
  <g opacity="0.7">
    <rect x="70" y="100" width="8" height="30" fill="url(#treeGradient)" rx="1" transform="rotate(-20 74 115)" />
    <rect x="122" y="100" width="8" height="30" fill="url(#treeGradient)" rx="1" transform="rotate(20 126 115)" />
    <rect x="85" y="80" width="6" height="25" fill="url(#treeGradient)" rx="1" transform="rotate(-10 88 92)" />
    <rect x="109" y="80" width="6" height="25" fill="url(#treeGradient)" rx="1" transform="rotate(10 112 92)" />
  </g>
  
  <!-- Leaves canopy -->
  <circle cx="100" cy="60" r="35" fill="url(#leavesGradient)" />
  <circle cx="75" cy="70" r="20" fill="url(#leavesGradient)" opacity="0.8" />
  <circle cx="125" cy="70" r="20" fill="url(#leavesGradient)" opacity="0.8" />
  <circle cx="100" cy="40" r="25" fill="url(#leavesGradient)" opacity="0.9" />
</svg>
''';

// Compass illustration - Detailed compass with cardinal directions
const String _compassSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="compassBg" cx="50%" cy="50%" r="50%">
      <stop offset="0%" style="stop-color:#FEF3C7;stop-opacity:0.9" />
      <stop offset="100%" style="stop-color:#F59E0B;stop-opacity:0.2" />
    </radialGradient>
    <linearGradient id="needleGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#EF4444;stop-opacity:0.9" />
      <stop offset="100%" style="stop-color:#991B1B;stop-opacity:0.7" />
    </linearGradient>
  </defs>
  
  <!-- Outer ring -->
  <circle cx="100" cy="100" r="85" fill="url(#compassBg)" stroke="#D97706" stroke-width="3" opacity="0.8" />
  
  <!-- Inner ring -->
  <circle cx="100" cy="100" r="75" fill="none" stroke="#D97706" stroke-width="1" opacity="0.5" />
  
  <!-- Cardinal directions -->
  <g fill="#92400E" font-family="serif" font-size="14" text-anchor="middle" opacity="0.7">
    <text x="100" y="35">N</text>
    <text x="165" y="105">E</text>
    <text x="100" y="175">S</text>
    <text x="35" y="105">W</text>
  </g>
  
  <!-- Compass needle -->
  <g transform="rotate(45 100 100)">
    <path d="M100,50 L110,100 L100,150 L90,100 Z" fill="url(#needleGradient)" />
    <path d="M100,50 L105,100 L100,130 L95,100 Z" fill="#EF4444" opacity="0.8" />
  </g>
  
  <!-- Center decoration -->
  <circle cx="100" cy="100" r="12" fill="#92400E" opacity="0.8" />
  <circle cx="100" cy="100" r="8" fill="#FEF3C7" />
  
  <!-- Degree marks -->
  <g stroke="#D97706" stroke-width="1" opacity="0.4">
    <line x1="100" y1="25" x2="100" y2="30" />
    <line x1="175" y1="100" x2="170" y2="100" />
    <line x1="100" y1="175" x2="100" y2="170" />
    <line x1="25" y1="100" x2="30" y2="100" />
  </g>
</svg>
''';

// Rhythm illustration - Sound waves and timing
const String _rhythmSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="waveGradient" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:#8B5CF6;stop-opacity:0.3" />
      <stop offset="50%" style="stop-color:#7C3AED;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#8B5CF6;stop-opacity:0.3" />
    </linearGradient>
  </defs>
  
  <!-- Clock circle -->
  <circle cx="100" cy="100" r="70" fill="none" stroke="#E9D5FF" stroke-width="2" opacity="0.6" />
  
  <!-- Sound waves -->
  <g opacity="0.7">
    <path d="M40,100 Q50,85 60,100 T80,100 T100,100 T120,100 T140,100 T160,100" 
          fill="none" stroke="url(#waveGradient)" stroke-width="3" stroke-linecap="round" />
    <path d="M45,110 Q55,95 65,110 T85,110 T105,110 T125,110 T145,110 T155,110" 
          fill="none" stroke="url(#waveGradient)" stroke-width="2" stroke-linecap="round" opacity="0.6" />
    <path d="M45,90 Q55,105 65,90 T85,90 T105,90 T125,90 T145,90 T155,90" 
          fill="none" stroke="url(#waveGradient)" stroke-width="2" stroke-linecap="round" opacity="0.6" />
  </g>
  
  <!-- Clock hands -->
  <g stroke="#7C3AED" stroke-width="3" stroke-linecap="round">
    <line x1="100" y1="100" x2="100" y2="60" opacity="0.8" />
    <line x1="100" y1="100" x2="130" y2="100" opacity="0.6" />
  </g>
  
  <!-- Center dot -->
  <circle cx="100" cy="100" r="6" fill="#7C3AED" opacity="0.8" />
  
  <!-- Rhythm dots -->
  <g fill="#8B5CF6" opacity="0.6">
    <circle cx="50" cy="100" r="3" />
    <circle cx="70" cy="100" r="4" />
    <circle cx="90" cy="100" r="5" />
    <circle cx="110" cy="100" r="5" />
    <circle cx="130" cy="100" r="4" />
    <circle cx="150" cy="100" r="3" />
  </g>
</svg>
''';

// Social illustration - Connected circles
const String _socialSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="socialGradient" cx="50%" cy="50%" r="50%">
      <stop offset="0%" style="stop-color:#DBEAFE;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#3B82F6;stop-opacity:0.2" />
    </radialGradient>
  </defs>
  
  <!-- Connection lines -->
  <g stroke="#3B82F6" stroke-width="2" opacity="0.3">
    <line x1="60" y1="70" x2="100" y2="100" stroke-dasharray="5,5" />
    <line x1="140" y1="70" x2="100" y2="100" stroke-dasharray="5,5" />
    <line x1="60" y1="130" x2="100" y2="100" stroke-dasharray="5,5" />
    <line x1="140" y1="130" x2="100" y2="100" stroke-dasharray="5,5" />
    <line x1="60" y1="70" x2="140" y2="70" stroke-dasharray="3,3" opacity="0.2" />
    <line x1="60" y1="130" x2="140" y2="130" stroke-dasharray="3,3" opacity="0.2" />
  </g>
  
  <!-- Person circles -->
  <g>
    <!-- Center person (you) -->
    <circle cx="100" cy="100" r="25" fill="url(#socialGradient)" stroke="#3B82F6" stroke-width="2" />
    <circle cx="100" cy="92" r="8" fill="#3B82F6" opacity="0.8" />
    <path d="M85,110 Q100,105 115,110" fill="#3B82F6" opacity="0.6" />
    
    <!-- Others -->
    <circle cx="60" cy="70" r="20" fill="url(#socialGradient)" stroke="#3B82F6" stroke-width="1.5" opacity="0.7" />
    <circle cx="60" cy="65" r="6" fill="#3B82F6" opacity="0.6" />
    <path d="M50,78 Q60,74 70,78" fill="#3B82F6" opacity="0.4" />
    
    <circle cx="140" cy="70" r="20" fill="url(#socialGradient)" stroke="#3B82F6" stroke-width="1.5" opacity="0.7" />
    <circle cx="140" cy="65" r="6" fill="#3B82F6" opacity="0.6" />
    <path d="M130,78 Q140,74 150,78" fill="#3B82F6" opacity="0.4" />
    
    <circle cx="60" cy="130" r="20" fill="url(#socialGradient)" stroke="#3B82F6" stroke-width="1.5" opacity="0.7" />
    <circle cx="60" cy="125" r="6" fill="#3B82F6" opacity="0.6" />
    <path d="M50,138 Q60,134 70,138" fill="#3B82F6" opacity="0.4" />
    
    <circle cx="140" cy="130" r="20" fill="url(#socialGradient)" stroke="#3B82F6" stroke-width="1.5" opacity="0.7" />
    <circle cx="140" cy="125" r="6" fill="#3B82F6" opacity="0.6" />
    <path d="M130,138 Q140,134 150,138" fill="#3B82F6" opacity="0.4" />
  </g>
  
  <!-- Gentle glow around center -->
  <circle cx="100" cy="100" r="35" fill="none" stroke="#3B82F6" stroke-width="1" opacity="0.2" stroke-dasharray="2,4" />
</svg>
''';

// Review illustration - Checkmark with completion circle
const String _reviewSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="checkGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#10B981;stop-opacity:0.9" />
      <stop offset="100%" style="stop-color:#047857;stop-opacity:0.7" />
    </linearGradient>
    <radialGradient id="completionGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" style="stop-color:#D1FAE5;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:#10B981;stop-opacity:0.1" />
    </radialGradient>
  </defs>
  
  <!-- Background glow -->
  <circle cx="100" cy="100" r="75" fill="url(#completionGlow)" />
  
  <!-- Progress circle -->
  <circle cx="100" cy="100" r="60" fill="none" stroke="#D1FAE5" stroke-width="8" opacity="0.6" />
  <circle cx="100" cy="100" r="60" fill="none" stroke="url(#checkGradient)" stroke-width="8" 
          stroke-dasharray="377" stroke-dashoffset="94" stroke-linecap="round"
          transform="rotate(-90 100 100)" />
  
  <!-- Checkmark -->
  <g transform="scale(1.2) translate(15, 10)">
    <path d="M50,75 L70,95 L130,35" fill="none" stroke="url(#checkGradient)" 
          stroke-width="8" stroke-linecap="round" stroke-linejoin="round" />
  </g>
  
  <!-- Small completion dots -->
  <g fill="#10B981" opacity="0.6">
    <circle cx="40" cy="40" r="4" />
    <circle cx="160" cy="40" r="4" />
    <circle cx="40" cy="160" r="4" />
    <circle cx="160" cy="160" r="4" />
  </g>
  
  <!-- Center highlight -->
  <circle cx="100" cy="100" r="3" fill="#047857" opacity="0.8" />
</svg>
''';
