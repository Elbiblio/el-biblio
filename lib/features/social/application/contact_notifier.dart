import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/xp_service.dart';
import '../data/contact_repository.dart';
import '../domain/models/social_models.dart';
import 'contact_state.dart';

class ContactNotifier extends StateNotifier<ContactState> {
  final ContactRepository _repository;
  late final Future<void> _initFuture;

  ContactNotifier(this._repository) : super(const ContactState()) {
    _initFuture = _repository.init();
  }

  Future<bool> importContacts() async {
    state = state.copyWith(isImporting: true, error: null);
    try {
      await _initFuture;
      // 1. Get device contacts
      final deviceContacts = await _repository.getDeviceContacts();

      // 2. Find potential matches on server
      List<Contact> matches = const [];
      String? discoveryError;
      try {
        matches = await _repository.findPotentialContacts(deviceContacts);
      } catch (e) {
        discoveryError =
            'Contacts imported, but failed to sync matches: ${e.toString()}';
      }

      // 3. Store device contacts for invite functionality
      state = state.copyWith(
        potentialContacts: matches,
        deviceContacts: deviceContacts,
        isImporting: false,
        error: discoveryError,
      );
      return discoveryError == null;
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: 'Failed to import contacts: ${e.toString()}',
      );
      return false;
    }
  }

  Future<Contact?> pickDeviceContact() async {
    try {
      await _initFuture;
      final contact = await _repository.pickDeviceContact();
      if (contact == null) {
        return null;
      }

      final existingIndex = state.deviceContacts.indexWhere(
        (item) => item.deviceId == contact.deviceId,
      );
      final deviceContacts = [...state.deviceContacts];
      if (existingIndex == -1) {
        deviceContacts.insert(0, contact);
      } else {
        deviceContacts[existingIndex] = contact;
      }

      state = state.copyWith(deviceContacts: deviceContacts, error: null);
      return contact;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to choose contact: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> connect(Contact contact) async {
    try {
      await _initFuture;
      await _repository.connectContacts([contact]);

      // Move from potential to connected
      final updatedPotential = state.potentialContacts
          .where((c) => c.contactHash != contact.contactHash)
          .toList();

      final updatedConnected = [
        ...state.connectedContacts,
        contact.copyWith(status: ContactStatus.connected),
      ];

      state = state.copyWith(
        potentialContacts: updatedPotential,
        connectedContacts: updatedConnected,
        error: null,
      );

      // Award XP for social connection
      await XPService.instance.addXP(
        type: XPActivityType.socialConnection,
        description: 'Connected with ${contact.displayName}',
        metadata: {
          'contactName': contact.displayName,
          'contactHash': contact.contactHash,
          'connectionDate': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to connect: ${e.toString()}');
    }
  }

  Future<void> connectAll(List<Contact> contacts) async {
    try {
      await _initFuture;
      await _repository.connectContacts(contacts);

      final hashSet = contacts.map((c) => c.contactHash).toSet();

      final updatedPotential = state.potentialContacts
          .where((c) => !hashSet.contains(c.contactHash))
          .toList();

      final newConnected = contacts.map(
        (c) => c.copyWith(status: ContactStatus.connected),
      );
      final updatedConnected = [...state.connectedContacts, ...newConnected];

      state = state.copyWith(
        potentialContacts: updatedPotential,
        connectedContacts: updatedConnected,
        error: null,
      );

      // Award XP for each social connection
      for (final contact in contacts) {
        await XPService.instance.addXP(
          type: XPActivityType.socialConnection,
          description: 'Connected with ${contact.displayName}',
          metadata: {
            'contactName': contact.displayName,
            'contactHash': contact.contactHash,
            'connectionDate': DateTime.now().toIso8601String(),
            'batchConnection': true,
          },
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to connect all: ${e.toString()}');
    }
  }

  Future<void> invite(
    Contact contact, {
    String? message,
    String? contextType,
    int? tribeId,
    int? hangoutId,
    int? commitmentId,
    String? scopeType,
    int? scopeId,
  }) async {
    try {
      await _initFuture;
      await _repository.inviteContact(
        contact,
        message: message,
        contextType: contextType,
        tribeId: tribeId,
        hangoutId: hangoutId,
        commitmentId: commitmentId,
        scopeType: scopeType,
        scopeId: scopeId,
      );
      state = state.copyWith(error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to invite: ${e.toString()}');
      rethrow;
    }
  }
}
