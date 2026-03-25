import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/bible/domain/models/bible_verse.dart';
import '../../features/journal/domain/models/note.dart';
import '../../features/meditation/domain/models/meditation_session.dart';
import '../../features/spiritual_aid/data/spiritual_aid_repository.dart';
import '../../features/today/domain/models/daily_anchors.dart';
import 'hive_boxes.dart';

class HiveService {
  const HiveService._();

  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _registerAdapters();

      // Open only essential boxes first
      await Future.wait(<Future<void>>[
        _safeOpenBox<dynamic>(HiveBoxes.settings),
        _safeOpenBox<DailyAnchors>(HiveBoxes.dailyAnchors),
        _safeOpenBox<Virtue>(HiveBoxes.virtues),
        _safeOpenBox<dynamic>(HiveBoxes.xpActivities),
        _safeOpenBox<int>(HiveBoxes.xpTotals),
      ]);
      
      // Defer less critical boxes
      Future.microtask(() async {
        await Future.wait(<Future<void>>[
          _safeOpenBox<Note>(HiveBoxes.journalEntries),
          _safeOpenBox<BibleVerse>(HiveBoxes.bibleVerses),
          _safeOpenBox<MeditationSession>(HiveBoxes.meditationSessions),
          _safeOpenBox<dynamic>(HiveBoxes.appLockConfigs),
          _safeOpenBox<dynamic>(HiveBoxes.appLockUsage),
          SpiritualAidRepository.initializeBoxes(),
          _safeOpenBox<dynamic>(HiveBoxes.alignment),
        ]);
      });
    } catch (e) {
      debugPrint('Hive initialization failed: $e');
      // If initialization fails, try to clear corrupted data and retry
      debugPrint('Attempting to clear corrupted Hive data and retry...');
      await Hive.close();
      await _clearHiveData();
      await Hive.initFlutter();
      _registerAdapters();
      
      // Open essential boxes first
      await Future.wait(<Future<void>>[
        Hive.openBox<dynamic>(HiveBoxes.settings),
        Hive.openBox<DailyAnchors>(HiveBoxes.dailyAnchors),
        Hive.openBox<Virtue>(HiveBoxes.virtues),
        Hive.openBox<dynamic>(HiveBoxes.xpActivities),
        Hive.openBox<int>(HiveBoxes.xpTotals),
      ]);
      
      // Defer less critical boxes
      Future.microtask(() async {
        await Future.wait(<Future<void>>[
          Hive.openBox<Note>(HiveBoxes.journalEntries),
          Hive.openBox<BibleVerse>(HiveBoxes.bibleVerses),
          Hive.openBox<MeditationSession>(HiveBoxes.meditationSessions),
          Hive.openBox<dynamic>(HiveBoxes.appLockConfigs),
          Hive.openBox<dynamic>(HiveBoxes.appLockUsage),
          SpiritualAidRepository.initializeBoxes(),
          Hive.openBox<dynamic>(HiveBoxes.alignment),
        ]);
      });
    }
  }

  static Future<void> _safeOpenBox<T>(String boxName) async {
    try {
      await Hive.openBox<T>(boxName);
    } catch (e) {
      debugPrint('Failed to open box $boxName: $e');
      // Try to delete corrupted box and recreate it
      try {
        await Hive.deleteBoxFromDisk(boxName);
        debugPrint('Deleted corrupted box: $boxName');
        await Hive.openBox<T>(boxName);
        debugPrint('Successfully recreated box: $boxName');
      } catch (deleteError) {
        debugPrint('Failed to delete and recreate box $boxName: $deleteError');
        rethrow;
      }
    }
  }

  static Future<void> _clearHiveData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDir.path}/hive');
      if (await hiveDir.exists()) {
        await hiveDir.delete(recursive: true);
        debugPrint('Cleared corrupted Hive data directory');
      }
    } catch (e) {
      debugPrint('Failed to clear Hive data: $e');
    }
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
      Hive.registerAdapter(NoteAdapter());
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(BibleVerseAdapter());
    }
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(MeditationSessionAdapter());
    }
  }
}
