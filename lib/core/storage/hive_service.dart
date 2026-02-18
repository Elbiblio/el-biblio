import 'package:hive_flutter/hive_flutter.dart';

import '../../features/bible/domain/models/bible_verse.dart';
import '../../features/journal/domain/models/journal_entry.dart';
import '../../features/meditation/domain/models/meditation_session.dart';
import '../../features/today/domain/models/daily_anchors.dart';
import 'hive_boxes.dart';

class HiveService {
  const HiveService._();

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _registerAdapters();

    await Future.wait(<Future<void>>[
      Hive.openBox<dynamic>(HiveBoxes.settings),
      Hive.openBox<DailyAnchors>(HiveBoxes.dailyAnchors),
      Hive.openBox<Virtue>(HiveBoxes.virtues),
      Hive.openBox<JournalEntry>(HiveBoxes.journalEntries),
      Hive.openBox<BibleVerse>(HiveBoxes.bibleVerses),
      Hive.openBox<MeditationSession>(HiveBoxes.meditationSessions),
    ]);
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VirtueTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HabitTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AnchorTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(VirtueAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(EnergyActionAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(DailyAnchorsAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(JournalEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(BibleVerseAdapter());
    }
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(MeditationSessionAdapter());
    }
  }
}
