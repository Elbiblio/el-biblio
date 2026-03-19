import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssessmentActionTask {
  const AssessmentActionTask({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

class AssessmentTaskCatalog {
  const AssessmentTaskCatalog();

  static const Map<String, List<AssessmentActionTask>> _defaultTasksByPath = {
    'development': [
      AssessmentActionTask(
        id: 'dev_1',
        title: 'Read one book about your specific talent',
        description:
            'Choose a book that helps you understand how to use your gifts more effectively.',
      ),
      AssessmentActionTask(
        id: 'dev_2',
        title: 'Find a mentor in your area of calling',
        description:
            'Connect with someone mature who can help you navigate the challenges of your specific gifts.',
      ),
      AssessmentActionTask(
        id: 'dev_3',
        title: 'Start a journal tracking your growth',
        description:
            'Write down moments when you use your strengths and when you face your specific distortions.',
      ),
      AssessmentActionTask(
        id: 'dev_4',
        title: 'Take a course related to your archetype',
        description: 'Invest in training that sharpens your natural abilities.',
      ),
      AssessmentActionTask(
        id: 'dev_5',
        title: 'Find an accountability partner',
        description:
            'Share your growth areas with someone who can help you stay on track.',
      ),
    ],
    'engagement': [
      AssessmentActionTask(
        id: 'eng_1',
        title: 'Volunteer in your local church',
        description:
            'Find an opportunity to use your specific gifts in a structured environment.',
      ),
      AssessmentActionTask(
        id: 'eng_2',
        title: 'Start a small group or initiative',
        description:
            'Take the lead on something that aligns with your archetype\'s strengths.',
      ),
      AssessmentActionTask(
        id: 'eng_3',
        title: 'Offer your skills to a non-profit',
        description:
            'Find an organization that needs the specific value you bring.',
      ),
      AssessmentActionTask(
        id: 'eng_4',
        title: 'Mentor someone younger in faith',
        description: 'Pass on what you have learned to someone else.',
      ),
      AssessmentActionTask(
        id: 'eng_5',
        title: 'Take on a new responsibility at work',
        description:
            'Look for ways to apply your spiritual gifts in your secular workplace.',
      ),
    ],
    'recalibration': [
      AssessmentActionTask(
        id: 'rec_1',
        title: 'Set boundaries around your time',
        description:
            'Choose to say no to things that drain you or pull you away from your core calling.',
      ),
      AssessmentActionTask(
        id: 'rec_2',
        title: 'Take a sabbatical or retreat',
        description:
            'Set aside dedicated time to rest and hear from God about your next steps.',
      ),
      AssessmentActionTask(
        id: 'rec_3',
        title: 'Evaluate your current commitments',
        description:
            'Look at everything you are doing and see if it aligns with your archetype.',
      ),
      AssessmentActionTask(
        id: 'rec_4',
        title: 'Seek professional coaching or counseling',
        description:
            'Get help navigating burnout or misalignment in your current role.',
      ),
      AssessmentActionTask(
        id: 'rec_5',
        title: 'Delegate responsibilities',
        description:
            'Find things you can hand off to others so you can focus on your strengths.',
      ),
    ],
  };

  List<AssessmentActionTask> tasksForPath(String? path) {
    if (path != null && _defaultTasksByPath.containsKey(path)) {
      return List<AssessmentActionTask>.from(_defaultTasksByPath[path]!);
    }
    return List<AssessmentActionTask>.from(_defaultTasksByPath['recalibration']!);
  }
}

final assessmentTaskCatalogProvider = Provider<AssessmentTaskCatalog>((ref) {
  return const AssessmentTaskCatalog();
});
