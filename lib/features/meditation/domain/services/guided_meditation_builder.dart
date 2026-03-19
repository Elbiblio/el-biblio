import '../models/guided_meditation_content.dart';
import '../models/guided_meditation_phases.dart';
import '../models/meditation_enums.dart';
import '../models/meditation_templates.dart';

/// Builds guided meditation content following the 4-phase structure
class GuidedMeditationBuilder {
  const GuidedMeditationBuilder._();

  static GuidedMeditationContent build({
    required MeditationStyle style,
    required int totalDurationMinutes,
    BibleTemplate? bibleTemplate,
    AffirmationCategory? affirmationCategory,
    VirtueAffirmation? virtueAffirmation,
    HabitAffirmation? habitAffirmation,
    String? customBibleVerses,
    String? centeringWord,
  }) {
    switch (style) {
      case MeditationStyle.quietReflection:
        return _buildQuietReflection(totalDurationMinutes, centeringWord);
      case MeditationStyle.bible:
        return _buildBible(totalDurationMinutes, bibleTemplate, customBibleVerses);
      case MeditationStyle.affirmation:
        return _buildAffirmation(
          totalDurationMinutes,
          affirmationCategory,
          virtueAffirmation,
          habitAffirmation,
        );
      case MeditationStyle.chant:
        return _buildChant(totalDurationMinutes);
    }
  }

  static GuidedMeditationContent _buildQuietReflection(int minutes, String? centeringWord) {
    final word = centeringWord ?? 'Jesus';
    
    return GuidedMeditationContent(
      style: MeditationStyle.quietReflection,
      totalDurationMinutes: minutes,
      backgroundTheme: 'Sacred stillness and divine presence',
      openingPrayer: 'Lord, meet me in this quiet space.',
      closingPrayer: 'May Your peace go with me.',
      phases: [
        // Phase 1: Breathing
        GuidedPhaseContent(
          phase: GuidedPhase.breathing,
          title: 'Arrive in Stillness',
          instruction: 'Close your eyes and settle into your breathing',
          spokenText: 'Welcome to this sacred pause. Find a comfortable position and gently close your eyes. Let your body settle and your breathing become natural. There\'s nothing to fix, nothing to achieve. Just be here, now, in God\'s presence.',
          breathingCue: 'Breathe in peace... breathe out tension...',
          durationSeconds: (minutes * 60 * 0.15).round(),
        ),
        
        // Phase 2: Scenery Journey
        GuidedPhaseContent(
          phase: GuidedPhase.sceneryJourney,
          title: 'Journey to Sacred Space',
          instruction: 'Visualize a peaceful path leading toward God\'s presence',
          spokenText: 'Imagine a gentle path before you. Perhaps it winds through a quiet forest, or along peaceful shores. With each step, you feel lighter, more free. The burdens you\'ve been carrying begin to fall away like autumn leaves. You are walking toward a sacred space where God waits for you. The air grows warmer, filled with divine light. You are almost there.',
          imagery: 'A winding path through peaceful nature, leading toward warm, divine light',
          focusPoint: 'Feel the release with each step forward',
          durationSeconds: (minutes * 60 * 0.35).round(),
        ),
        
        // Phase 3: Focus/Prayer
        GuidedPhaseContent(
          phase: GuidedPhase.focusPrayer,
          title: 'Rest in Divine Presence',
          instruction: 'Rest in the awareness of God\'s loving presence',
          spokenText: 'You have arrived in the sanctuary of God\'s presence. Here, you are fully known and completely loved. There is no judgment here, only grace. Let your sacred word, "$word", become your anchor. When thoughts arise, gently return to "$word". You are held. You are safe. You are home.',
          focusPoint: 'Repeat gently: "$word"',
          durationSeconds: (minutes * 60 * 0.35).round(),
        ),
        
        // Phase 4: Closing
        GuidedPhaseContent(
          phase: GuidedPhase.closing,
          title: 'Return with Peace',
          instruction: 'Gently prepare to return, carrying this peace forward',
          spokenText: 'Slowly begin to return your awareness to the present moment. Notice the peace that fills you. This peace doesn\'t end here – you carry it with you. As you open your eyes, know that you can return to this sacred space anytime, simply by breathing and remembering "$word". You go forth blessed and loved.',
          breathingCue: 'One deep breath in... one long breath out...',
          durationSeconds: (minutes * 60 * 0.15).round(),
        ),
      ],
    );
  }

  static GuidedMeditationContent _buildBible(int minutes, BibleTemplate? template, String? customVerses) {
    final resolvedTemplate = template ?? BibleTemplate.parables;
    final verseText = customVerses ?? _getSampleVerse(resolvedTemplate);
    
    return GuidedMeditationContent(
      style: MeditationStyle.bible,
      totalDurationMinutes: minutes,
      backgroundTheme: 'Sacred Scripture and divine revelation',
      openingPrayer: 'Lord, speak to me through Your Word.',
      closingPrayer: 'May Your truth transform my heart.',
      phases: [
        // Phase 1: Breathing
        GuidedPhaseContent(
          phase: GuidedPhase.breathing,
          title: 'Prepare Your Heart',
          instruction: 'Breathe deeply and prepare to receive God\'s Word',
          spokenText: 'Come into God\'s presence with an open heart. Let each breath create space for the Scriptures to speak. Breathe in expectation... breathe out distraction... You are entering holy ground where God meets you in His Word.',
          breathingCue: 'Breathe in reverence... breathe out noise...',
          durationSeconds: (minutes * 60 * 0.15).round(),
        ),
        
        // Phase 2: Scenery Journey
        GuidedPhaseContent(
          phase: GuidedPhase.sceneryJourney,
          title: 'Enter the Biblical Story',
          instruction: 'Step inside the Scripture passage as if you were there',
          spokenText: 'The words before you are not just text – they are a doorway into God\'s story. Imagine yourself entering this scene. What do you see? What do you hear? Feel the warmth of Jesus\' presence, or the wisdom of the psalmist. This is your story too, written by God for you. Let the words come alive around you.',
          imagery: 'Stepping into the biblical scene, feeling the presence of Jesus and the disciples',
          focusPoint: 'You are part of God\'s ongoing story',
          durationSeconds: (minutes * 60 * 0.35).round(),
        ),
        
        // Phase 3: Focus/Prayer
        GuidedPhaseContent(
          phase: GuidedPhase.focusPrayer,
          title: 'Meditate on the Truth',
          instruction: 'Rest in the truth of this Scripture',
          spokenText: 'Let the words settle deep in your heart: "$verseText". This is not just information – this is transformation. Let this truth reshape how you see yourself, how you see God, how you see your world. What is God saying to you, right here, right now, through these ancient words made new today?',
          focusPoint: 'Let the truth become prayer in your heart',
          durationSeconds: (minutes * 60 * 0.35).round(),
        ),
        
        // Phase 4: Closing
        GuidedPhaseContent(
          phase: GuidedPhase.closing,
          title: 'Carry the Word',
          instruction: 'Prepare to carry this truth into your day',
          spokenText: 'The Scripture doesn\'t end here – it goes with you. As you prepare to return, hold onto one phrase that resonated deeply. Let it be your companion through the day. God\'s Word is living and active, and it will continue to work in you long after this moment of stillness ends.',
          breathingCue: 'Breathe in God\'s truth... breathe out to share it...',
          durationSeconds: (minutes * 60 * 0.15).round(),
        ),
      ],
    );
  }

  static GuidedMeditationContent _buildAffirmation(
    int minutes,
    AffirmationCategory? category,
    VirtueAffirmation? virtueAffirmation,
    HabitAffirmation? habitAffirmation,
  ) {
    final resolvedCategory = category ?? AffirmationCategory.growVirtue;
    final isVirtue = resolvedCategory == AffirmationCategory.growVirtue;
    
    // Get the appropriate affirmation and its properties
    final String affirmationTitle;
    final String affirmationText;
    
    if (isVirtue) {
      final affirmation = virtueAffirmation ?? VirtueAffirmation.selfControl;
      affirmationTitle = affirmation.title;
      affirmationText = affirmation.text;
    } else {
      final affirmation = habitAffirmation ?? HabitAffirmation.lust;
      affirmationTitle = affirmation.title;
      affirmationText = affirmation.text;
    }
    
    return GuidedMeditationContent(
      style: MeditationStyle.affirmation,
      totalDurationMinutes: minutes,
      backgroundTheme: 'Spiritual growth and transformation',
      openingPrayer: 'Lord, shape me into Your likeness.',
      closingPrayer: 'May Your truth empower my life.',
      phases: [
        // Phase 1: Breathing
        GuidedPhaseContent(
          phase: GuidedPhase.breathing,
          title: 'Create Space for Change',
          instruction: 'Breathe and prepare for spiritual transformation',
          spokenText: 'Welcome this opportunity for growth. Each breath creates space for God to work in you. Breathe in possibility... breathe out limitation... You are not here to try harder, but to surrender more fully to God\'s transforming grace.',
          breathingCue: 'Breathe in grace... breathe out resistance...',
          durationSeconds: (minutes * 60 * 0.15).round(),
        ),
        
        // Phase 2: Scenery Journey
        GuidedPhaseContent(
          phase: GuidedPhase.sceneryJourney,
          title: 'Journey to Freedom',
          instruction: 'Visualize the path to spiritual freedom or virtue',
          spokenText: 'Imagine a garden where God is growing something beautiful in you. If you\'re growing in ${affirmationTitle.toLowerCase()}, see it as a mighty tree taking root. If you\'re finding freedom from ${affirmationTitle.toLowerCase()}, see chains falling away. This is God\'s work in you – not your effort, but His grace creating something new.',
          imagery: isVirtue 
              ? 'A mighty tree of ${affirmationTitle.toLowerCase()} growing in God\'s garden'
              : 'Chains of ${affirmationTitle.toLowerCase()} falling away in God\'s light',
          focusPoint: 'God is the one who transforms',
          durationSeconds: (minutes * 60 * 0.35).round(),
        ),
        
        // Phase 3: Focus/Prayer
        GuidedPhaseContent(
          phase: GuidedPhase.focusPrayer,
          title: 'Embody the Truth',
          instruction: 'Let the affirmation become your reality',
          spokenText: 'The truth you need is this: "$affirmationText". Let these words sink deeper than your mind – into your heart, your body, your spirit. This is not just something you say, but something you become. God is making this true in you, moment by moment, choice by choice.',
          focusPoint: 'Repeat gently: "$affirmationText"',
          durationSeconds: (minutes * 60 * 0.35).round(),
        ),
        
        // Phase 4: Closing
        GuidedPhaseContent(
          phase: GuidedPhase.closing,
          title: 'Live Transformed',
          instruction: 'Prepare to live this transformation',
          spokenText: 'As you return, know that this transformation continues. God doesn\'t just meet you in stillness – He goes with you into every moment, every choice, every challenge. You carry within you the seed of ${isVirtue ? 'virtue' : 'freedom'} that God is growing. Trust His work in you.',
          breathingCue: 'Breathe in transformation... breathe out to live it...',
          durationSeconds: (minutes * 60 * 0.15).round(),
        ),
      ],
    );
  }

  static GuidedMeditationContent _buildChant(int minutes) {
    return GuidedMeditationContent(
      style: MeditationStyle.chant,
      totalDurationMinutes: minutes,
      backgroundTheme: 'Sacred music and divine praise',
      openingPrayer: 'Lord, receive my song of praise.',
      closingPrayer: 'May my heart continue to sing Your praise.',
      phases: [
        // Phase 1: Breathing
        GuidedPhaseContent(
          phase: GuidedPhase.breathing,
          title: 'Prepare to Sing',
          instruction: 'Settle your body and prepare for sacred music',
          spokenText: 'Welcome to this time of worship through song. Let your breathing become the rhythm that will carry the chant. There\'s no performance here – only offering. Breathe in readiness... breathe out hesitation... Your voice matters to God.',
          breathingCue: 'Breathe in praise... breathe out self-consciousness...',
          durationSeconds: (minutes * 60 * 0.15).round(),
        ),
        
        // Phase 2: Scenery Journey
        GuidedPhaseContent(
          phase: GuidedPhase.sceneryJourney,
          title: 'Join the Heavenly Choir',
          instruction: 'Visualize your voice joining with angels and saints',
          spokenText: 'Imagine yourself in a vast cathedral or open field. All around you, voices are rising to heaven – angels, saints, believers throughout time. Your voice joins this eternal chorus. The music flows not from your throat alone, but from the Spirit within you. You are part of something much bigger than yourself.',
          imagery: 'A heavenly choir of voices rising together in worship',
          focusPoint: 'Your voice adds to the eternal song',
          durationSeconds: (minutes * 60 * 0.35).round(),
        ),
        
        // Phase 3: Focus/Prayer
        GuidedPhaseContent(
          phase: GuidedPhase.focusPrayer,
          title: 'Sing as Prayer',
          instruction: 'Let the chant become your prayer',
          spokenText: 'Now let the chant flow through you. Each note is a prayer, each word a declaration of love. Don\'t think about technique – think about offering. Let the melody carry your heart to places words alone cannot reach. This is intimate worship between you and God.',
          focusPoint: 'Let the music become prayer',
          durationSeconds: (minutes * 60 * 0.35).round(),
        ),
        
        // Phase 4: Closing
        GuidedPhaseContent(
          phase: GuidedPhase.closing,
          title: 'Carry the Song',
          instruction: 'Prepare to carry the melody in your heart',
          spokenText: 'As the music fades, the prayer continues in your heart. The melody doesn\'t end here – it becomes the background music of your day. You can return to this song anytime, humming it quietly, letting it remind you of God\'s presence. You go forth still singing.',
          breathingCue: 'Breathe in the melody... breathe out gratitude...',
          durationSeconds: (minutes * 60 * 0.15).round(),
        ),
      ],
    );
  }

  static String _getSampleVerse(BibleTemplate template) {
    switch (template) {
      case BibleTemplate.parables:
        return 'The kingdom of heaven is like a mustard seed...';
      case BibleTemplate.profoundVerses:
        return 'For God so loved the world...';
      case BibleTemplate.blessedProverbs:
        return 'Trust in the LORD with all your heart...';
      case BibleTemplate.psalmsOfComfort:
        return 'The LORD is my shepherd...';
      case BibleTemplate.promisesOfHope:
        return 'Do not fear, for I have redeemed you...';
      case BibleTemplate.miraclesOfJesus:
        return 'Immediately her bleeding stopped...';
      case BibleTemplate.kingdomEthics:
        return 'Blessed are the poor in spirit...';
      case BibleTemplate.lettersOfEncouragement:
        return 'Do not be anxious about anything...';
      case BibleTemplate.custom:
        return 'Your chosen Scripture...';
    }
  }
}
