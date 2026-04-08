import 'package:flutter/material.dart';

/// Dialog for collecting the user's prayer intention before starting a commitment journey.
/// Asks: "What do you ask God to do in you through this journey?"
class PrayerIntentionDialog extends StatefulWidget {
  const PrayerIntentionDialog({
    super.key,
    required this.journeyTitle,
    required this.durationDays,
    required this.virtueAlignment,
    this.onSubmit,
  });

  final String journeyTitle;
  final int durationDays;
  final String virtueAlignment;
  final void Function(String intention)? onSubmit;

  @override
  State<PrayerIntentionDialog> createState() => _PrayerIntentionDialogState();
}

class _PrayerIntentionDialogState extends State<PrayerIntentionDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  static const _examplePrompts = [
    'Patience with those I love',
    'Freedom from restless anxiety',
    'A heart that listens before speaking',
    'Courage to serve when it\'s inconvenient',
    'Discipline in my daily prayer',
    'Contentment with what I have',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectPrompt(String prompt) {
    _controller.text = prompt;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: prompt.length),
    );
  }

  void _submit() {
    final intention = _controller.text.trim();
    if (intention.isEmpty) return;
    
    widget.onSubmit?.call(intention);
    Navigator.of(context).pop(intention);
  }

  void _skip() {
    // Allow skipping but with a default intention
    const defaultIntention = 'To grow closer to God';
    widget.onSubmit?.call(defaultIntention);
    Navigator.of(context).pop(defaultIntention);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header icon
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_outline,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'What do you ask God\nto do in you?',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Through this ${widget.durationDays}-day journey in ${widget.virtueAlignment.toLowerCase()}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            // Intention input
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'My intention...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Example prompts
            Text(
              'Or choose one to inspire you:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _examplePrompts.map((prompt) {
                return ActionChip(
                  label: Text(prompt),
                  onPressed: () => _selectPrompt(prompt),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  labelStyle: theme.textTheme.bodySmall,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _controller.text.trim().isNotEmpty ? _submit : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Begin Journey'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the prayer intention dialog and returns the entered intention.
Future<String?> showPrayerIntentionDialog({
  required BuildContext context,
  required String journeyTitle,
  required int durationDays,
  required String virtueAlignment,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PrayerIntentionDialog(
      journeyTitle: journeyTitle,
      durationDays: durationDays,
      virtueAlignment: virtueAlignment,
    ),
  );
}
