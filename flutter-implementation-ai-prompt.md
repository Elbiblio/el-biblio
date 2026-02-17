# Comprehensive AI Implementation Prompt for Compass OS Flutter Migration

## AI Prompt for Flutter Implementation

You are an expert Flutter developer specializing in high-performance mobile applications with deep knowledge of spiritual wellness apps. Your task is to implement Compass OS, a personal spiritual operating system, in Flutter with extreme focus on performance optimization and user experience.

## Project Context

**Compass OS** is a daily spiritual alignment system that helps users connect their inner life (spiritual), outer life (physical), and directional life (purpose/career) through a structured daily operating loop.

### Core Philosophy
- This is NOT a content library or passive devotional
- This IS a daily alignment system
- Spiritual growth is directional, not informational
- Consistency beats intensity
- Inner formation must be embodied (action, movement, discipline)

### Four Foundational Virtues (Fixed, Universal)
1. **Humility** — alignment with truth, self-awareness, surrender
2. **Love** — compassion, service, relational intentionality  
3. **Faith** — trust, obedience, courage, spiritual anchoring
4. **Knowledge** — wisdom, learning, discernment, understanding

### Trinitarian Daily Anchor Model
Each day has three anchors:
- **Core Virtue Anchor** (Why you live today) - Internal alignment
- **Habit Anchor** (What you must practice today) - Discipline & formation
- **Fun/Energy Anchor** (How you embody it physically) - Embodiment & joy

## Technical Requirements

### Performance Standards (NON-NEGOTIABLE)
- App startup time: < 2 seconds
- Screen transitions: < 300ms
- Memory usage: < 100MB typical usage
- 60fps animations throughout
- App size: < 50MB (without assets)

### Architecture Requirements
- **Framework**: Flutter 3.x with Dart 3.5+
- **State Management**: Riverpod (lightweight, performant)
- **Navigation**: GoRouter (declarative, type-safe)
- **Local Storage**: Hive (faster than SQLite for simple models)
- **Networking**: Dio with proper caching
- **Images**: cached_network_image with optimized caching

### Project Structure
```
lib/
├── core/                          # Core app functionality
│   ├── constants/                 # App constants, routes
│   ├── errors/                    # Error handling
│   ├── network/                   # Network configuration
│   ├── storage/                   # Local storage setup
│   └── theme/                     # Theme system
├── features/                      # Feature-based architecture
│   ├── onboarding/               # Onboarding flow
│   ├── today/                    # Daily anchors & home
│   ├── bible/                    # Bible reading
│   ├── meditation/               # Meditation tools
│   ├── journal/                   # Journaling
│   ├── assessment/               # Compass assessment
│   └── profile/                  # User settings
├── shared/                        # Shared components
│   ├── widgets/                   # Reusable UI components
│   ├── extensions/               # Dart extensions
│   └── utils/                     # Utility functions
└── main.dart                      # App entry point
```

## Implementation Tasks

### Phase 1: Foundation Setup

#### 1.1 Project Creation & Dependencies
Create Flutter project with these exact dependencies:
```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  go_router: ^12.1.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  dio: ^5.3.0
  cached_network_image: ^3.3.0
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.0
  shared_preferences: ^2.2.0
  workmanager: ^0.5.0
  json_annotation: ^4.8.0
  intl: ^0.18.0

dev_dependencies:
  flutter_test:
    flutter_lints: ^3.0.0
  hive_generator: ^2.0.0
  json_serializable: ^6.7.0
  build_runner: ^2.4.0
```

#### 1.2 Theme System Implementation
Implement the existing theme system with three variants:

**Sage Garden Theme** (Primary)
```dart
class AppColors {
  // Sage Garden - Light
  static const sagePrimary = Color(0xFF638B6C);
  static const sagePrimaryLight = Color(0xFF85A889);
  static const sagePrimaryDark = Color(0xFF4A6B51);
  static const sageBackground = Color(0xFFFDFAF6);
  static const sageSurface = Color(0xFFF5F7F3);
  static const sagePaper = Color(0xFFF2F5E9);
  
  // Typography
  static const textPrimary = Color(0xFF2C3830);
  static const textSecondary = Color(0xFF5A6157);
  static const textTertiary = Color(0xFF7D857A);
}
```

**Typography System**
- **Crimson Pro** for verse text and body content
- **Plus Jakarta Sans** for headings and UI elements
- Implement responsive text scaling

#### 1.3 Core Infrastructure
- Error handling system with custom exceptions
- Network layer with Dio interceptors
- Hive storage setup with proper adapters
- Base repository pattern implementation
- Dependency injection setup

### Phase 2: Core Features

#### 2.1 Onboarding Flow (MANDATORY COMPLETION)
Onboarding is only complete when ALL tasks are done:

1. **Purpose Framing Screen**
   - Explains this is a daily alignment system
   - Gentle accountability messaging
   - Time-bound experience framing

2. **Compass Assessment**
   - Short, reflective questions
   - Detect dominant virtue and neglected virtue
   - Spiritual imbalance signals

3. **Initial Virtue Focus**
   - App suggests 1 primary virtue
   - User can accept or override with explanation

4. **Daily Rhythm Setup**
   - Journal reminder time selection
   - Notification window configuration
   - Framed as support, not pressure

5. **Anchor Explanation + Preview**
   - Shows all three anchor types
   - Example day preview
   - Interactive explanation

6. **First Check-in (Mini)**
   - One reflective prompt
   - One simple action confirmation

#### 2.2 Today Screen - "Today First" Philosophy
The homepage is time-sensitive, not navigational. When the day changes, the screen changes.

**Screen Structure (Vertical Layout)**
```
┌────────────────────────────────┐
│ DATE + GREETING               │
│ "Today • Tuesday, Mar 12"     │
│ Focus Virtue: HUMILITY        │
├────────────────────────────────┤
│ DAILY VERSE / MEDITATION LINE │
│ "He must increase..."         │
│ [Reflect]                     │
├────────────────────────────────┤
│ YOUR 3 DAILY ANCHORS          │
│                               │
│ ① CORE VIRTUE                 │
│ Humility                      │
│ "Act with openness & truth"   │
│                               │
│ ② DAILY HABIT                 │
│ Silent Prayer (5 min)         │
│ [Start]                       │
│                               │
│ ③ FUN / ENERGY ACTION         │
│ Walk intentionally for 10 min │
│ [Mark Done]                   │
├────────────────────────────────┤
│ MIDDAY CHECK-IN (if time)     │
│ "Are you aligned so far?"     │
│ [Yes] [Adjust]                │
├────────────────────────────────┤
│ EVENING REFLECTION            │
│ Sliders (1–5):                │
│ - Virtue lived                │
│ - Habit kept                  │
│ - Action completed            │
│ [Journal Entry]               │
├────────────────────────────────┤
│ DAILY SUMMARY                 │
│ Integrity Points: +12         │
│ Streak: Day 4                 │
└────────────────────────────────┘
```

#### 2.3 State Management Implementation
```dart
// Core providers
final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) => ThemeNotifier());
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier());

// Feature providers
final dailyAnchorsProvider = StateNotifierProvider<DailyAnchorsNotifier, DailyAnchors>((ref) => DailyAnchorsNotifier());
final virtueProvider = StateNotifierProvider<VirtueNotifier, VirtueState>((ref) => VirtueNotifier());
final journalProvider = StateNotifierProvider<JournalNotifier, JournalState>((ref) => JournalNotifier());
```

### Phase 3: Spiritual Tools

#### 3.1 Bible Integration
- Daily verse auto-selection based on virtue focus
- Optional reading plans
- No infinite scrolling (content-focused)
- Contextual prompts tied to virtue
- Offline caching with Hive

#### 3.2 Meditation System
- Short sessions (2-10 minutes)
- Silent or guided options
- Virtue-specific meditations
- Audio caching and streaming
- Progress tracking

#### 3.3 Journal System
- Structured prompts tied to daily anchors
- Free writing optional
- Anchored to daily check-in
- Search and organization
- Export capabilities

### Phase 4: Reinforcement Layer

#### 4.1 Integrity Score System
- Earned daily based on:
  - Honesty in self-assessment
  - Consistency in practice
  - Completion (not perfection)
- Light gamification, no leaderboards
- Personal growth focus

#### 4.2 Streaks & Rhythm
- Daily usage tracking
- Gentle accountability
- Rhythm visualization
- Recalibration suggestions

## Performance Optimization Requirements

### 1. Widget Performance
- Mark ALL static widgets as `const`
- Use `RepaintBoundary` strategically around animated components
- Implement `ListView.builder` for ALL scrollable content
- Use `AutomaticKeepAliveClientMixin` judiciously

### 2. Memory Management
- Proper disposal of controllers and streams
- Implement efficient caching strategies
- Monitor memory usage with DevTools
- Use `Isolate` for heavy computations

### 3. Asset Optimization
- Convert all images to WebP format
- Implement lazy loading for images
- Compress audio files
- Optimize font loading

### 4. Build Optimization
```yaml
# pubspec.yaml optimizations
flutter:
  # Optimize asset bundling
  assets:
    - assets/images/
    - assets/audio/
    - assets/fonts/
  
  # Tree shaking configuration
  tree-shake-icons: true
  
  # Optimize fonts
  fonts:
    - family: CrimsonPro
      fonts:
        - asset: assets/fonts/CrimsonPro-Regular.ttf
        - asset: assets/fonts/CrimsonPro-Medium.ttf
          weight: 500
```

## Data Models & Storage

### Core Models
```dart
@JsonSerializable()
class DailyAnchors {
  final Virtue coreVirtue;
  final Habit habit;
  final EnergyAction energyAction;
  final DateTime date;
  final bool isCompleted;
}

@JsonSerializable()
class Virtue {
  final VirtueType type;
  final String description;
  final String focusPrompt;
  final int integrityPoints;
  final String scriptureReference;
}

@JsonSerializable()
class Habit {
  final String title;
  final String description;
  final Duration duration;
  final HabitType type;
  final bool isCompleted;
}

@JsonSerializable()
class JournalEntry {
  final String id;
  final DateTime date;
  final String content;
  final List<String> prompts;
  final int virtueRating;
  final int habitRating;
  final int actionRating;
}
```

### Hive Storage Setup
```dart
// Register Hive adapters
Hive.registerAdapter(DailyAnchorsAdapter());
Hive.registerAdapter(VirtueAdapter());
Hive.registerAdapter(HabitAdapter());
Hive.registerAdapter(JournalEntryAdapter());

// Open boxes
await Hive.openBox<DailyAnchors>('daily_anchors');
await Hive.openBox<Virtue>('virtues');
await Hive.openBox<JournalEntry>('journal_entries');
```

## Testing Requirements

### Unit Tests
- Test all business logic
- Mock external dependencies
- Achieve 80%+ code coverage
- Test edge cases and error conditions

### Widget Tests
- Test UI component behavior
- Verify accessibility compliance
- Test user interactions
- Validate responsive design

### Integration Tests
- Test complete user flows
- Verify data persistence
- Test network interactions
- Performance benchmarking

## Accessibility Requirements

### WCAG 2.1 AA Compliance
- Semantic labeling for all interactive elements
- Proper contrast ratios (4.5:1 minimum)
- Screen reader support
- Keyboard navigation
- Text scaling support

### Flutter-Specific Accessibility
- Use `Semantics` widgets appropriately
- Implement `AccessibilityShortcuts`
- Support for VoiceOver and TalkBack
- High contrast mode support

## Error Handling & Logging

### Error Types
```dart
class AppException implements Exception {
  final String message;
  final String code;
  final dynamic details;
  
  AppException(this.message, this.code, [this.details]);
}

class NetworkException extends AppException { }
class StorageException extends AppException { }
class ValidationException extends AppException { }
```

### Logging Strategy
- Use `logger` package for structured logging
- Different log levels for development vs production
- Crash reporting integration (Firebase Crashlytics)
- Performance monitoring

## Security Considerations

### Data Protection
- Encrypt sensitive user data
- Secure API communication
- Local data encryption
- Biometric authentication for sensitive features

### Privacy Compliance
- GDPR compliance
- Data minimization
- User consent management
- Right to deletion

## Deployment Configuration

### Build Configuration
```yaml
# Build flavors for different environments
flutter:
  flavors:
    development:
      app_name: Compass OS Dev
      bundle_id: com.compassos.dev
    production:
      app_name: Compass OS
      bundle_id: com.compassos.app
```

### Release Optimization
- Enable AOT compilation
- Obfuscate code for production
- Optimize asset compression
- Configure proper signing

## Success Criteria

### Performance Benchmarks
- App startup: < 2 seconds
- Screen transitions: < 300ms
- Memory usage: < 100MB
- 60fps animations maintained
- App size: < 50MB

### User Experience Goals
- Seamless onboarding completion rate > 90%
- Daily anchor engagement > 80%
- User retention > 70% after 30 days
- App store rating > 4.5

## Implementation Priority

### P0 (Critical Path)
1. Project setup and theme system
2. Onboarding flow completion
3. Today screen with daily anchors
4. Basic journal functionality

### P1 (Core Features)
1. Bible integration
2. Meditation system
3. Integrity scoring
4. Data persistence

### P2 (Enhancement)
1. Advanced analytics
2. Social features (deferred)
3. Advanced customization
4. Performance optimizations

## Code Quality Standards

### Dart/Flutter Best Practices
- Follow effective Dart guidelines
- Use strong typing throughout
- Implement proper null safety
- Use const constructors where possible
- Proper widget composition

### Documentation Requirements
- Document all public APIs
- Include usage examples
- Architecture decision records
- Performance benchmarks

## Final Deliverables

1. **Complete Flutter application** with all core features
2. **Performance benchmarks** meeting all targets
3. **Comprehensive test suite** with 80%+ coverage
4. **Deployment configuration** for iOS and Android
5. **Documentation** including architecture and user guides

## Implementation Notes

- Focus on performance optimization at every step
- Implement proper error handling from the start
- Use the existing brand identity and themes
- Maintain the spiritual operating system philosophy
- Prioritize user experience over feature complexity
- Test thoroughly on both iOS and Android devices

Remember: This is a spiritual operating system, not just another app. Every design decision should support the user's spiritual growth and daily alignment with their core virtues.
