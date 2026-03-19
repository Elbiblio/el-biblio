import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/meditation_session.dart';

class MeditationSessionRepository {
  const MeditationSessionRepository(this._box);

  final Box<MeditationSession> _box;

  Future<void> saveSession(MeditationSession session) async {
    await _box.put(session.id, session);
  }

  List<MeditationSession> getAllSessions() {
    return _box.values.toList();
  }

  MeditationSession? getSession(String id) {
    return _box.get(id);
  }

  Future<void> deleteSession(String id) async {
    await _box.delete(id);
  }
  
  Future<void> clearAll() async {
    await _box.clear();
  }
}
