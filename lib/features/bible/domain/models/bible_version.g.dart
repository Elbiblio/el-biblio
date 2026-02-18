// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BibleVersion _$BibleVersionFromJson(Map<String, dynamic> json) => BibleVersion(
      id: json['id'] as String,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String,
      language: json['language'] as String,
      description: json['description'] as String?,
      copyright: json['copyright'] as String?,
      tableName: json['table_name'] as String?,
    );

Map<String, dynamic> _$BibleVersionToJson(BibleVersion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'abbreviation': instance.abbreviation,
      'language': instance.language,
      'description': instance.description,
      'copyright': instance.copyright,
      'table_name': instance.tableName,
    };
