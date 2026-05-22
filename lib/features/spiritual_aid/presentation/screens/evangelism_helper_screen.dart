import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../application/spiritual_aid_notifier.dart';
import '../../domain/models/evangelism_content.dart';
import '../widgets/shareable_card.dart';

class EvangelismHelperScreen extends ConsumerStatefulWidget {
  const EvangelismHelperScreen({super.key});

  @override
  ConsumerState<EvangelismHelperScreen> createState() =>
      _EvangelismHelperScreenState();
}

class _EvangelismHelperScreenState extends ConsumerState<EvangelismHelperScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ShareableCardTheme _selectedCardTheme = ShareableCardTheme.blue;

  static const _tabs = [
    _TabDef('Verse Cards', 'verse_card', Icons.image_rounded),
    _TabDef('Testimonies', 'testimony_template', Icons.person_rounded),
    _TabDef('Starters', 'conversation_starter', Icons.chat_bubble_rounded),
    _TabDef('Guides', 'guide', Icons.menu_book_rounded),
    _TabDef('Prayers', 'prayer_card', Icons.favorite_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(spiritualAidProvider.notifier)
            .filterEvangelismByType(_tabs[_tabController.index].type);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(spiritualAidProvider.notifier)
          .filterEvangelismByType(_tabs.first.type);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spiritualAidProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Scaffold(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Evangelism Helper',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
                indicatorSize: TabBarIndicatorSize.label,
                dividerHeight: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: _tabs
                    .map(
                      (t) => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 16),
                            const SizedBox(width: 6),
                            Text(t.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    return _buildContentList(
                      state.evangelismContent
                          .where((c) => c.type == tab.type)
                          .toList(),
                      tab.type,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentList(List<EvangelismContent> content, String type) {
    if (content.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final item = content[index];

        if (type == 'verse_card' || type == 'prayer_card') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildShareableItem(item),
          );
        }

        return _buildTextItem(item);
      },
    );
  }

  Widget _buildShareableItem(EvangelismContent item) {
    return Column(
      children: [
        ShareableCard(
          title: item.title,
          body: item.relatedVerse ?? item.body,
          reference: item.relatedVerseReference,
          category: item.category,
          colorTheme: _selectedCardTheme,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Color theme selector
            ...ShareableCardTheme.values.map((ct) {
              final colors = _getThemeColors(ct);
              return GestureDetector(
                onTap: () => setState(() => _selectedCardTheme = ct),
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    shape: BoxShape.circle,
                    border: _selectedCardTheme == ct
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                ),
              );
            }),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _linkToMissionAction(item),
              icon: const Icon(Icons.add_task_rounded, size: 16),
              label: const Text('Add to actions'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _shareContent(item),
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Share'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextItem(EvangelismContent item) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showContentDetail(item),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _formatCategory(item.category),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContentDetail(EvangelismContent item) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.7,
                        ),
                      ),
                      if (item.relatedVerse != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.05,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.relatedVerse!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                              if (item.relatedVerseReference != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '- ${item.relatedVerseReference}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _linkToMissionAction(item);
                              },
                              icon: const Icon(
                                Icons.add_task_rounded,
                                size: 18,
                              ),
                              label: const Text('Add to actions'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _shareContent(item);
                              },
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareContent(EvangelismContent item) {
    final buffer = StringBuffer()
      ..writeln(item.title)
      ..writeln()
      ..writeln(item.body);

    if (item.relatedVerse != null) {
      buffer
        ..writeln()
        ..writeln('"${item.relatedVerse}"');
      if (item.relatedVerseReference != null) {
        buffer.writeln('- ${item.relatedVerseReference}');
      }
    }

    buffer
      ..writeln()
      ..writeln('Shared via ElBiblio');

    Share.share(buffer.toString());
  }

  void _linkToMissionAction(EvangelismContent item) {
    ref
        .read(missionProvider.notifier)
        .addAction(
          title: item.title,
          description: item.body,
          evangelismContentId: item.id,
          requiresFollowUp: true,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${item.title}" to your actions'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Color> _getThemeColors(ShareableCardTheme ct) {
    return switch (ct) {
      ShareableCardTheme.blue => const [Color(0xFF1a3a5c), Color(0xFF2b5c8a)],
      ShareableCardTheme.purple => const [Color(0xFF4a1a5c), Color(0xFF7b3d9e)],
      ShareableCardTheme.green => const [Color(0xFF1a5c3a), Color(0xFF3d9e6b)],
      ShareableCardTheme.sunset => const [Color(0xFF8b4513), Color(0xFFc67b3c)],
      ShareableCardTheme.rose => const [Color(0xFF7a1e3a), Color(0xFFb83b5e)],
    };
  }

  String _formatCategory(String raw) {
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

class _TabDef {
  const _TabDef(this.label, this.type, this.icon);
  final String label;
  final String type;
  final IconData icon;
}
