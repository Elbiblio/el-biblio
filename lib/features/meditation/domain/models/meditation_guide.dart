/// A structured meditation guide generated for a session.
class MeditationGuide {
  const MeditationGuide({
    required this.title,
    required this.imagery,
    required this.scripture,
    required this.prompts,
    required this.declaration,
    required this.leadIn,
    required this.focus,
    this.breathInvitation,
    this.closingReminder,
    this.openReflection,
    this.stageNote,
    this.guidanceTips,
  });

  final String title;
  final String imagery;
  final String scripture;
  final List<String> prompts;
  final String declaration;
  final String leadIn;
  final String focus;
  final String? breathInvitation;
  final String? closingReminder;
  final String? openReflection;
  final String? stageNote;
  final List<String>? guidanceTips;

  static const empty = MeditationGuide(
    title: 'Meditation',
    imagery: '',
    scripture: '',
    prompts: [''],
    declaration: '',
    leadIn: '',
    focus: '',
  );
}
