import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../data/contact_repository.dart';

class InviteAcceptanceScreen extends ConsumerStatefulWidget {
  const InviteAcceptanceScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InviteAcceptanceScreen> createState() =>
      _InviteAcceptanceScreenState();
}

class _InviteAcceptanceScreenState
    extends ConsumerState<InviteAcceptanceScreen> {
  late Future<InvitationPreview> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = ref
        .read(contactRepositoryProvider)
        .previewInvitation(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FCF6),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<InvitationPreview>(
                future: _previewFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _InvitePanel(
                      title: 'This invite is unavailable',
                      body:
                          'The invite may have expired or been withdrawn. You can still start fresh with ElBiblio.',
                      actions: [
                        FilledButton(
                          onPressed: () => context.go(AppRoutes.onboarding),
                          child: const Text('Start signup'),
                        ),
                      ],
                    );
                  }

                  final preview = snapshot.data!;
                  return _InvitePanel(
                    title: preview.destinationLabel,
                    subtitle: '${preview.inviterName} invited you',
                    body: preview.message?.trim().isNotEmpty == true
                        ? preview.message!.trim()
                        : 'Take a look before you join.',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ContextPill(
                              label: preview.destinationType.toUpperCase(),
                            ),
                            if (preview.expiresAt != null)
                              _ContextPill(
                                label:
                                    'EXPIRES ${_shortDate(preview.expiresAt!)}',
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Privacy',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preview.privacyNote,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF475747),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => context.go(
                          '${AppRoutes.onboarding}?invite_token=${Uri.encodeComponent(preview.token)}',
                        ),
                        child: const Text('Continue'),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.root),
                        child: const Text('Not now'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _shortDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _InvitePanel extends StatelessWidget {
  const _InvitePanel({
    required this.title,
    required this.body,
    required this.actions,
    this.subtitle,
    this.content,
  });

  final String title;
  final String? subtitle;
  final String body;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE8D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF638B6C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF1B241C),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF475747),
                height: 1.45,
              ),
            ),
            if (content != null) ...[const SizedBox(height: 22), content!],
            const SizedBox(height: 24),
            Wrap(spacing: 12, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF315C3D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
