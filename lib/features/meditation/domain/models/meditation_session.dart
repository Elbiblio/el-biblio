import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../today/domain/models/daily_anchors.dart';
import '../models/meditation_enums.dart';
import '../models/meditation_templates.dart';

@JsonSerializable()
class MeditationSession {
  const MeditationSession({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.guided,
    required this.audioUrl,
    required this.virtueType,
    required this.completedCount,
    // Configuration data for restoring sessions
    this.style,
    this.backgroundSound,
    this.breathPace,
    this.centeringWord,
    this.virtueName,
    this.chosenChantId,
    this.bibleTemplate,
    this.affirmationCategory,
    this.virtueAffirmation,
    this.habitAffirmation,
    this.customBibleVerses,
    this.godSpokeToMe,
    this.journalEntryId,
  });

  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final bool guided;
  final String audioUrl;
  final VirtueType virtueType;
  final int completedCount;
  
  // Configuration data for restoring sessions
  final MeditationStyle? style;
  final BackgroundSound? backgroundSound;
  final BreathPace? breathPace;
  final String? centeringWord;
  final String? virtueName;
  final String? chosenChantId;
  final BibleTemplate? bibleTemplate;
  final AffirmationCategory? affirmationCategory;
  final VirtueAffirmation? virtueAffirmation;
  final HabitAffirmation? habitAffirmation;
  final String? customBibleVerses;

  /// Whether the user sensed God speaking during this session.
  final bool? godSpokeToMe;

  /// ID of the journal entry created after this meditation session.
  final String? journalEntryId;

  MeditationSession copyWith({
    int? completedCount,
    MeditationStyle? style,
    BackgroundSound? backgroundSound,
    BreathPace? breathPace,
    String? centeringWord,
    String? virtueName,
    String? chosenChantId,
    BibleTemplate? bibleTemplate,
    AffirmationCategory? affirmationCategory,
    VirtueAffirmation? virtueAffirmation,
    HabitAffirmation? habitAffirmation,
    String? customBibleVerses,
    bool? godSpokeToMe,
    String? journalEntryId,
  }) {
    return MeditationSession(
      id: id,
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      guided: guided,
      audioUrl: audioUrl,
      virtueType: virtueType,
      completedCount: completedCount ?? this.completedCount,
      style: style ?? this.style,
      backgroundSound: backgroundSound ?? this.backgroundSound,
      breathPace: breathPace ?? this.breathPace,
      centeringWord: centeringWord ?? this.centeringWord,
      virtueName: virtueName ?? this.virtueName,
      chosenChantId: chosenChantId ?? this.chosenChantId,
      bibleTemplate: bibleTemplate ?? this.bibleTemplate,
      affirmationCategory: affirmationCategory ?? this.affirmationCategory,
      virtueAffirmation: virtueAffirmation ?? this.virtueAffirmation,
      habitAffirmation: habitAffirmation ?? this.habitAffirmation,
      customBibleVerses: customBibleVerses ?? this.customBibleVerses,
      godSpokeToMe: godSpokeToMe ?? this.godSpokeToMe,
      journalEntryId: journalEntryId ?? this.journalEntryId,
    );
  }

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: json['durationMinutes'] as int,
      guided: json['guided'] as bool,
      audioUrl: json['audioUrl'] as String,
      virtueType: VirtueType.values.firstWhere(
        (value) => value.name == json['virtueType'],
        orElse: () => VirtueType.faith,
      ),
      completedCount: json['completedCount'] as int? ?? 0,
      // Configuration fields with null defaults for backward compatibility
      style: json['style'] != null 
          ? MeditationStyle.values.firstWhere(
              (value) => value.name == json['style'],
              orElse: () => MeditationStyle.quietReflection,
            )
          : null,
      backgroundSound: json['backgroundSound'] != null
          ? BackgroundSound.values.firstWhere(
              (value) => value.name == json['backgroundSound'],
              orElse: () => BackgroundSound.ambient,
            )
          : null,
      breathPace: json['breathPace'] != null
          ? BreathPace.values.firstWhere(
              (value) => value.name == json['breathPace'],
              orElse: () => BreathPace.medium,
            )
          : null,
      centeringWord: json['centeringWord'] as String?,
      virtueName: json['virtueName'] as String?,
      chosenChantId: json['chosenChantId'] as String?,
      bibleTemplate: json['bibleTemplate'] != null
          ? BibleTemplate.values.firstWhere(
              (value) => value.name == json['bibleTemplate'],
              orElse: () => BibleTemplate.parables,
            )
          : null,
      affirmationCategory: json['affirmationCategory'] != null
          ? AffirmationCategory.values.firstWhere(
              (value) => value.name == json['affirmationCategory'],
              orElse: () => AffirmationCategory.growVirtue,
            )
          : null,
      virtueAffirmation: json['virtueAffirmation'] != null
          ? VirtueAffirmation.values.firstWhere(
              (value) => value.name == json['virtueAffirmation'],
              orElse: () => VirtueAffirmation.selfControl,
            )
          : null,
      habitAffirmation: json['habitAffirmation'] != null
          ? HabitAffirmation.values.firstWhere(
              (value) => value.name == json['habitAffirmation'],
              orElse: () => HabitAffirmation.lust,
            )
          : null,
      customBibleVerses: json['customBibleVerses'] as String?,
      godSpokeToMe: json['godSpokeToMe'] as bool?,
      journalEntryId: json['journalEntryId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'guided': guided,
      'audioUrl': audioUrl,
      'virtueType': virtueType.name,
      'completedCount': completedCount,
      // Configuration fields
      'style': style?.name,
      'backgroundSound': backgroundSound?.name,
      'breathPace': breathPace?.name,
      'centeringWord': centeringWord,
      'virtueName': virtueName,
      'chosenChantId': chosenChantId,
      'bibleTemplate': bibleTemplate?.name,
      'affirmationCategory': affirmationCategory?.name,
      'virtueAffirmation': virtueAffirmation?.name,
      'habitAffirmation': habitAffirmation?.name,
      'customBibleVerses': customBibleVerses,
      'godSpokeToMe': godSpokeToMe,
      'journalEntryId': journalEntryId,
    };
  }
}

class MeditationSessionAdapter extends TypeAdapter<MeditationSession> {
  @override
  final int typeId = 40;

  @override
  MeditationSession read(BinaryReader reader) {
    return MeditationSession(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      durationMinutes: reader.readInt(),
      guided: reader.readBool(),
      audioUrl: reader.readString(),
      virtueType: reader.read() as VirtueType,
      completedCount: reader.readInt(),
      // Configuration fields
      style: reader.read() as MeditationStyle?,
      backgroundSound: reader.read() as BackgroundSound?,
      breathPace: reader.read() as BreathPace?,
      centeringWord: reader.readString(),
      virtueName: reader.readString(),
      chosenChantId: reader.readString(),
      bibleTemplate: reader.read() as BibleTemplate?,
      affirmationCategory: reader.read() as AffirmationCategory?,
      virtueAffirmation: reader.read() as VirtueAffirmation?,
      habitAffirmation: reader.read() as HabitAffirmation?,
      customBibleVerses: reader.readString(),
      godSpokeToMe: reader.read() as bool?,
      journalEntryId: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, MeditationSession obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeInt(obj.durationMinutes)
      ..writeBool(obj.guided)
      ..writeString(obj.audioUrl)
      ..write(obj.virtueType)
      ..writeInt(obj.completedCount)
      // Configuration fields
      ..write(obj.style)
      ..write(obj.backgroundSound)
      ..write(obj.breathPace)
      ..writeString(obj.centeringWord ?? '')
      ..writeString(obj.virtueName ?? '')
      ..writeString(obj.chosenChantId ?? '')
      ..write(obj.bibleTemplate)
      ..write(obj.affirmationCategory)
      ..write(obj.virtueAffirmation)
      ..write(obj.habitAffirmation)
      ..writeString(obj.customBibleVerses ?? '')
      ..write(obj.godSpokeToMe)
      ..writeString(obj.journalEntryId ?? '');
  }
}
