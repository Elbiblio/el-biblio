import 'package:json_annotation/json_annotation.dart';

part 'bible_insight.g.dart';

@JsonSerializable()
class BibleInsight {
  const BibleInsight({
    required this.sections,
    this.reference,
  });

  final List<InsightSection> sections;
  final String? reference;

  factory BibleInsight.fromJson(Map<String, dynamic> json) => _$BibleInsightFromJson(json);
  Map<String, dynamic> toJson() => _$BibleInsightToJson(this);
}

@JsonSerializable()
class InsightSection {
  const InsightSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  factory InsightSection.fromJson(Map<String, dynamic> json) => _$InsightSectionFromJson(json);
  Map<String, dynamic> toJson() => _$InsightSectionToJson(this);
}
