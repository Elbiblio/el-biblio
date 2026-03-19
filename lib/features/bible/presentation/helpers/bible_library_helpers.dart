import 'package:flutter/material.dart';

import '../../../../shared/domain/models/activity.dart';
import '../../domain/models/reading_plan.dart';
import '../../application/bible_reading_notifier.dart';

// ---------------------------------------------------------------------------
// Activity parsing
// ---------------------------------------------------------------------------

Map<String, dynamic> extractReadingInfo(Activity activity) {
  final metadata = activity.metadata;
  String? book = metadata?['book']?.toString();
  book ??= metadata?['book_name']?.toString();
  int? chapter = asInt(metadata?['chapter']);
  int? verse = asInt(metadata?['verse']);

  if ((book == null || book.isEmpty) && metadata?['chapters_read'] != null) {
    final rawChaptersRead = metadata?['chapters_read'];
    final chaptersRead =
        rawChaptersRead is List ? rawChaptersRead : <dynamic>[rawChaptersRead];
    if (chaptersRead.isNotEmpty) {
      final chapterStr = chaptersRead.first.toString();
      final lastSpaceIndex = chapterStr.lastIndexOf(' ');
      if (lastSpaceIndex != -1) {
        book = chapterStr.substring(0, lastSpaceIndex);
        chapter =
            int.tryParse(chapterStr.substring(lastSpaceIndex + 1)) ?? chapter;
      } else {
        book = chapterStr;
      }
    }
  }

  if ((book == null || book.isEmpty) && metadata?['reference'] != null) {
    final parsed = parseReference(metadata!['reference'].toString());
    book = parsed['book'] as String?;
    chapter ??= parsed['chapter'] as int?;
    verse ??= parsed['verse'] as int?;
  }

  return {
    'book': book ?? 'Genesis',
    'chapter': chapter ?? 1,
    'verse': verse,
  };
}

String getTestamentFromActivity(Activity activity) {
  final bookName = extractReadingInfo(activity)['book'] as String;
  const oldTestamentBooks = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua',
    'Judges', 'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings',
    '1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther',
    'Job', 'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon',
    'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel',
    'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah',
    'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
  ];
  return oldTestamentBooks.contains(bookName)
      ? 'OLD TESTAMENT'
      : 'NEW TESTAMENT';
}

String getBookFromActivity(Activity activity) =>
    extractReadingInfo(activity)['book'] as String;

String getChapterFromActivity(Activity activity) =>
    'Chapter ${extractReadingInfo(activity)['chapter']}';

double getProgressFromActivity(Activity activity) {
  final raw = activity.metadata?['progress'];
  final parsed = asDouble(raw);
  if (parsed == null) return 0.5;
  return parsed.clamp(0.0, 1.0);
}

String getLocationFromActivity(Activity activity) {
  final info = extractReadingInfo(activity);
  final book = info['book'];
  final chapter = info['chapter'];
  final verse = info['verse'];
  if (verse != null) return '$book $chapter:$verse';
  return '$book $chapter';
}

// ---------------------------------------------------------------------------
// Greeting
// ---------------------------------------------------------------------------

String getMotivationalGreeting(BibleReadingState readingState) {
  if (readingState.history.isEmpty) return 'Begin Your Journey';
  final streak = readingState.currentStreak;
  final totalDays = readingState.totalDays;
  if (streak >= 30) return 'Bible Warrior';
  if (streak >= 14) return 'Devoted Reader';
  if (streak >= 7) return 'Growing Strong';
  if (streak >= 3) return 'Building Momentum';
  if (totalDays >= 1) return 'Keep Going';
  return 'Welcome Back';
}

String getMotivationalSubtitle(BibleReadingState readingState) {
  if (readingState.history.isEmpty) {
    return 'Start your daily reading habit today';
  }
  final streak = readingState.currentStreak;
  final totalDays = readingState.totalDays;
  final lastRead = readingState.lastReadingDate;

  if (streak >= 30) return '$streak day streak - Unstoppable!';
  if (streak >= 14) return '$streak day streak - Amazing consistency!';
  if (streak >= 7) return '$streak day streak - You\'re on fire!';
  if (streak >= 3) return '$streak day streak - Great momentum!';
  if (streak == 1) return '1 day streak - Keep it going!';
  if (lastRead != null) {
    final daysSince = DateTime.now().difference(lastRead).inDays;
    if (daysSince == 1) return 'Continue your streak today';
    if (daysSince <= 3) return 'Pick up where you left off';
    return 'Time to reignite your journey';
  }
  return '$totalDays days completed - Keep growing';
}

// ---------------------------------------------------------------------------
// Plan / Theme helpers
// ---------------------------------------------------------------------------

String getVirtueFromPlan(ReadingPlan? plan) {
  switch (plan?.themeId) {
    case 'humility': return 'HUMILITY';
    case 'faith': return 'FAITH';
    case 'love': return 'LOVE';
    case 'knowledge': return 'KNOWLEDGE';
    case 'grace': return 'GRACE';
    case 'wisdom': return 'WISDOM';
    case 'courage': return 'COURAGE';
    case 'hope': return 'HOPE';
    case 'joy': return 'JOY';
    case 'peace': return 'PEACE';
    case 'patience': return 'PATIENCE';
    case 'kindness': return 'KINDNESS';
    case 'goodness': return 'GOODNESS';
    case 'faithfulness': return 'FAITHFULNESS';
    case 'gentleness': return 'GENTLENESS';
    case 'self_control': return 'SELF-CONTROL';
    default: return 'GROWTH';
  }
}

Color getVirtueColor(String? themeId) {
  switch (themeId) {
    case 'humility': return Colors.brown.shade600;
    case 'faith': return Colors.blue.shade500;
    case 'love': return Colors.red.shade500;
    case 'knowledge': return Colors.indigo.shade500;
    case 'grace': return Colors.purple.shade500;
    case 'wisdom': return Colors.amber.shade600;
    case 'courage': return Colors.orange.shade600;
    case 'hope': return Colors.lightBlue.shade500;
    case 'joy': return Colors.yellow.shade600;
    case 'peace': return Colors.green.shade500;
    case 'patience': return Colors.teal.shade500;
    case 'kindness': return Colors.pink.shade500;
    case 'goodness': return Colors.lime.shade600;
    case 'faithfulness': return Colors.blue.shade700;
    case 'gentleness': return Colors.purple.shade300;
    case 'self_control': return Colors.grey.shade600;
    default: return Colors.teal.shade500;
  }
}

List<Color> getGradientColors(String? themeId) {
  switch (themeId) {
    case 'humility': return [Colors.brown.shade400, Colors.brown.shade700];
    case 'faith': return [Colors.blue.shade400, Colors.blue.shade700];
    case 'love': return [Colors.red.shade400, Colors.pink.shade700];
    case 'knowledge': return [Colors.indigo.shade400, Colors.indigo.shade700];
    case 'grace': return [Colors.purple.shade400, Colors.purple.shade700];
    case 'wisdom': return [Colors.orange.shade400, Colors.orange.shade700];
    case 'courage': return [Colors.deepOrange.shade400, Colors.deepOrange.shade700];
    case 'hope': return [Colors.lightBlue.shade400, Colors.blue.shade600];
    case 'joy': return [Colors.yellow.shade400, Colors.amber.shade700];
    case 'peace': return [Colors.green.shade400, Colors.green.shade700];
    case 'patience': return [Colors.teal.shade400, Colors.teal.shade700];
    case 'kindness': return [Colors.pink.shade400, Colors.pink.shade700];
    case 'goodness': return [Colors.lime.shade400, Colors.green.shade600];
    case 'faithfulness': return [Colors.blue.shade500, Colors.blue.shade800];
    case 'gentleness': return [Colors.purple.shade300, Colors.purple.shade600];
    case 'self_control': return [Colors.grey.shade400, Colors.grey.shade700];
    default: return [Colors.teal.shade400, Colors.cyan.shade700];
  }
}

double calculatePlanProgress(int currentDay, int? durationDays) {
  final safeDuration = (durationDays ?? 0) > 0 ? durationDays! : 1;
  return (currentDay / safeDuration).clamp(0.0, 1.0);
}

// ---------------------------------------------------------------------------
// Generic utilities
// ---------------------------------------------------------------------------

int? asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double? asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

Map<String, dynamic> parseReference(String reference) {
  final match =
      RegExp(r'^\s*(.+?)\s+(\d+)(?::(\d+))?').firstMatch(reference);
  if (match == null) {
    return const {'book': null, 'chapter': null, 'verse': null};
  }
  return {
    'book': match.group(1)?.trim(),
    'chapter': int.tryParse(match.group(2) ?? ''),
    'verse': int.tryParse(match.group(3) ?? ''),
  };
}

String formatDate(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);
  if (difference.inDays == 0) {
    return 'Today at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  } else if (difference.inDays == 1) {
    return 'Yesterday at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
