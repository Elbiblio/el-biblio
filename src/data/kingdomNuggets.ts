import { Platform } from 'react-native';

export type NuggetTag =
  | 'purity'
  | 'stewardship'
  | 'self_control'
  | 'focus'
  | 'relationships'
  | 'humility'
  | 'purpose'
  | 'courage'
  | 'gratitude'
  | 'generosity'
  | 'wisdom'
  | 'identity'
  | 'trust'
  | 'obedience'
  | 'service'
  | 'discernment'
  | 'joy'
  | 'contentment'
  | 'repentance';

export interface KingdomNugget {
  id: string;
  text: string;
  scriptureRefs?: string[];
  tags: NuggetTag[];
  deliveryHints: {
    moments: string[];
    uiPlacements: string[];
  };
  tone: 'encourage' | 'challenge' | 'remind';
  source: string;
}

export const KINGDOM_NUGGETS: KingdomNugget[] = [
  {
    id: 'body-temple-discipline',
    text: 'Habits change fastest when we keep saying “yes” to the Holy Spirit in the small moments.',
    scriptureRefs: ['Luke 16:11'],
    tags: ['purity', 'self_control', 'stewardship'],
    deliveryHints: {
      moments: ['meditation_completed', 'habit_session_finished', 'challenge_streak_3'],
      uiPlacements: ['meditation_summary', 'habit_conquest_feed'],
    },
    tone: 'encourage',
    source: 'kingdom.md#1-70',
  },
  {
    id: 'purpose-over-escape',
    text: 'Choosing purpose over quick escapes keeps you aligned with God’s eternal story.',
    scriptureRefs: ['1 Corinthians 6:19-20'],
    tags: ['purpose', 'purity', 'focus'],
    deliveryHints: {
      moments: ['verse_saved_self_control', 'note_tagged_purpose'],
      uiPlacements: ['verse_highlight_banner', 'daily_digest_notification'],
    },
    tone: 'challenge',
    source: 'kingdom.md#72-133',
  },
  {
    id: 'dignity-not-deals',
    text: 'Stolen shortcuts break trust and cost your God-given dignity—choose integrity even when unseen.',
    scriptureRefs: ['Proverbs 10:9'],
    tags: ['stewardship', 'identity', 'trust'],
    deliveryHints: {
      moments: ['community_like_integrity', 'reflection_on_honesty'],
      uiPlacements: ['community_feed_helper', 'evening_review'],
    },
    tone: 'challenge',
    source: 'kingdom.md#103-133',
  },
  {
    id: 'influence-by-love',
    text: 'Control pushes people away; love draws them close. Use your strength to serve, not to dominate.',
    scriptureRefs: ['Ephesians 4:2'],
    tags: ['relationships', 'service', 'humility'],
    deliveryHints: {
      moments: ['comment_submitted', 'conflict_detected'],
      uiPlacements: ['comment_hint', 'notifications_relational'],
    },
    tone: 'remind',
    source: 'kingdom.md#134-163',
  },
  {
    id: 'run-your-race',
    text: 'Your blessings wait in your lane—envy only pauses the progress God planned for you.',
    scriptureRefs: ['Galatians 6:4'],
    tags: ['purpose', 'contentment', 'gratitude'],
    deliveryHints: {
      moments: ['leaderboard_viewed', 'comparison_signal'],
      uiPlacements: ['leaderboard_banner', 'daily_digest_notification'],
    },
    tone: 'remind',
    source: 'kingdom.md#165-194',
  },
  {
    id: 'body-temple-investment',
    text: 'When you steward your body as God’s temple, clarity, energy, and relational trust multiply.',
    scriptureRefs: ['1 Corinthians 6:19-20'],
    tags: ['purity', 'stewardship', 'self_control'],
    deliveryHints: {
      moments: ['habit_goal_completed', 'meditation_streak_5'],
      uiPlacements: ['habit_progress_card', 'meditation_summary'],
    },
    tone: 'encourage',
    source: 'kingdom.md#201-228',
  },
  {
    id: 'vision-investment',
    text: 'Pure vision lets you spot divine opportunities others walk past—guard what enters your eyes.',
    scriptureRefs: ['Matthew 6:22-23'],
    tags: ['discernment', 'focus', 'wisdom'],
    deliveryHints: {
      moments: ['verse_saved_discernment', 'note_on_focus'],
      uiPlacements: ['verse_reader_overlay', 'reading_plan_reminder'],
    },
    tone: 'challenge',
    source: 'kingdom.md#230-257',
  },
  {
    id: 'character-investment',
    text: 'God entrusts greater authority to the trustworthy—humility today opens influence tomorrow.',
    scriptureRefs: ['James 4:6'],
    tags: ['humility', 'service', 'purpose'],
    deliveryHints: {
      moments: ['reflection_published', 'challenge_completed'],
      uiPlacements: ['reflection_publish_success', 'virtue_progress_modal'],
    },
    tone: 'encourage',
    source: 'kingdom.md#259-286',
  },
  {
    id: 'purpose-investment',
    text: 'Comfort is expensive—every sacrifice for Jesus returns eternal impact a hundredfold.',
    scriptureRefs: ['Mark 10:29-30'],
    tags: ['purpose', 'courage', 'obedience'],
    deliveryHints: {
      moments: ['challenge_joined', 'reading_plan_streak'],
      uiPlacements: ['daily_digest_notification', 'journey_phase_banner'],
    },
    tone: 'challenge',
    source: 'kingdom.md#288-315',
  },
  {
    id: 'cure-for-desire',
    text: 'Willpower plus grace breaks cycles of desire—invite God into the choices you can’t make alone.',
    scriptureRefs: ['1 John 3:9'],
    tags: ['self_control', 'purity', 'trust'],
    deliveryHints: {
      moments: ['note_about_temptation', 'habit_relapse_logged'],
      uiPlacements: ['habit_conquest_support', 'evening_review'],
    },
    tone: 'remind',
    source: 'kingdom.md#319-336',
  },
  {
    id: 'detox-the-soul',
    text: 'Spiritual detox starts by fasting from the voices that poison your heart.',
    scriptureRefs: ['Romans 12:2'],
    tags: ['self_control', 'discernment', 'purity'],
    deliveryHints: {
      moments: ['meditation_planning', 'journal_entry_negativity'],
      uiPlacements: ['meditation_setup_tip', 'reflection_compose_banner'],
    },
    tone: 'challenge',
    source: 'kingdom.md#347-358',
  },
  {
    id: 'ask-for-spirit',
    text: 'The best prayer you can make today: “Father, give me more of Your Spirit.”',
    scriptureRefs: ['Luke 11:13'],
    tags: ['trust', 'obedience', 'joy'],
    deliveryHints: {
      moments: ['morning_check_in', 'prayer_request_created'],
      uiPlacements: ['home_top_card', 'prayer_requests_intro'],
    },
    tone: 'encourage',
    source: 'kingdom.md#353-356',
  },
  {
    id: 'path-to-holiness',
    text: 'Holiness is walking in step with God’s will so closely that obedience feels like breathing.',
    scriptureRefs: ['John 15:4-5'],
    tags: ['obedience', 'purpose', 'joy'],
    deliveryHints: {
      moments: ['journey_phase_started', 'reading_plan_milestone'],
      uiPlacements: ['journey_dashboard', 'reading_plan_header'],
    },
    tone: 'encourage',
    source: 'kingdom.md#360-375',
  },
  {
    id: 'communication-with-god',
    text: 'Every six hours, pause to check your soul—constant conversation keeps you close to God.',
    scriptureRefs: ['1 Thessalonians 5:17'],
    tags: ['obedience', 'focus', 'service'],
    deliveryHints: {
      moments: ['no_activity_half_day'],
      uiPlacements: Platform.select({ ios: ['push_quiet_time'], android: ['push_quiet_time'], default: ['daily_digest_notification'] }) ?? ['daily_digest_notification'],
    },
    tone: 'remind',
    source: 'kingdom.md#371-374',
  },
  {
    id: 'fear-of-god-wisdom',
    text: 'Holy fear is wise awe—reserve your fear for the One who holds your life.',
    scriptureRefs: ['Proverbs 9:10'],
    tags: ['wisdom', 'discernment', 'identity'],
    deliveryHints: {
      moments: ['verse_saved_wisdom', 'meditation_selected_parable'],
      uiPlacements: ['verse_reader_overlay', 'meditation_summary'],
    },
    tone: 'remind',
    source: 'kingdom.md#377-384',
  },
  {
    id: 'service-without-credit',
    text: 'Serve quietly even when unseen—heaven keeps better score than any leaderboard.',
    scriptureRefs: ['Matthew 6:4'],
    tags: ['service', 'humility', 'gratitude'],
    deliveryHints: {
      moments: ['challenge_service_completed', 'leaderboard_viewed'],
      uiPlacements: ['leaderboard_banner', 'challenge_completion_modal'],
    },
    tone: 'remind',
    source: 'kingdom.md#320-344',
  },
  {
    id: 'joy-of-contentment',
    text: 'Contentment is the pure joy God gives those who trust His timeline over their own.',
    scriptureRefs: ['Philippians 4:11-12'],
    tags: ['contentment', 'trust', 'joy'],
    deliveryHints: {
      moments: ['gratitude_note_created', 'journaling_session'],
      uiPlacements: ['note_editor_tip', 'evening_review'],
    },
    tone: 'encourage',
    source: 'kingdom.md#332-339',
  },
  {
    id: 'identity-reminder',
    text: 'When you forget who you are, remember whose you are—beloved children regain their strength.',
    scriptureRefs: ['Romans 8:16-17'],
    tags: ['identity', 'trust', 'purpose'],
    deliveryHints: {
      moments: ['streak_broken', 'reflection_draft_saved'],
      uiPlacements: ['streak_recovery_modal', 'reflection_compose_banner'],
    },
    tone: 'encourage',
    source: 'kingdom.md#333-338',
  },
  {
    id: 'return-to-father',
    text: 'If you feel far from God, run home—the Father is already watching and ready to restore you.',
    scriptureRefs: ['Luke 15:20'],
    tags: ['repentance', 'joy', 'identity'],
    deliveryHints: {
      moments: ['long_inactivity', 'confession_note_created'],
      uiPlacements: ['welcome_back_modal', 'prayer_requests_intro'],
    },
    tone: 'encourage',
    source: 'kingdom.md#335-338',
  },
  {
    id: 'gratitude-guardrail',
    text: 'Gratitude keeps you aligned with God’s justice—remember His goodness before the day pulls you away.',
    scriptureRefs: ['Psalm 103:2'],
    tags: ['gratitude', 'trust', 'joy'],
    deliveryHints: {
      moments: ['morning_check_in', 'gratitude_challenge'],
      uiPlacements: ['home_top_card', 'challenge_reminder'],
    },
    tone: 'remind',
    source: 'kingdom.md#334-339',
  },
  {
    id: 'sow-generously',
    text: 'Generosity opens unexpected doors—your hospitality can set the atmosphere for God’s work.',
    scriptureRefs: ['2 Corinthians 9:6-8'],
    tags: ['generosity', 'service', 'joy'],
    deliveryHints: {
      moments: ['resource_shared', 'community_support_action'],
      uiPlacements: ['community_feed_helper', 'journey_phase_banner'],
    },
    tone: 'encourage',
    source: 'kingdom.md#58-315',
  },
  {
    id: 'watchful-discernment',
    text: 'Stay spiritually alert—discernment keeps you from trading divine purpose for shiny counterfeits.',
    scriptureRefs: ['1 Peter 5:8'],
    tags: ['discernment', 'focus', 'obedience'],
    deliveryHints: {
      moments: ['night_time_scroll', 'verse_saved_watchfulness'],
      uiPlacements: ['evening_review', 'verse_reader_overlay'],
    },
    tone: 'challenge',
    source: 'kingdom.md#53-70',
  },
];

export const NUGGET_COOLDOWN_HOURS = 36;
