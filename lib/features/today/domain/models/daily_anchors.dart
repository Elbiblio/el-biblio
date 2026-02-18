import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

enum VirtueType { humility, love, faith, knowledge }

enum HabitType { prayer, reflection, scripture, service, movement }

enum AnchorType { coreVirtue, habit, energyAction }

extension VirtueTypeX on VirtueType {
  String get title => switch (this) {
        VirtueType.humility => 'Humility',
        VirtueType.love => 'Love',
        VirtueType.faith => 'Faith',
        VirtueType.knowledge => 'Knowledge',
      };

  String get description => switch (this) {
        VirtueType.humility =>
          'Alignment with truth, self-awareness, and surrender.',
        VirtueType.love =>
          'Compassion, service, and relational intentionality.',
        VirtueType.faith =>
          'Trust, obedience, courage, and spiritual anchoring.',
        VirtueType.knowledge =>
          'Wisdom, learning, discernment, and understanding.',
      };

  String get focusPrompt => switch (this) {
        VirtueType.humility => 'Act with openness and truth.',
        VirtueType.love => 'Serve with compassion today.',
        VirtueType.faith => 'Take one courageous step in trust.',
        VirtueType.knowledge => 'Seek wisdom before reaction.',
      };

  String get scriptureReference => switch (this) {
        VirtueType.humility => 'John 3:30',
        VirtueType.love => 'Mark 12:31',
        VirtueType.faith => 'Hebrews 11:1',
        VirtueType.knowledge => 'Proverbs 4:7',
      };

  static VirtueType? fromStorage(String? value) {
    for (final type in VirtueType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }
}

@JsonSerializable()
class Virtue {
  const Virtue({
    required this.type,
    required this.description,
    required this.focusPrompt,
    required this.integrityPoints,
    required this.scriptureReference,
    required this.isCompleted,
  });

  final VirtueType type;
  final String description;
  final String focusPrompt;
  final int integrityPoints;
  final String scriptureReference;
  final bool isCompleted;

  Virtue copyWith({
    VirtueType? type,
    String? description,
    String? focusPrompt,
    int? integrityPoints,
    String? scriptureReference,
    bool? isCompleted,
  }) {
    return Virtue(
      type: type ?? this.type,
      description: description ?? this.description,
      focusPrompt: focusPrompt ?? this.focusPrompt,
      integrityPoints: integrityPoints ?? this.integrityPoints,
      scriptureReference: scriptureReference ?? this.scriptureReference,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory Virtue.fromJson(Map<String, dynamic> json) {
    return Virtue(
      type: VirtueType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => VirtueType.humility,
      ),
      description: json['description'] as String,
      focusPrompt: json['focusPrompt'] as String,
      integrityPoints: json['integrityPoints'] as int,
      scriptureReference: json['scriptureReference'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'description': description,
      'focusPrompt': focusPrompt,
      'integrityPoints': integrityPoints,
      'scriptureReference': scriptureReference,
      'isCompleted': isCompleted,
    };
  }
}

@JsonSerializable()
class Habit {
  const Habit({
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.type,
    required this.isCompleted,
  });

  final String title;
  final String description;
  final int durationMinutes;
  final HabitType type;
  final bool isCompleted;

  Habit copyWith({
    String? title,
    String? description,
    int? durationMinutes,
    HabitType? type,
    bool? isCompleted,
  }) {
    return Habit(
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: json['durationMinutes'] as int,
      type: HabitType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => HabitType.prayer,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'type': type.name,
      'isCompleted': isCompleted,
    };
  }
}

@JsonSerializable()
class EnergyAction {
  const EnergyAction({
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.isCompleted,
  });

  final String title;
  final String description;
  final int durationMinutes;
  final bool isCompleted;

  EnergyAction copyWith({
    String? title,
    String? description,
    int? durationMinutes,
    bool? isCompleted,
  }) {
    return EnergyAction(
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory EnergyAction.fromJson(Map<String, dynamic> json) {
    return EnergyAction(
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: json['durationMinutes'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
    };
  }
}

@JsonSerializable()
class DailyAnchors {
  const DailyAnchors({
    required this.coreVirtue,
    required this.habit,
    required this.energyAction,
    required this.date,
    required this.isCompleted,
  });

  final Virtue coreVirtue;
  final Habit habit;
  final EnergyAction energyAction;
  final DateTime date;
  final bool isCompleted;

  int get integrityPoints =>
      coreVirtue.integrityPoints +
      (habit.isCompleted ? 4 : 0) +
      (energyAction.isCompleted ? 5 : 0);

  DailyAnchors copyWith({
    Virtue? coreVirtue,
    Habit? habit,
    EnergyAction? energyAction,
    DateTime? date,
    bool? isCompleted,
  }) {
    return DailyAnchors(
      coreVirtue: coreVirtue ?? this.coreVirtue,
      habit: habit ?? this.habit,
      energyAction: energyAction ?? this.energyAction,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory DailyAnchors.empty(DateTime date) {
    return DailyAnchorsFactory.forDate(date: date, virtueType: VirtueType.humility);
  }

  factory DailyAnchors.fromJson(Map<String, dynamic> json) {
    return DailyAnchors(
      coreVirtue: Virtue.fromJson(json['coreVirtue'] as Map<String, dynamic>),
      habit: Habit.fromJson(json['habit'] as Map<String, dynamic>),
      energyAction:
          EnergyAction.fromJson(json['energyAction'] as Map<String, dynamic>),
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'coreVirtue': coreVirtue.toJson(),
      'habit': habit.toJson(),
      'energyAction': energyAction.toJson(),
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}

class DailyAnchorsFactory {
  const DailyAnchorsFactory._();

  static DailyAnchors forDate({
    required DateTime date,
    required VirtueType virtueType,
  }) {
    final virtue = Virtue(
      type: virtueType,
      description: virtueType.description,
      focusPrompt: virtueType.focusPrompt,
      integrityPoints: 3,
      scriptureReference: virtueType.scriptureReference,
      isCompleted: false,
    );

    final habit = switch (virtueType) {
      VirtueType.humility => const Habit(
          title: 'Silent Prayer',
          description: 'Spend five focused minutes surrendering your plans.',
          durationMinutes: 5,
          type: HabitType.prayer,
          isCompleted: false,
        ),
      VirtueType.love => const Habit(
          title: 'Compassion Prayer',
          description: 'Pray blessings over someone you will serve today.',
          durationMinutes: 5,
          type: HabitType.service,
          isCompleted: false,
        ),
      VirtueType.faith => const Habit(
          title: 'Scripture Trust Practice',
          description: 'Meditate on one promise and declare it aloud.',
          durationMinutes: 6,
          type: HabitType.scripture,
          isCompleted: false,
        ),
      VirtueType.knowledge => const Habit(
          title: 'Wisdom Reflection',
          description: 'Read a short passage and write one actionable insight.',
          durationMinutes: 7,
          type: HabitType.reflection,
          isCompleted: false,
        ),
    };

    final action = switch (virtueType) {
      VirtueType.humility => const EnergyAction(
          title: 'Intentional Walk',
          description: 'Walk for 10 minutes while practicing gratitude.',
          durationMinutes: 10,
          isCompleted: false,
        ),
      VirtueType.love => const EnergyAction(
          title: 'Act of Service',
          description: 'Do one practical act of kindness for someone nearby.',
          durationMinutes: 10,
          isCompleted: false,
        ),
      VirtueType.faith => const EnergyAction(
          title: 'Courage Sprint',
          description: 'Take one action you have delayed out of fear.',
          durationMinutes: 8,
          isCompleted: false,
        ),
      VirtueType.knowledge => const EnergyAction(
          title: 'Learning Walk',
          description: 'Listen to a short wisdom teaching while moving.',
          durationMinutes: 10,
          isCompleted: false,
        ),
    };

    return DailyAnchors(
      coreVirtue: virtue,
      habit: habit,
      energyAction: action,
      date: DateTime(date.year, date.month, date.day),
      isCompleted: false,
    );
  }
}

class VirtueTypeAdapter extends TypeAdapter<VirtueType> {
  @override
  final int typeId = 0;

  @override
  VirtueType read(BinaryReader reader) {
    return VirtueType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, VirtueType obj) {
    writer.writeInt(obj.index);
  }
}

class HabitTypeAdapter extends TypeAdapter<HabitType> {
  @override
  final int typeId = 1;

  @override
  HabitType read(BinaryReader reader) {
    return HabitType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, HabitType obj) {
    writer.writeInt(obj.index);
  }
}

class AnchorTypeAdapter extends TypeAdapter<AnchorType> {
  @override
  final int typeId = 2;

  @override
  AnchorType read(BinaryReader reader) {
    return AnchorType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, AnchorType obj) {
    writer.writeInt(obj.index);
  }
}

class VirtueAdapter extends TypeAdapter<Virtue> {
  @override
  final int typeId = 3;

  @override
  Virtue read(BinaryReader reader) {
    return Virtue(
      type: reader.read() as VirtueType,
      description: reader.readString(),
      focusPrompt: reader.readString(),
      integrityPoints: reader.readInt(),
      scriptureReference: reader.readString(),
      isCompleted: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Virtue obj) {
    writer
      ..write(obj.type)
      ..writeString(obj.description)
      ..writeString(obj.focusPrompt)
      ..writeInt(obj.integrityPoints)
      ..writeString(obj.scriptureReference)
      ..writeBool(obj.isCompleted);
  }
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 4;

  @override
  Habit read(BinaryReader reader) {
    return Habit(
      title: reader.readString(),
      description: reader.readString(),
      durationMinutes: reader.readInt(),
      type: reader.read() as HabitType,
      isCompleted: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeInt(obj.durationMinutes)
      ..write(obj.type)
      ..writeBool(obj.isCompleted);
  }
}

class EnergyActionAdapter extends TypeAdapter<EnergyAction> {
  @override
  final int typeId = 5;

  @override
  EnergyAction read(BinaryReader reader) {
    return EnergyAction(
      title: reader.readString(),
      description: reader.readString(),
      durationMinutes: reader.readInt(),
      isCompleted: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, EnergyAction obj) {
    writer
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeInt(obj.durationMinutes)
      ..writeBool(obj.isCompleted);
  }
}

class DailyAnchorsAdapter extends TypeAdapter<DailyAnchors> {
  @override
  final int typeId = 6;

  @override
  DailyAnchors read(BinaryReader reader) {
    return DailyAnchors(
      coreVirtue: reader.read() as Virtue,
      habit: reader.read() as Habit,
      energyAction: reader.read() as EnergyAction,
      date: DateTime.parse(reader.readString()),
      isCompleted: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyAnchors obj) {
    writer
      ..write(obj.coreVirtue)
      ..write(obj.habit)
      ..write(obj.energyAction)
      ..writeString(obj.date.toIso8601String())
      ..writeBool(obj.isCompleted);
  }
}
