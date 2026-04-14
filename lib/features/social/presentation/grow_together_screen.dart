import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/app_providers.dart';
import '../../mission/presentation/widgets/accountability_check_in_sheet.dart';
import '../domain/models/social_models.dart';

class GrowTogetherScreen extends ConsumerStatefulWidget {
  const GrowTogetherScreen({super.key});

  @override
  ConsumerState<GrowTogetherScreen> createState() => _GrowTogetherScreenState();
}

class _GrowTogetherScreenState extends ConsumerState<GrowTogetherScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  String? _searchError;
  bool _showInviteOption = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mission = ref.watch(missionProvider);
    final theme = Theme.of(context);
    final partner = mission.accountabilityPartner;
    final nextAction = mission.nextAction;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grow Together'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
          children: [
            // Hero section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.14),
                    theme.colorScheme.primary.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay accountable without overcomplicating it.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Choose one trusted person, share your next step, and check in each week.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Current partner card
            if (partner != null) ...[
              _PartnerSummaryCard(),
              const SizedBox(height: 20),
            ],

            // --- Partner search/invite section ---
            Text(
              partner == null ? 'Find your accountability partner' : 'Add another partner',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by email or phone number',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),

            // Search field
            TextField(
              controller: _searchController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email or phone number',
                hintText: 'friend@example.com or +1234567890',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: _searchController.text.trim().isNotEmpty
                            ? () => _searchPartner(_searchController.text.trim())
                            : null,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) _searchPartner(value.trim());
              },
            ),

            // Search results
            if (_searchError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _searchError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],

            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._searchResults.map((user) => _buildSearchResultCard(theme, user)),
            ],

            // Invite option when user not found
            if (_showInviteOption) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_add_alt_1_rounded, size: 20,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Not on El-Biblio yet',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'ll send them an invite to join you on El-Biblio as your accountability partner.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _invitePartner(_searchQuery),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Send Invite'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Partners who miss 3 check-ins are automatically removed to keep accountability strong.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // --- Find from contacts section ---
            const Divider(),
            const SizedBox(height: 16),
            _ContactsPartnerSection(),
            const SizedBox(height: 24),

            // Current step + check-in
            if (nextAction != null && partner != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current step',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nextAction.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextAction.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.tonalIcon(
                      onPressed: () => AccountabilityCheckInSheet.show(context),
                      icon: const Icon(Icons.mark_chat_read_rounded),
                      label: const Text('Check-in'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(ThemeData theme, Map<String, dynamic> user) {
    final name = user['name'] as String? ?? 'El-Biblio User';
    final userId = user['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'El-Biblio member',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _sendPartnerRequest(userId, name),
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchPartner(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = [];
      _showInviteOption = false;
      _searchQuery = query;
    });

    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get(
        '/partnerships/search',
        queryParameters: {'query': query},
      );

      if (response.statusCode != null && response.statusCode! >= 400) {
        setState(() {
          _isSearching = false;
          _showInviteOption = true;
        });
        return;
      }

      final data = response.data['data'] as List<dynamic>? ?? [];

      setState(() {
        _isSearching = false;
        _searchResults = data.cast<Map<String, dynamic>>();
        _showInviteOption = data.isEmpty;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _showInviteOption = true;
      });
    }
  }

  Future<void> _sendPartnerRequest(dynamic userId, String name) async {
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post('/partnerships', data: {
        'partner_user_id': userId,
        'partner_type': 'peer',
      });

      // Also save locally for immediate display
      await ref.read(missionProvider.notifier).savePartner(
        name: name,
        relationship: 'Accountability Partner',
        contact: '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Partnership request sent to $name')),
      );
      setState(() {
        _searchResults = [];
        _searchController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send request. Try again.')),
      );
    }
  }

  Future<void> _invitePartner(String contact) async {
    try {
      final dio = ref.read(dioClientProvider);

      // Determine if email or phone
      final isEmail = contact.contains('@');
      await dio.post('/partnerships', data: {
        if (isEmail) 'partner_email': contact,
        if (!isEmail) 'partner_phone': contact,
        'partner_type': 'peer',
      });

      // Also share the invite link
      Share.share(
        'I\'m using El-Biblio to grow spiritually and I\'d like you to be my accountability partner. Download it here: https://elbiblio.com',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent! They\'ll be notified when they join.')),
      );
      setState(() {
        _showInviteOption = false;
        _searchController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send invite. Try again.')),
      );
    }
  }
}

/// Section that finds existing El-Biblio users from device contacts and offers
/// to add them as accountability partners directly — no email search needed.
class _ContactsPartnerSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ContactsPartnerSection> createState() =>
      _ContactsPartnerSectionState();
}

class _ContactsPartnerSectionState
    extends ConsumerState<_ContactsPartnerSection> {
  bool _hasSearched = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contactState = ref.watch(contactProvider);
    final potentialContacts = contactState.potentialContacts;

    if (!_hasSearched && potentialContacts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find from your contacts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We\'ll privately check if any of your contacts are already on El-Biblio.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: contactState.isImporting
                  ? null
                  : () async {
                      setState(() => _hasSearched = true);
                      await ref.read(contactProvider.notifier).importContacts();
                    },
              icon: contactState.isImporting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.contacts_rounded, size: 18),
              label: Text(
                contactState.isImporting
                    ? 'Searching contacts…'
                    : 'Search My Contacts',
              ),
            ),
          ),
        ],
      );
    }

    if (contactState.isImporting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (potentialContacts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_off_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'None of your contacts are on El-Biblio yet. '
                'Invite them using the search above.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '${potentialContacts.length} contact${potentialContacts.length == 1 ? '' : 's'} on El-Biblio',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...potentialContacts.map(
          (contact) => _ContactPartnerCard(contact: contact),
        ),
      ],
    );
  }
}

class _ContactPartnerCard extends ConsumerWidget {
  const _ContactPartnerCard({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mission = ref.watch(missionProvider);
    final isAlreadyPartner =
        mission.accountabilityPartner?.name == contact.displayName;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              contact.displayName.isNotEmpty
                  ? contact.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 11,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'El-Biblio member',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isAlreadyPartner)
            Chip(
              label: const Text('Partner'),
              labelStyle: const TextStyle(fontSize: 11),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          else
            FilledButton(
              onPressed: () => _addAsPartner(context, ref),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Add Partner'),
            ),
        ],
      ),
    );
  }

  Future<void> _addAsPartner(BuildContext context, WidgetRef ref) async {
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post('/partnerships', data: {
        'partner_user_id': contact.id,
        'partner_type': 'peer',
      });

      await ref.read(missionProvider.notifier).savePartnerEnhanced(
            name: contact.displayName,
            relationship: 'Accountability Partner',
            contact: contact.email ?? contact.phoneNumber ?? '',
          );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${contact.displayName} added as your partner!'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      // Still save locally even if API fails
      await ref.read(missionProvider.notifier).savePartnerEnhanced(
            name: contact.displayName,
            relationship: 'Accountability Partner',
            contact: contact.email ?? contact.phoneNumber ?? '',
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${contact.displayName} added as your partner.'),
        ),
      );
    }
  }
}

class _PartnerSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(missionProvider).accountabilityPartner!;
    final theme = Theme.of(context);
    final formatted = partner.lastCheckInAt == null
        ? 'No check-in logged yet'
        : 'Last check-in ${DateFormat('MMM d').format(partner.lastCheckInAt!)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  partner.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      partner.relationship,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            formatted,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          if ((partner.lastCheckInNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              partner.lastCheckInNote!,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
