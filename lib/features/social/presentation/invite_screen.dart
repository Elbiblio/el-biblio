import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../domain/models/social_models.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final Set<String> _selectedContactIds = {};
  bool _isInviting = false;

  @override
  void initState() {
    super.initState();
    // Load contacts when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contactProvider.notifier).importContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<Contact> _getFilteredContacts(List<Contact> contacts) {
    final query = _searchController.text.toLowerCase();
    
    // Filter contacts that have email or phone
    final contactsWithContactInfo = contacts.where((contact) => 
      contact.email != null || contact.phoneNumber != null
    ).toList();
    
    // Apply search filter
    if (query.isEmpty) {
      return contactsWithContactInfo;
    }
    
    return contactsWithContactInfo.where((contact) =>
      contact.displayName.toLowerCase().contains(query) ||
      (contact.email?.toLowerCase().contains(query) ?? false) ||
      (contact.phoneNumber?.contains(query) ?? false)
    ).toList();
  }

  Future<void> _sendInvitations() async {
    final contactState = ref.read(contactProvider);
    final selectedContacts = contactState.deviceContacts.where((contact) =>
      _selectedContactIds.contains(contact.deviceId)
    ).toList();

    if (selectedContacts.isEmpty && _emailController.text.isEmpty && _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select contacts or enter email/phone')),
      );
      return;
    }

    setState(() {
      _isInviting = true;
    });

    try {
      int successCount = 0;
      int failureCount = 0;

      // Invite selected contacts
      for (final contact in selectedContacts) {
        try {
          await ref.read(contactProvider.notifier).invite(contact);
          successCount++;
        } catch (_) {
          failureCount++;
        }
      }

      // Invite manual entries
      if (_emailController.text.isNotEmpty) {
        try {
          final emailContact = Contact(
            displayName: 'Manual Email',
            email: _emailController.text.trim(),
            isAnonymous: false,
          );
          await ref.read(contactProvider.notifier).invite(emailContact);
          successCount++;
        } catch (_) {
          failureCount++;
        }
      }
      if (_phoneController.text.isNotEmpty) {
        try {
          final phoneContact = Contact(
            displayName: 'Manual Phone',
            phoneNumber: _phoneController.text.trim(),
            isAnonymous: false,
          );
          await ref.read(contactProvider.notifier).invite(phoneContact);
          successCount++;
        } catch (_) {
          failureCount++;
        }
      }

      if (mounted) {
        final totalAttempted = successCount + failureCount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failureCount == 0
                  ? 'Invitations sent to $successCount contact(s)!'
                  : 'Sent $successCount of $totalAttempted invitation(s).',
            ),
          ),
        );
        
        // Clear selections
        setState(() {
          _selectedContactIds.clear();
          _emailController.clear();
          _phoneController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invitations: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactState = ref.watch(contactProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final filteredContacts = _getFilteredContacts(contactState.deviceContacts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Friends'),
        backgroundColor: isDark ? const Color(0xFF101822) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      backgroundColor: isDark ? const Color(0xFF0F1419) : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          
          // Contacts List or Loading
          Expanded(
            child: contactState.isImporting
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      // ── Friends already on El-Biblio ──────────────────────
                      if (contactState.potentialContacts.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Friends on El-Biblio',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${contactState.potentialContacts.length}',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final contact = contactState.potentialContacts[index];
                              return _PotentialContactTile(
                                contact: contact,
                                onConnect: () => ref.read(contactProvider.notifier).connect(contact),
                                onAddAsPartner: () {
                                  ref.read(missionProvider.notifier).savePartnerEnhanced(
                                    name: contact.displayName,
                                    relationship: 'Accountability Partner',
                                    contact: contact.email ?? contact.phoneNumber ?? '',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${contact.displayName} added as your accountability partner!'),
                                      action: SnackBarAction(
                                        label: 'View',
                                        onPressed: () => context.push(AppRoutes.growTogether),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: contactState.potentialContacts.length,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Invite Others',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      // ── Device contacts to invite ──────────────────────────
                      if (contactState.deviceContacts.isEmpty)
                        SliverFillRemaining(
                          child: _buildEmptyState(context),
                        )
                      else if (filteredContacts.isEmpty)
                        SliverFillRemaining(
                          child: _buildNoSearchResults(context),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final contact = filteredContacts[index];
                                final isSelected = _selectedContactIds.contains(contact.deviceId);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ContactTile(
                                    contact: contact,
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedContactIds.remove(contact.deviceId!);
                                        } else {
                                          _selectedContactIds.add(contact.deviceId!);
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                              childCount: filteredContacts.length,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          
          // Manual Invite Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite manually',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F1419) : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Phone',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F1419) : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Send Button
          Container(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isInviting ? null : _sendInvitations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isInviting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Sending...'),
                        ],
                      )
                    : Text(
                        'Send Invitations (${_selectedContactIds.length + (_emailController.text.isNotEmpty || _phoneController.text.isNotEmpty ? 1 : 0)})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure contacts have email or phone numbers',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(contactProvider.notifier).importContacts(),
              child: const Text('Import Contacts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different name, email, or phone number.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile for a contact already found on El-Biblio — shows Connect + Add as Partner CTAs.
class _PotentialContactTile extends StatelessWidget {
  const _PotentialContactTile({
    required this.contact,
    required this.onConnect,
    required this.onAddAsPartner,
  });

  final Contact contact;
  final VoidCallback onConnect;
  final VoidCallback onAddAsPartner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: contact.avatar != null
                ? ClipOval(
                    child: Image.memory(
                      Uint8List.fromList(contact.avatar!),
                      width: 44, height: 44, fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    contact.displayName.isNotEmpty
                        ? contact.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'On El-Biblio',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: onConnect,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Connect', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onAddAsPartner,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '+ Partner',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });

  final Contact contact;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primaryContainer,
          child: contact.avatar != null
              ? ClipOval(
                  child: Image.memory(
                    Uint8List.fromList(contact.avatar!),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              : Text(
                  contact.displayName.isNotEmpty 
                      ? contact.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          contact.displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.email != null)
              Text(
                contact.email!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (contact.phoneNumber != null)
              Text(
                contact.phoneNumber!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : Icon(
                Icons.circle_outlined,
                color: Colors.grey.shade400,
              ),
        onTap: onTap,
      ),
    );
  }
}
