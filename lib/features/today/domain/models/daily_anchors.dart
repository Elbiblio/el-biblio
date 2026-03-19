import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

enum VirtueType { humility, love, faith, knowledge }

enum HabitType { prayer, reflection, scripture, service, movement }

enum AnchorType { coreVirtue, habit, energyAction }

enum SpiritualPulseType { peace, joy, gratitude, hope, love, wisdom }

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
    this.commitmentStartTime,
    this.commitmentLockedTime,
    this.commitmentCompletedTime,
    this.isLockedIn = false,
    this.commitmentId,
    this.commitmentTitle,
    this.commitmentDescription,
    this.isPaused = false,
    this.pauseStartTime,
    this.totalPausedDuration = Duration.zero,
  });

  final String title;
  final String description;
  final int durationMinutes;
  final HabitType type;
  final bool isCompleted;
  final DateTime? commitmentStartTime;
  final DateTime? commitmentLockedTime;
  final DateTime? commitmentCompletedTime;
  final bool isLockedIn;
  final int? commitmentId;
  final String? commitmentTitle;
  final String? commitmentDescription;
  final bool isPaused;
  final DateTime? pauseStartTime;
  final Duration totalPausedDuration;

  Habit copyWith({
    String? title,
    String? description,
    int? durationMinutes,
    HabitType? type,
    bool? isCompleted,
    DateTime? commitmentStartTime,
    DateTime? commitmentLockedTime,
    DateTime? commitmentCompletedTime,
    bool? isLockedIn,
    int? commitmentId,
    String? commitmentTitle,
    String? commitmentDescription,
    bool? isPaused,
    DateTime? pauseStartTime,
    Duration? totalPausedDuration,
  }) {
    return Habit(
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      commitmentStartTime: commitmentStartTime ?? this.commitmentStartTime,
      commitmentLockedTime: commitmentLockedTime ?? this.commitmentLockedTime,
      commitmentCompletedTime: commitmentCompletedTime ?? this.commitmentCompletedTime,
      isLockedIn: isLockedIn ?? this.isLockedIn,
      commitmentId: commitmentId ?? this.commitmentId,
      commitmentTitle: commitmentTitle ?? this.commitmentTitle,
      commitmentDescription: commitmentDescription ?? this.commitmentDescription,
      isPaused: isPaused ?? this.isPaused,
      pauseStartTime: pauseStartTime ?? this.pauseStartTime,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
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
      commitmentStartTime: json['commitmentStartTime'] != null 
          ? DateTime.parse(json['commitmentStartTime'] as String) 
          : null,
      commitmentLockedTime: json['commitmentLockedTime'] != null 
          ? DateTime.parse(json['commitmentLockedTime'] as String) 
          : null,
      commitmentCompletedTime: json['commitmentCompletedTime'] != null 
          ? DateTime.parse(json['commitmentCompletedTime'] as String) 
          : null,
      isLockedIn: json['isLockedIn'] as bool? ?? false,
      commitmentId: json['commitmentId'] as int?,
      commitmentTitle: json['commitmentTitle'] as String?,
      commitmentDescription: json['commitmentDescription'] as String?,
      isPaused: json['isPaused'] as bool? ?? false,
      pauseStartTime: json['pauseStartTime'] != null
          ? DateTime.parse(json['pauseStartTime'] as String)
          : null,
      totalPausedDuration: json['totalPausedDuration'] != null
          ? Duration(milliseconds: json['totalPausedDuration'] as int)
          : Duration.zero,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'type': type.name,
      'isCompleted': isCompleted,
      'commitmentStartTime': commitmentStartTime?.toIso8601String(),
      'commitmentLockedTime': commitmentLockedTime?.toIso8601String(),
      'commitmentCompletedTime': commitmentCompletedTime?.toIso8601String(),
      'isLockedIn': isLockedIn,
      'commitmentId': commitmentId,
      'commitmentTitle': commitmentTitle,
      'commitmentDescription': commitmentDescription,
      'isPaused': isPaused,
      'pauseStartTime': pauseStartTime?.toIso8601String(),
      'totalPausedDuration': totalPausedDuration.inMilliseconds,
    };
  }

  // Helper methods for time-based logic
  bool get canStartCommitment {
    final now = DateTime.now();
    return now.hour >= 10 && !isLockedIn && commitmentStartTime == null;
  }

  bool get isCommitmentActive {
    if (commitmentStartTime == null) return false;
    if (isLockedIn && commitmentLockedTime == null) return false; // Locked but not actually started
    final now = DateTime.now();
    return now.isAfter(commitmentStartTime!) && !isCompleted;
  }

  Duration get commitmentProgress {
    if (commitmentStartTime == null) return Duration.zero;
    if (isLockedIn && commitmentLockedTime == null) return Duration.zero; // Locked but not actually started
    final now = DateTime.now();
    final elapsed = now.difference(commitmentStartTime!);
    final requiredDuration = Duration(minutes: durationMinutes);
    return elapsed > requiredDuration ? requiredDuration : elapsed;
  }

  double get commitmentProgressPercent {
    if (commitmentStartTime == null) return 0.0;
    if (isLockedIn && commitmentLockedTime == null) return 0.0; // Locked but not actually started
    final progress = commitmentProgress;
    return progress.inMinutes / durationMinutes;
  }

  bool get isCommitmentComplete {
    if (commitmentStartTime == null) return false;
    if (isLockedIn && commitmentLockedTime == null) return false; // Locked but not actually started
    return DateTime.now().difference(commitmentStartTime!) >= Duration(minutes: durationMinutes);
  }

  String get displayTitle => commitmentTitle != null ? commitmentTitle! : 'Practice a Habit';
  String get displayDescription => commitmentDescription != null ? commitmentDescription! : 'Begin and lock in a habit during the day for a minimum of ${_formatDuration(durationMinutes)}.';
  
  String get timeRemaining {
    if (commitmentStartTime == null) return '';
    if (isLockedIn && commitmentLockedTime == null) return ''; // Locked but not actually started
    final now = DateTime.now();
    final targetTime = commitmentStartTime!.add(Duration(minutes: durationMinutes));
    final remaining = targetTime.difference(now);
    
    if (remaining.isNegative) return 'Complete!';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}H ${minutes}M left';
    } else {
      return '${minutes}M left';
    }
  }

  // Helper method to format duration for display
  static String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      if (remainingMinutes > 0) {
        return '$hours hour${hours > 1 ? 's' : ''} $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''}';
      }
    } else {
      return '$remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
    }
  }

  // Pause/resume functionality
  bool get canPause {
    return isCommitmentActive && !isPaused && !isCompleted;
  }

  bool get canResume {
    return isCommitmentActive && isPaused && !isCompleted;
  }

  Duration get adjustedCommitmentProgress {
    if (commitmentStartTime == null) return Duration.zero;
    if (isLockedIn && commitmentLockedTime == null) return Duration.zero; // Locked but not actually started
    
    final now = DateTime.now();
    var elapsed = now.difference(commitmentStartTime!);
    
    // Subtract paused time
    if (isPaused && pauseStartTime != null) {
      elapsed = elapsed - now.difference(pauseStartTime!);
    }
    
    // Subtract total paused duration from previous pauses
    elapsed = elapsed - totalPausedDuration;
    
    final requiredDuration = Duration(minutes: durationMinutes);
    return elapsed > requiredDuration ? requiredDuration : elapsed;
  }

  double get adjustedCommitmentProgressPercent {
    if (commitmentStartTime == null) return 0.0;
    if (isLockedIn && commitmentLockedTime == null) return 0.0; // Locked but not actually started
    final progress = adjustedCommitmentProgress;
    return progress.inMinutes / durationMinutes;
  }

  String get adjustedTimeRemaining {
    if (commitmentStartTime == null) return '';
    if (isLockedIn && commitmentLockedTime == null) return ''; // Locked but not actually started
    
    final now = DateTime.now();
    var targetTime = commitmentStartTime!.add(Duration(minutes: durationMinutes));
    
    // Add paused time to target
    if (isPaused && pauseStartTime != null) {
      final currentPauseDuration = now.difference(pauseStartTime!);
      targetTime = targetTime.add(currentPauseDuration);
    }
    targetTime = targetTime.add(totalPausedDuration);
    
    final remaining = targetTime.difference(now);
    
    if (remaining.isNegative) return 'Complete!';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}H ${minutes}M left';
    } else {
      return '${minutes}M left';
    }
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
class SpiritualPulseEntry {
  const SpiritualPulseEntry({
    required this.type,
    required this.timestamp,
    required this.note,
    this.intensity = 1.0,
  });

  final SpiritualPulseType type;
  final DateTime timestamp;
  final String note;
  final double intensity; // 0.0 to 1.0

  SpiritualPulseEntry copyWith({
    SpiritualPulseType? type,
    DateTime? timestamp,
    String? note,
    double? intensity,
  }) {
    return SpiritualPulseEntry(
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      intensity: intensity ?? this.intensity,
    );
  }

  factory SpiritualPulseEntry.fromJson(Map<String, dynamic> json) {
    return SpiritualPulseEntry(
      type: SpiritualPulseType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SpiritualPulseType.peace,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'intensity': intensity,
    };
  }
}

@JsonSerializable()
class SpiritualPulseResponse {
  const SpiritualPulseResponse({
    required this.entries,
    required this.lastUpdated,
    this.goingWell = '',
    this.struggling = '',
    this.needHelp = '',
    this.followUpQuestion = '',
    this.followUpAnswer = '',
    this.virtueFocus = '',
  });

  final List<SpiritualPulseEntry> entries;
  final DateTime lastUpdated;
  final String goingWell;
  final String struggling;
  final String needHelp;
  final String followUpQuestion;
  final String followUpAnswer;
  final String virtueFocus;

  SpiritualPulseResponse copyWith({
    List<SpiritualPulseEntry>? entries,
    DateTime? lastUpdated,
    String? goingWell,
    String? struggling,
    String? needHelp,
    String? followUpQuestion,
    String? followUpAnswer,
    String? virtueFocus,
  }) {
    return SpiritualPulseResponse(
      entries: entries ?? this.entries,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      goingWell: goingWell ?? this.goingWell,
      struggling: struggling ?? this.struggling,
      needHelp: needHelp ?? this.needHelp,
      followUpQuestion: followUpQuestion ?? this.followUpQuestion,
      followUpAnswer: followUpAnswer ?? this.followUpAnswer,
      virtueFocus: virtueFocus ?? this.virtueFocus,
    );
  }

  factory SpiritualPulseResponse.fromJson(Map<String, dynamic> json) {
    return SpiritualPulseResponse(
      entries: (json['entries'] as List<dynamic>?)
          ?.map((e) => SpiritualPulseEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      goingWell: json['goingWell'] as String? ?? '',
      struggling: json['struggling'] as String? ?? '',
      needHelp: json['needHelp'] as String? ?? '',
      followUpQuestion: json['followUpQuestion'] as String? ?? '',
      followUpAnswer: json['followUpAnswer'] as String? ?? '',
      virtueFocus: json['virtueFocus'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'entries': entries.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'goingWell': goingWell,
      'struggling': struggling,
      'needHelp': needHelp,
      'followUpQuestion': followUpQuestion,
      'followUpAnswer': followUpAnswer,
      'virtueFocus': virtueFocus,
    };
  }

  factory SpiritualPulseResponse.empty() {
    return SpiritualPulseResponse(
      entries: [],
      lastUpdated: DateTime.now(),
    );
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

    final habit = Habit(
      title: 'Practice a Habit',
      description: 'Begin and lock in a habit during the day for a minimum of ${Habit._formatDuration(240)}.',
      durationMinutes: 240,
      type: HabitType.reflection,
      isCompleted: false,
    );

    const action = EnergyAction(
      title: 'Physical Activity',
      description: 'Carry out a physical activity anytime during the day or evening.',
      durationMinutes: 30,
      isCompleted: false,
    );

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
    final commitmentTitle = reader.readString();
    final commitmentDescription = reader.readString();
    return Habit(
      title: reader.readString(),
      description: reader.readString(),
      durationMinutes: reader.readInt(),
      type: reader.read() as HabitType,
      isCompleted: reader.readBool(),
      commitmentStartTime: reader.read() as DateTime?,
      commitmentLockedTime: reader.read() as DateTime?,
      commitmentCompletedTime: reader.read() as DateTime?,
      isLockedIn: reader.readBool(),
      commitmentId: reader.read() as int?,
      commitmentTitle: commitmentTitle.isEmpty ? null : commitmentTitle,
      commitmentDescription: commitmentDescription.isEmpty ? null : commitmentDescription,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeString(obj.commitmentTitle ?? '')
      ..writeString(obj.commitmentDescription ?? '')
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeInt(obj.durationMinutes)
      ..write(obj.type)
      ..writeBool(obj.isCompleted)
      ..write(obj.commitmentStartTime)
      ..write(obj.commitmentLockedTime)
      ..write(obj.commitmentCompletedTime)
      ..writeBool(obj.isLockedIn)
      ..write(obj.commitmentId);
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
