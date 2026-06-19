/// Template engine for rich push notification messages.
///
/// Templates use `{variable}` placeholders that are replaced with
/// user-specific values at render time.
class PushTemplateEngine {
  const PushTemplateEngine._();

  static const Map<String, String> _templates = {
    'commitment_check_in':
        '{name}, time for {commitment}. Day {day} of {total}.',
    'milestone_reached':
        '{name}, you\'ve completed {percent} of {commitment}! Keep going!',
    'partner_activity':
        '{partner} just checked in. Your turn?',
    'circle_streak':
        'Your circle is on a {days}-day streak. Don\'t break it!',
    'struggle_support':
        'You\'ve missed {days} days. Need to adjust or talk?',
    'companion_nudge':
        '{companion} says: {message}',
    'failure_admission_response':
        '{companion} responded to your admission.',
    'milestone_25':
        '{name}, you\'re a quarter of the way through {commitment}!',
    'milestone_50':
        '{name}, halfway through {commitment} — amazing progress!',
    'milestone_75':
        '{name}, three-quarters done with {commitment}! The finish line is in sight!',
    'milestone_100':
        '{name}, you completed {commitment}! Celebrate this victory!',
  };

  /// Render a template with the given variables.
  ///
  /// Variables should be provided as key-value pairs matching the
  /// `{variable}` placeholders in the template string.
  static String render(String templateKey, Map<String, String> vars) {
    final template = _templates[templateKey];
    if (template == null) return '';

    var result = template;
    for (final entry in vars.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  /// Get a specific template string.
  static String? getTemplate(String templateKey) => _templates[templateKey];

  /// Get all available template keys.
  static List<String> get availableTemplates => _templates.keys.toList();
}
