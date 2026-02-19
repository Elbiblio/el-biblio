import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../onboarding/application/onboarding_notifier.dart';
import '../../../onboarding/presentation/widgets/responsive_layout_builder.dart';
import '../../application/contact_notifier.dart';
import '../../application/contact_state.dart';
import '../../domain/models/social_models.dart';

class SocialOnboardingView extends ConsumerWidget {
  const SocialOnboardingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    final contactState = ref.watch(contactProvider);
    final contactNotifier = ref.read(contactProvider.notifier);

    // Sync onboarding state with contact state if needed
    ref.listen(contactProvider, (previous, next) {
      if ((previous == null || previous.deviceContacts.isEmpty) && next.deviceContacts.isNotEmpty) {
        onboardingNotifier.setContactsImported(true);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: onboardingState.socialPresenceOptIn,
          title: Text(
            'Connect with contacts',
            style: TextStyle(
              fontSize: ResponsiveFontSize.getBodyLarge(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Find friends using El-Biblio',
            style: TextStyle(
              fontSize: ResponsiveFontSize.getBodyMedium(context),
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          onChanged: (value) {
             onboardingNotifier.setSocialPresenceOptIn(value);
          },
        ),
        
        if (onboardingState.socialPresenceOptIn) ...[
          SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(16)),
          
          if (contactState.isLoading || contactState.isImporting)
            const Center(child: CircularProgressIndicator())
          else if (!onboardingState.contactsImported)
            _buildImportButton(context, contactNotifier)
          else
            _buildContactsList(context, contactState, contactNotifier),
            
          if (contactState.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                contactState.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildImportButton(BuildContext context, ContactNotifier contactNotifier) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveSpacing.getGoldenRatioSmall(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ResponsiveBorderRadius.getSmall(context)),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.contacts_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(12)),
          Text(
            'See who is here',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(8)),
          Text(
            'We will hash your contacts to find matches without storing their details.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: ResponsiveSpacing.getGoldenRatioSmall(16)),
          PrimaryButton(
            label: 'Import Contacts',
            onPressed: () => contactNotifier.importContacts(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(BuildContext context, ContactState state, ContactNotifier contactNotifier) {
    // 1. Matches (Potential Contacts)
    // 2. Invite others (Device contacts not in matches)
    
    // Filter device contacts to exclude those that are already matches
    // We only want to show invitable contacts, i.e., those who are NOT matches and NOT already connected
    
    final matches = state.potentialContacts;
    
    // For Invite list, we just take deviceContacts. 
    // We should ideally filter out those who are in 'matches'.
    // But since we don't have the hash on deviceContacts easily here without recalculating, 
    // let's just show all device contacts as "Invite" except those we know are matches by name/email if possible,
    // or just show them. 
    // Actually, `ContactRepository` implementation of `findPotentialContacts` returns `Contact` objects.
    // The `potentialContacts` are `Contact` objects with `status=pending`.
    
    // Let's simplified view:
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matches.isNotEmpty) ...[
          Text(
            'Found on Compass (${matches.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = matches[index];
              final isConnected = state.connectedContacts.any((c) => c.contactHash == contact.contactHash);
              
              return ListTile(
                leading: CircleAvatar(
                   backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                   child: Text(contact.displayName[0].toUpperCase()),
                ),
                title: Text(contact.displayName),
                subtitle: const Text('Uses El-Biblio'),
                trailing: isConnected 
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : TextButton(
                      onPressed: () => contactNotifier.connect(contact),
                      child: const Text('Connect'),
                    ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        
        Text(
          'Invite Friends',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
             fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Limit to 5 for onboarding to avoid clutter
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.deviceContacts.length > 5 ? 5 : state.deviceContacts.length,
          itemBuilder: (context, index) {
             final contact = state.deviceContacts[index];
             // Check if this contact is actually a match (if we can match by name for UI dedupe?)
             // It's tricky without hashes. Let's just list them.
             
             return ListTile(
               leading: CircleAvatar(
                 backgroundImage: contact.avatar != null 
                    ? MemoryImage(Uint8List.fromList(contact.avatar!))
                    : null,
                 backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                 child: contact.avatar == null ? Text(contact.displayName.isNotEmpty ? contact.displayName[0] : '?') : null,
               ),
               title: Text(contact.displayName),
               trailing: contact.status == ContactStatus.pending
                 ? Text(
                     'Invited',
                     style: TextStyle(
                       color: Theme.of(context).colorScheme.primary,
                       fontWeight: FontWeight.w500,
                       fontSize: 12,
                     ),
                   )
                 : TextButton(
                     onPressed: () => contactNotifier.invite(contact),
                     child: const Text('Invite'),
                   ),
             );
          },
        ),
        if (state.deviceContacts.length > 5)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: Text(
                '+ ${state.deviceContacts.length - 5} more contacts',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }
}
