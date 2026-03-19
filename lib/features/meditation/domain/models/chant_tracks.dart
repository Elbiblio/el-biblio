enum ChantId {
  tenThousandReasons('10000-reasons'),
  tenThousandReasonsAfrican('10000-reasons-african'),
  soulOfJesusSanctifyMe('soul-of-jesus-sanctify-me'),
  oceans('oceans');

  const ChantId(this.value);
  final String value;
}

class ChantTrack {
  final ChantId id;
  final String label;
  final String? voiceKey;
  final String? instrumentalKey;
  final List<String> cues;
  final int pauseDurationMs;

  const ChantTrack({
    required this.id,
    required this.label,
    this.voiceKey,
    this.instrumentalKey,
    required this.cues,
    required this.pauseDurationMs,
  });
}

class ChantTracks {
  static const Map<ChantId, ChantTrack> tracks = {
    ChantId.tenThousandReasons: ChantTrack(
      id: ChantId.tenThousandReasons,
      label: '10,000 Reasons',
      voiceKey: 'https://elbiblio.com/sounds/chants/10000_reasons.mp3',
      instrumentalKey: 'https://elbiblio.com/sounds/chants/10000_reasons_instrumental.mp3',
      cues: ['Pause and thank God for today', 'Let praise rise with each breath'],
      pauseDurationMs: 12000,
    ),
    ChantId.tenThousandReasonsAfrican: ChantTrack(
      id: ChantId.tenThousandReasonsAfrican,
      label: '10,000 Reasons (African)',
      voiceKey: 'https://elbiblio.com/sounds/chants/10000_reasons_african.mp3',
      instrumentalKey: 'https://elbiblio.com/sounds/chants/10000_reasons_instrumental.mp3',
      cues: ['Pause and thank God for today', 'Let praise echo with each breath'],
      pauseDurationMs: 12000,
    ),
    ChantId.soulOfJesusSanctifyMe: ChantTrack(
      id: ChantId.soulOfJesusSanctifyMe,
      label: 'Soul of Jesus, Sanctify Me',
      voiceKey: 'https://elbiblio.com/sounds/chants/anima_christi.mp3',
      instrumentalKey: 'https://elbiblio.com/sounds/chants/anima_christi_instrumental.mp3',
      cues: ['Invite Jesus to sanctify you today', 'Be reassured in His saving mercy'],
      pauseDurationMs: 14000,
    ),
    ChantId.oceans: ChantTrack(
      id: ChantId.oceans,
      label: 'Oceans (Spirit Lead Me)',
      voiceKey: 'https://elbiblio.com/sounds/chants/oceans_voice.mp3',
      instrumentalKey: 'https://elbiblio.com/sounds/chants/oceans_instrumental.mp3',
      cues: ['Notice where God invites you to trust deeper', 'Trust in every breath'],
      pauseDurationMs: 13000,
    ),
  };

  static List<ChantTrack> get allTracks => tracks.values.toList();

  static ChantTrack? getById(String? id) {
    if (id == null) return null;
    try {
      final chantId = ChantId.values.firstWhere((e) => e.value == id);
      return tracks[chantId];
    } catch (e) {
      return null;
    }
  }
}
