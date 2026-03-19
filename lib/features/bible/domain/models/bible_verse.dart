import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../today/domain/models/daily_anchors.dart';

@JsonSerializable()
class BibleVerse {
  const BibleVerse({
    required this.reference,
    required this.text,
    required this.virtueType,
    required this.date,
  });

  final String reference;
  final String text;
  final VirtueType virtueType;
  final DateTime date;

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      reference: json['reference'] as String,
      text: json['text'] as String,
      virtueType: VirtueType.values.firstWhere(
        (value) => value.name == json['virtueType'],
        orElse: () => VirtueType.humility,
      ),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reference': reference,
      'text': text,
      'virtueType': virtueType.name,
      'date': date.toIso8601String(),
    };
  }
}

class BibleVerseAdapter extends TypeAdapter<BibleVerse> {
  @override
  final int typeId = 30;

  @override
  BibleVerse read(BinaryReader reader) {
    return BibleVerse(
      reference: reader.readString(),
      text: reader.readString(),
      virtueType: reader.read() as VirtueType,
      date: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, BibleVerse obj) {
    writer
      ..writeString(obj.reference)
      ..writeString(obj.text)
      ..write(obj.virtueType)
      ..writeString(obj.date.toIso8601String());
  }
}
