import 'package:flutter/material.dart';

enum TimePillar {
  health(
    id: 'health',
    label: 'Health & Rest',
    description: 'Sleep, exercise, food',
    color: Color(0xFFA4AC86), // earth-olive
    defaultMinutes: 450, // 7h 30m
  ),
  learning(
    id: 'learning',
    label: 'Learning',
    description: 'Reading, study, growth',
    color: Color(0xFFC89F81), // earth-clay
    defaultMinutes: 120, // 2h 00m
  ),
  vocation(
    id: 'vocation',
    label: 'Vocation',
    description: 'Work, career, mission',
    color: Color(0xFF8D7B68), // earth-brown
    defaultMinutes: 480, // 8h 00m
  ),
  family(
    id: 'family',
    label: 'Family',
    description: 'Spouse, children, home',
    color: Color(0xFFE6DCCA), // earth-sand
    defaultMinutes: 180, // 3h 00m
  ),
  social(
    id: 'social',
    label: 'Social',
    description: 'Friends, community',
    color: Color(0xFFB8A992),
    defaultMinutes: 90, // 1h 30m
  ),
  spirit(
    id: 'spirit',
    label: 'Spirit',
    description: 'Prayer, meditation',
    color: Color(0xFF7A8471), // sage-green
    defaultMinutes: 60, // 1h 00m
  ),
  others(
    id: 'others',
    label: 'Others',
    description: 'Commute, chores',
    color: Color(0xFFD4C5B0),
    defaultMinutes: 60, // 1h 00m
  );

  const TimePillar({
    required this.id,
    required this.label,
    required this.description,
    required this.color,
    required this.defaultMinutes,
  });

  final String id;
  final String label;
  final String description;
  final Color color;
  final int defaultMinutes;
}

enum SpiritualGrowthLevel {
  none(label: 'None', minutes: 0),
  min15(label: '15 min', minutes: 15),
  min30(label: '30 min', minutes: 30),
  hr1(label: '1 hr', minutes: 60),
  hr2(label: '2 hrs', minutes: 120),
  hr3(label: '3 hrs', minutes: 180),
  hr4(label: '4 hrs', minutes: 240);

  const SpiritualGrowthLevel({
    required this.label,
    required this.minutes,
  });

  final String label;
  final int minutes;
}
