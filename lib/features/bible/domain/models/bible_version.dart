import 'package:json_annotation/json_annotation.dart';

part 'bible_version.g.dart';

@JsonSerializable()
class BibleVersion {
  const BibleVersion({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.language,
    this.description,
    this.copyright,
    this.tableName,
    this.isDownloaded = false,
  });

  final String id;
  final String name;
  final String abbreviation;
  final String language;
  final String? description;
  final String? copyright;
  @JsonKey(name: 'table_name')
  final String? tableName;
  
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isDownloaded;

  factory BibleVersion.fromJson(Map<String, dynamic> json) => _$BibleVersionFromJson(json);
  Map<String, dynamic> toJson() => _$BibleVersionToJson(this);

  BibleVersion copyWith({
    String? id,
    String? name,
    String? abbreviation,
    String? language,
    String? description,
    String? copyright,
    String? tableName,
    bool? isDownloaded,
  }) {
    return BibleVersion(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      language: language ?? this.language,
      description: description ?? this.description,
      copyright: copyright ?? this.copyright,
      tableName: tableName ?? this.tableName,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
