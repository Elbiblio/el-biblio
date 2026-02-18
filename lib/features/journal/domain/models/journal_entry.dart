import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.prompts,
    required this.virtueRating,
    required this.habitRating,
    required this.actionRating,
  });

  final String id;
  final DateTime date;
  final String content;
  final List<String> prompts;
  final int virtueRating;
  final int habitRating;
  final int actionRating;

  int get integrityPoints => virtueRating + habitRating + actionRating;

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      prompts: (json['prompts'] as List<dynamic>).cast<String>(),
      virtueRating: json['virtueRating'] as int,
      habitRating: json['habitRating'] as int,
      actionRating: json['actionRating'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'prompts': prompts,
      'virtueRating': virtueRating,
      'habitRating': habitRating,
      'actionRating': actionRating,
    };
  }
}

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 20;

  @override
  JournalEntry read(BinaryReader reader) {
    return JournalEntry(
      id: reader.readString(),
      date: DateTime.parse(reader.readString()),
      content: reader.readString(),
      prompts: (reader.readList().cast<String>()),
      virtueRating: reader.readInt(),
      habitRating: reader.readInt(),
      actionRating: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.date.toIso8601String())
      ..writeString(obj.content)
      ..writeList(obj.prompts)
      ..writeInt(obj.virtueRating)
      ..writeInt(obj.habitRating)
      ..writeInt(obj.actionRating);
  }
}
