import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import '../../../alignment/data/forty_day_templates.dart';
import '../../../alignment/data/habit_catalog.dart';
import '../../../alignment/domain/models/forty_day_goal.dart';
import '../../../alignment/domain/models/habit_assessment.dart';
import '../../../vision/domain/vision_models.dart';
import '../../domain/models/commitment_schedule.dart';
import '../../application/overlay_notification_service.dart';
import '../widgets/schedule_picker_widget.dart';

enum WizardPath { goodHabit, stopBadHabit, fortyDay }

class CommitmentWizardScreen extends ConsumerStatefulWidget {
  const CommitmentWizardScreen({super.key});

  @override
  ConsumerState<CommitmentWizardScreen> createState() =>
      _CommitmentWizardScreenState();
}

class _CommitmentWizardScreenState
    extends ConsumerState<CommitmentWizardScreen> {
  int _step = 0;
  WizardPath? _selectedPath;
  HabitItem? _selectedBadHabit;
  String? _selectedReplacement;
  String? _triggerContext;
  String? _accountabilityContact;
  HabitItem? _selectedGoodHabit;
  FortyDayGoal? _selectedFortyDay;
  int _dailyLoad = 1;
  List<TimeOfDay> _scheduleTimes = [];
  bool _saving = false;

  static const _totalSteps = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Commitment'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _StepIndicator(
                currentStep: _step,
                totalSteps: _totalSteps,
                selectedPath: _selectedPath,
              ),
              Expanded(
                  child: SafeListView(
                  bottomPadding: shellChromeBottomPadding,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [_buildStepContent()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _ChoosePathStep(
        selectedPath: _selectedPath,
        onSelected: (path) => setState(() {
          _selectedPath = path;
          _step = 1;
        }),
      ),
      1 => _buildPathDetailStep(),
      2 => _buildAccountabilityStep(),
      3 => _buildScheduleStep(),
      4 => _buildReviewStep(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildPathDetailStep() {
    return switch (_selectedPath) {
      WizardPath.stopBadHabit => _StopBadHabitStep(
        habits: HabitCatalog.badHabits,
        selectedHabit: _selectedBadHabit,
        selectedReplacement: _selectedReplacement,
        triggerContext: _triggerContext,
        onHabitSelected: (h) => setState(() {
          _selectedBadHabit = h;
          _selectedReplacement = h.counterHabit;
        }),
        onReplacementChanged: (r) =>
            setState(() => _selectedReplacement = r),
        onTriggerChanged: (t) =>
            setState(() => _triggerContext = t),
        onNext: () => setState(() => _step = 2),
      ),
      WizardPath.goodHabit => _StartGoodHabitStep(
        habits: HabitCatalog.goodHabits,
        selectedHabit: _selectedGoodHabit,
        dailyLoad: _dailyLoad,
        onHabitSelected: (h) =>
            setState(() => _selectedGoodHabit = h),
        onLoadChanged: (l) => setState(() => _dailyLoad = l),
        onNext: () => setState(() => _step = 2),
      ),
      WizardPath.fortyDay => _FortyDayStep(
        templates: FortyDayTemplates.allTemplates,
        selectedTemplate: _selectedFortyDay,
        onSelected: (t) => setState(() => _selectedFortyDay = t),
        onNext: () => setState(() => _step = 2),
      ),
      null => const SizedBox.shrink(),
    };
  }

  Widget _buildAccountabilityStep() {
    return _AccountabilityStep(
      selectedContact: _accountabilityContact,
      onChanged: (c) => setState(() => _accountabilityContact = c),
      onBack: () => setState(() => _step = 1),
      onNext: () => setState(() => _step = 3),
    );
  }

  Widget _buildScheduleStep() {
    return _ScheduleStep(
      scheduleTimes: _scheduleTimes,
      onChanged: (t) => setState(() => _scheduleTimes = t),
      onBack: () => setState(() => _step = 2),
      onNext: () => setState(() => _step = 4),
    );
  }

  Widget _buildReviewStep() {
    return _ReviewStep(
      path: _selectedPath,
      habitName: _selectedBadHabit?.name ??
          _selectedGoodHabit?.name ??
          _selectedFortyDay?.title ??
          '',
      replacement: _selectedReplacement,
      trigger: _triggerContext,
      accountability: _accountabilityContact,
      times: _scheduleTimes,
      dailyLoad: _dailyLoad,
      isSaving: _saving,
      onBack: () => setState(() => _step = 3),
      onConfirm: _startCommitment,
    );
  }

  Future<void> _startCommitment() async {
    setState(() => _saving = true);

    try {
      final plan = _buildPlan();
      if (plan == null) return;

      final joined = await ref.read(visionProvider.notifier).joinCommitment(
        plan,
        _scheduleTimes.length.clamp(plan.nudgeMin, plan.nudgeMax),
        dailyLoadCount: _dailyLoad,
        planWhen: _scheduleTimes.isNotEmpty
            ? _scheduleTimes
                .map((t) =>
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
                .join(', ')
            : null,
        planObstacle: _triggerContext,
      );

      if (joined && _scheduleTimes.isNotEmpty) {
        final commitmentSchedule = CommitmentSchedule(
          commitmentId: plan.id,
          checkInTimes: _scheduleTimes,
          activeDays: List.generate(7, (i) => i + 1),
          skipDaysAllowed: 2,
          overlayEnabled: true,
        );

        try {
          await overlayNotificationService.scheduleFromSchedule(
            schedule: commitmentSchedule,
            commitmentTitle: plan.title,
            category: plan.category,
            totalDays: plan.durationDays,
          );
        } catch (e) {
          debugPrint('CommitmentWizard: Failed to schedule notifications: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commitment started!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  CommitmentPlan? _buildPlan() {
    final basePlan = switch (_selectedPath) {
      WizardPath.stopBadHabit => _selectedBadHabit != null
          ? CommitmentPlan(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: 'Stop: ${_selectedBadHabit!.name}',
              description: _selectedReplacement != null
                  ? 'Replace with: $_selectedReplacement'
                  : _selectedBadHabit!.description,
              durationDays: 30,
              category: _selectedBadHabit!.category.name,
              dailyAction: _selectedReplacement ??
                  _selectedBadHabit!.counterHabit ??
                  _selectedBadHabit!.name,
              nudgeMin: 1,
              nudgeMax: 3,
            )
          : null,
      WizardPath.goodHabit => _selectedGoodHabit != null
          ? CommitmentPlan(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: _selectedGoodHabit!.name,
              description: _selectedGoodHabit!.description,
              durationDays: 30,
              category: _selectedGoodHabit!.category.name,
              dailyAction: _selectedGoodHabit!.name,
              nudgeMin: 1,
              nudgeMax: 3,
            )
          : null,
      WizardPath.fortyDay => _selectedFortyDay != null
          ? CommitmentPlan(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: _selectedFortyDay!.title,
              description: _selectedFortyDay!.description,
              durationDays: 40,
              category: _selectedFortyDay!.category,
              dailyAction: 'Follow the ${_selectedFortyDay!.title} plan',
              nudgeMin: 1,
              nudgeMax: 3,
            )
          : null,
      null => null,
    };
    return basePlan;
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.selectedPath,
  });

  final int currentStep;
  final int totalSteps;
  final WizardPath? selectedPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepLabels = ['Choose', 'Detail', 'People', 'Schedule', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone || isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(Icons.check,
                                size: 16, color: theme.colorScheme.onPrimary)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepLabels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ChoosePathStep extends StatelessWidget {
  const _ChoosePathStep({
    required this.selectedPath,
    required this.onSelected,
  });

  final WizardPath? selectedPath;
  final ValueChanged<WizardPath> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you want to do?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose one path to begin.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 24),
        _PathCard(
          icon: LucideIcons.repeat2,
          title: 'Stop a bad habit',
          description: 'Break a pattern that\'s holding you back',
          accentColor: const Color(0xFFE53935),
          onTap: () => onSelected(WizardPath.stopBadHabit),
        ),
        const SizedBox(height: 12),
        _PathCard(
          icon: LucideIcons.sprout,
          title: 'Start a good habit',
          description: 'Build a new spiritual discipline',
          accentColor: const Color(0xFF4CAF50),
          onTap: () => onSelected(WizardPath.goodHabit),
        ),
        const SizedBox(height: 12),
        _PathCard(
          icon: LucideIcons.calendarDays,
          title: 'Follow a 40-day plan',
          description: 'A guided journey with daily tasks',
          accentColor: const Color(0xFF7B68EE),
          onTap: () => onSelected(WizardPath.fortyDay),
        ),
      ],
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    Text(description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        )),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopBadHabitStep extends StatelessWidget {
  const _StopBadHabitStep({
    required this.habits,
    required this.selectedHabit,
    required this.selectedReplacement,
    required this.triggerContext,
    required this.onHabitSelected,
    required this.onReplacementChanged,
    required this.onTriggerChanged,
    required this.onNext,
  });

  final List<HabitItem> habits;
  final HabitItem? selectedHabit;
  final String? selectedReplacement;
  final String? triggerContext;
  final ValueChanged<HabitItem> onHabitSelected;
  final ValueChanged<String> onReplacementChanged;
  final ValueChanged<String> onTriggerChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Which struggle?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 4),
        Text('Pick one pattern to work on.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
        const SizedBox(height: 16),
        ...habits.map((habit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceChip(
                selected: selectedHabit?.id == habit.id,
                label: Text(habit.name),
                onSelected: (_) => onHabitSelected(habit),
              ),
            )),
        if (selectedHabit != null) ...[
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'What triggers this?',
              hintText: 'Situation, emotion, time of day, person',
              border: OutlineInputBorder(),
            ),
            onChanged: onTriggerChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Healthier replacement',
              hintText: selectedHabit!.counterHabit ?? 'What will you do instead?',
              border: const OutlineInputBorder(),
            ),
            controller: TextEditingController(
              text: selectedReplacement ?? selectedHabit!.counterHabit ?? '',
            ),
            onChanged: onReplacementChanged,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: selectedReplacement != null &&
                      selectedReplacement!.isNotEmpty
                  ? onNext
                  : null,
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              label: const Text('Continue'),
            ),
          ),
        ],
      ],
    );
  }
}

class _StartGoodHabitStep extends StatelessWidget {
  const _StartGoodHabitStep({
    required this.habits,
    required this.selectedHabit,
    required this.dailyLoad,
    required this.onHabitSelected,
    required this.onLoadChanged,
    required this.onNext,
  });

  final List<HabitItem> habits;
  final HabitItem? selectedHabit;
  final int dailyLoad;
  final ValueChanged<HabitItem> onHabitSelected;
  final ValueChanged<int> onLoadChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Which habit?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 4),
        Text('Pick one new discipline to start.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
        const SizedBox(height: 16),
        ...habits.map((habit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceChip(
                selected: selectedHabit?.id == habit.id,
                label: Text(habit.name),
                onSelected: (_) => onHabitSelected(habit),
              ),
            )),
        if (selectedHabit != null) ...[
          const SizedBox(height: 16),
          Text('Daily load',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('Light'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: 2, label: Text('Steady'), icon: Icon(Icons.balance)),
              ButtonSegment(value: 3, label: Text('Deep'), icon: Icon(Icons.auto_stories)),
            ],
            selected: {dailyLoad},
            onSelectionChanged: (v) => onLoadChanged(v.first),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              label: const Text('Continue'),
            ),
          ),
        ],
      ],
    );
  }
}

class _FortyDayStep extends StatelessWidget {
  const _FortyDayStep({
    required this.templates,
    required this.selectedTemplate,
    required this.onSelected,
    required this.onNext,
  });

  final List<FortyDayGoal> templates;
  final FortyDayGoal? selectedTemplate;
  final ValueChanged<FortyDayGoal> onSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose a 40-day plan',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 4),
        Text('A guided journey with daily tasks.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
        const SizedBox(height: 16),
        ...templates.map((template) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TemplateCard(
                template: template,
                isSelected: selectedTemplate?.id == template.id,
                onTap: () => onSelected(template),
              ),
            )),
        if (selectedTemplate != null) ...[
          const SizedBox(height: 8),
          Text('Preview: First 7 days',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          ...selectedTemplate!.dailyTasks.take(7).map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${task.dayNumber}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(task.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              label: const Text('Continue'),
            ),
          ),
        ],
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final FortyDayGoal template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      '40 days • ${template.dailyTasks.length} tasks',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(LucideIcons.checkCircle,
                    color: theme.colorScheme.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountabilityStep extends StatelessWidget {
  const _AccountabilityStep({
    required this.selectedContact,
    required this.onChanged,
    required this.onBack,
    required this.onNext,
  });

  final String? selectedContact;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who walks with you?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 4),
        Text('Choose who will support you in this commitment.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
        const SizedBox(height: 16),
        _AccountabilityOption(
          icon: LucideIcons.messageCircle,
          title: 'Just me and my companion',
          description: 'AI companion checks in on you',
          isSelected: selectedContact == 'companion',
          onTap: () => onChanged('companion'),
        ),
        const SizedBox(height: 8),
        _AccountabilityOption(
          icon: LucideIcons.users,
          title: 'My accountability partner',
          description: 'A trusted friend sees your progress',
          isSelected: selectedContact == 'partner',
          onTap: () => onChanged('partner'),
        ),
        const SizedBox(height: 8),
        _AccountabilityOption(
          icon: LucideIcons.heartHandshake,
          title: 'My circle',
          description: 'Your tribe or group walks together',
          isSelected: selectedContact == 'circle',
          onTap: () => onChanged('circle'),
        ),
        const SizedBox(height: 8),
        _AccountabilityOption(
          icon: LucideIcons.user,
          title: 'Just me',
          description: 'Private commitment, no sharing',
          isSelected: selectedContact == 'solo',
          onTap: () => onChanged('solo'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(LucideIcons.arrowLeft, size: 16),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: selectedContact != null ? onNext : null,
                icon: const Icon(LucideIcons.arrowRight, size: 18),
                label: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountabilityOption extends StatelessWidget {
  const _AccountabilityOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 22,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    Text(description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        )),
                  ],
                ),
              ),
              if (isSelected)
                Icon(LucideIcons.checkCircle,
                    color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep({
    required this.scheduleTimes,
    required this.onChanged,
    required this.onBack,
    required this.onNext,
  });

  final List<TimeOfDay> scheduleTimes;
  final ValueChanged<List<TimeOfDay>> onChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When should we check in?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 4),
        Text('We\'ll send rich notification overlays. You\'ll need to respond.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
        const SizedBox(height: 20),
        SchedulePickerWidget(
          initialTimes: scheduleTimes,
          onChanged: onChanged,
          maxTimes: 3,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(LucideIcons.arrowLeft, size: 16),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: scheduleTimes.isNotEmpty ? onNext : null,
                icon: const Icon(LucideIcons.arrowRight, size: 18),
                label: const Text('Review'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.path,
    required this.habitName,
    this.replacement,
    this.trigger,
    this.accountability,
    required this.times,
    required this.dailyLoad,
    required this.isSaving,
    required this.onBack,
    required this.onConfirm,
  });

  final WizardPath? path;
  final String habitName;
  final String? replacement;
  final String? trigger;
  final String? accountability;
  final List<TimeOfDay> times;
  final int dailyLoad;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your commitment',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 4),
        Text('Make sure everything looks right before you begin.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
        const SizedBox(height: 20),
        _ReviewRow(
          icon: LucideIcons.target,
          label: 'Focus',
          value: habitName,
        ),
        if (replacement != null)
          _ReviewRow(
            icon: LucideIcons.repeat2,
            label: 'Replacement',
            value: replacement!,
          ),
        if (trigger != null && trigger!.isNotEmpty)
          _ReviewRow(
            icon: LucideIcons.zap,
            label: 'Trigger',
            value: trigger!,
          ),
        _ReviewRow(
          icon: LucideIcons.layers,
          label: 'Daily load',
          value: ['Light', 'Steady', 'Deep'][dailyLoad - 1],
        ),
        _ReviewRow(
          icon: LucideIcons.clock,
          label: 'Check-ins',
          value: times.isEmpty
              ? 'None set'
              : times
                  .map((t) => t.format(context))
                  .join(', '),
        ),
        _ReviewRow(
          icon: LucideIcons.heartHandshake,
          label: 'Accountability',
          value: accountability == 'solo'
              ? 'Just me'
              : accountability == 'companion'
                  ? 'AI Companion'
                  : accountability == 'partner'
                      ? 'Accountability Partner'
                      : accountability == 'circle'
                          ? 'My Circle'
                          : 'Not set',
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onBack,
                icon: const Icon(LucideIcons.arrowLeft, size: 16),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onConfirm,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.flag, size: 18),
                label: Text(isSaving ? 'Starting...' : 'Begin'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                )),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}
