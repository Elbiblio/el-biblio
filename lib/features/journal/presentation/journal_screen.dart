import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../domain/models/note.dart';
import 'widgets/virtue_picker.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);
    
    // Derived state for specific sections
    final pinnedNotes = journalState.pinnedNotes;
    final unpinnedNotes = journalState.unpinnedNotes;
    
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref),
            if (!journalState.showPublicNotes)
              _buildFilterSection(context, ref),
            
            Expanded(
              child: journalState.isLoading && journalState.notes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : journalState.filteredNotes.isEmpty
                      ? _buildEmptyState(context, ref)
                      : CustomScrollView(
                          slivers: [
                            if (!journalState.showPublicNotes && pinnedNotes.isNotEmpty) ...[
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                sliver: SliverToBoxAdapter(
                                  child: Text(
                                    'Pinned',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              _buildNotesGridOrList(context, pinnedNotes, journalState.isGridView),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                sliver: SliverToBoxAdapter(
                                  child: Text(
                                    'All Notes',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            
                            // Unpinned notes (or all notes if public/no pins)
                            _buildNotesGridOrList(context, unpinnedNotes, journalState.isGridView),
                            
                            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('${AppRoutes.journal}/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);
    final notifier = ref.read(journalProvider.notifier);
    final theme = Theme.of(context);
    final isPublic = journalState.showPublicNotes;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPublic ? 'Community Notes' : 'My Notes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Toggle Visibility
              IconButton(
                icon: Icon(isPublic ? Icons.public : Icons.public_off),
                color: isPublic ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                onPressed: () => notifier.toggleShowPublicNotes(),
                tooltip: isPublic ? 'Switch to My Notes' : 'Switch to Community Notes',
              ),
              // View Mode Toggle
              IconButton(
                icon: Icon(journalState.isGridView ? Icons.grid_view : Icons.view_list),
                onPressed: () => notifier.toggleGridView(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: isPublic ? 'Search community notes...' : 'Search my notes...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            onChanged: (value) => notifier.setSearchQuery(value),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);
    final notifier = ref.read(journalProvider.notifier);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter Button (Could open modal for more complex filters)
          if (journalState.selectedVirtues.isNotEmpty)
            Padding(
               padding: const EdgeInsets.only(right: 8.0),
               child: ActionChip(
                 label: const Text('Clear'),
                 onPressed: () => notifier.clearFilters(),
                 avatar: const Icon(Icons.close, size: 16),
               ),
            ),
          
          VirtuePicker(
             selectedVirtues: journalState.selectedVirtues,
             onVirtueToggle: (v) => notifier.toggleVirtueFilter(v),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesGridOrList(BuildContext context, List<Note> notes, bool isGridView) {
    if (isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final note = notes[index];
              return _NoteGridCard(
                note: note,
                onTap: () => context.push('${AppRoutes.journal}/${note.id}'),
              );
            },
            childCount: notes.length,
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final note = notes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NoteListCard(
                  note: note,
                  onTap: () => context.push('${AppRoutes.journal}/${note.id}'),
                ),
              );
            },
            childCount: notes.length,
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);
    final hasFilters = journalState.searchQuery.isNotEmpty || journalState.selectedVirtues.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No notes found' : 'Your journal is empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          if (!hasFilters)
            OutlinedButton(
              onPressed: () => context.push('${AppRoutes.journal}/new'),
              child: const Text('Create your first note'),
            )
          else
            TextButton(
              onPressed: () => ref.read(journalProvider.notifier).clearFilters(),
              child: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }
}

class _NoteGridCard extends StatelessWidget {
  const _NoteGridCard({required this.note, required this.onTap});
  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.MMMd().format(note.updatedAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               children: [
                 if (note.isPinned) 
                    Icon(Icons.push_pin, size: 12, color: theme.colorScheme.primary),
                 const Spacer(),
                 Text(dateStr, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
               ],
             ),
             const SizedBox(height: 8),
             if (note.title?.isNotEmpty == true) ...[
               Text(
                 note.title!,
                 style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
               ),
               const SizedBox(height: 4),
             ],
             Expanded(
               child: Text(
                 note.text ?? '',
                 style: theme.textTheme.bodyMedium?.copyWith(
                   color: theme.colorScheme.onSurfaceVariant,
                 ),
                 maxLines: 6,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
             if (note.virtues.isNotEmpty) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: note.virtues.take(2).map((v) => 
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          v, 
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                        ),
                      )
                    ).toList(),
                  ),
                ),
             ],
          ],
        ),
      ),
    );
  }
}

class _NoteListCard extends StatelessWidget {
  const _NoteListCard({required this.note, required this.onTap});
  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.yMMMd().format(note.updatedAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.title?.isNotEmpty == true) ...[
              Text(
                note.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              note.text ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const Spacer(),
                if (note.virtues.isNotEmpty)
                   ...note.virtues.take(3).map((v) => Padding(
                     padding: const EdgeInsets.only(left: 4.0),
                     child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            v, 
                            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                          ),
                     ),
                   )),

                if (note.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.push_pin,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (note.isPublic)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.public,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
