import 'package:flutter/material.dart';

class JesusJourneyEvent {
  final int order;
  final String id;
  final String title;
  final String subtitle;
  final String narrative;
  final String bibleReference;
  final String keyVerse;
  final String keyVerseReference;
  final String spiritualTakeaway;
  final List<JourneyQuestion> questions;
  final Color themeColor;
  final String iconName;
  final int xpReward;

  const JesusJourneyEvent({
    required this.order,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.narrative,
    required this.bibleReference,
    required this.keyVerse,
    required this.keyVerseReference,
    required this.spiritualTakeaway,
    required this.questions,
    required this.themeColor,
    required this.iconName,
    this.xpReward = 15,
  });

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'narrative': narrative,
      'bibleReference': bibleReference,
      'keyVerse': keyVerse,
      'keyVerseReference': keyVerseReference,
      'spiritualTakeaway': spiritualTakeaway,
      'questions': questions.map((q) => q.toJson()).toList(),
      'themeColor': themeColor.toARGB32(),
      'iconName': iconName,
      'xpReward': xpReward,
    };
  }

  factory JesusJourneyEvent.fromJson(Map<String, dynamic> json) {
    return JesusJourneyEvent(
      order: json['order'] as int,
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      narrative: json['narrative'] as String,
      bibleReference: json['bibleReference'] as String,
      keyVerse: json['keyVerse'] as String,
      keyVerseReference: json['keyVerseReference'] as String,
      spiritualTakeaway: json['spiritualTakeaway'] as String,
      questions: (json['questions'] as List)
          .map((q) => JourneyQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      themeColor: Color(json['themeColor'] as int),
      iconName: json['iconName'] as String,
      xpReward: json['xpReward'] as int? ?? 15,
    );
  }
}

class JourneyQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int difficulty;

  const JourneyQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.difficulty = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }

  factory JourneyQuestion.fromJson(Map<String, dynamic> json) {
    return JourneyQuestion(
      question: json['question'] as String,
      options: (json['options'] as List).cast<String>(),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
    );
  }
}
