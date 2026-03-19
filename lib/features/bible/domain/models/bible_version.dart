import 'package:json_annotation/json_annotation.dart';

part 'bible_version.g.dart';

@JsonSerializable()
class BibleVersion {
  const BibleVersion({
    this.id,
    this.name,
    required this.abbreviation,
    this.language,
    this.description,
    this.copyright,
    this.tableName,
    this.dbFilename = '',
    this.downloadUrl = '',
    this.preinstalled = false,
    this.isDownloaded = false,
  });

  final String? id;
  @JsonKey(name: 'english_name')
  final String? name;
  @JsonKey(name: 'short_name')
  final String abbreviation;
  final String? language;
  final String? description;
  final String? copyright;
  @JsonKey(name: 'table_name')
  final String? tableName;
  @JsonKey(name: 'db_filename')
  final String dbFilename;
  @JsonKey(name: 'download_url')
  final String downloadUrl;
  @JsonKey(name: 'preinstalled')
  final bool preinstalled;
  
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
    String? dbFilename,
    String? downloadUrl,
    bool? preinstalled,
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
      dbFilename: dbFilename ?? this.dbFilename,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      preinstalled: preinstalled ?? this.preinstalled,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
