// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BibleVersion _$BibleVersionFromJson(Map<String, dynamic> json) => BibleVersion(
      id: json['id'] as String?,
      name: json['english_name'] as String?,
      abbreviation: json['short_name'] as String,
      language: json['language'] as String?,
      description: json['description'] as String?,
      copyright: json['copyright'] as String?,
      tableName: json['table_name'] as String?,
      dbFilename: json['db_filename'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
      preinstalled: json['preinstalled'] as bool? ?? false,
    );

Map<String, dynamic> _$BibleVersionToJson(BibleVersion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'english_name': instance.name,
      'short_name': instance.abbreviation,
      'language': instance.language,
      'description': instance.description,
      'copyright': instance.copyright,
      'table_name': instance.tableName,
      'db_filename': instance.dbFilename,
      'download_url': instance.downloadUrl,
      'preinstalled': instance.preinstalled,
    };
