import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/contact_repository.dart';
import '../domain/models/social_models.dart';
import 'contact_state.dart';

class ContactNotifier extends StateNotifier<ContactState> {
  final ContactRepository _repository;

  ContactNotifier(this._repository) : super(const ContactState()) {
    _init();
  }

  Future<void> _init() async {
    await _repository.init();
  }

  Future<void> importContacts() async {
    state = state.copyWith(isImporting: true, error: null);
    try {
      // 1. Get device contacts
      final deviceContacts = await _repository.getDeviceContacts();
      state = state.copyWith(deviceContacts: deviceContacts);

      // 2. Find potential matches on server
      final matches = await _repository.findPotentialContacts(deviceContacts);
      
      // 3. Filter matches out of device contacts to avoid duplication in UI
      final matchedHashes = matches.map((c) => c.contactHash).toSet();
      
      final uniqueDeviceContacts = deviceContacts.where((c) {
        // Keep only if NO hash matches any found potential contact
        // Note: A device contact might have generated multiple hashes (email + phone).
        // If ANY of them matched, it's a match.
        // Our simplified getDeviceContacts computes one 'primary' hash for the model 'contactHash'.
        // But findPotentialContacts checks both.
        // If match.contactHash equals c.contactHash, we hide it from device list.
        return c.contactHash == null || !matchedHashes.contains(c.contactHash);
      }).toList();
      
      state = state.copyWith(
        deviceContacts: uniqueDeviceContacts,
        potentialContacts: matches, 
        isImporting: false
      );
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: 'Failed to import contacts: ${e.toString()}',
      );
    }
  }

  Future<void> connect(Contact contact) async {
    try {
      await _repository.connectContacts([contact]);
      
      // Move from potential to connected
      final updatedPotential = state.potentialContacts
          .where((c) => c.contactHash != contact.contactHash)
          .toList();
          
      final updatedConnected = [...state.connectedContacts, contact.copyWith(status: ContactStatus.connected)];

      state = state.copyWith(
        potentialContacts: updatedPotential,
        connectedContacts: updatedConnected,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to connect: ${e.toString()}');
    }
  }
  
  Future<void> connectAll(List<Contact> contacts) async {
     try {
      await _repository.connectContacts(contacts);
      
      final hashSet = contacts.map((c) => c.contactHash).toSet();
      
      final updatedPotential = state.potentialContacts
          .where((c) => !hashSet.contains(c.contactHash))
          .toList();
          
      final newConnected = contacts.map((c) => c.copyWith(status: ContactStatus.connected));
      final updatedConnected = [...state.connectedContacts, ...newConnected];

      state = state.copyWith(
        potentialContacts: updatedPotential,
        connectedContacts: updatedConnected,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to connect all: ${e.toString()}');
    }
  }

  Future<void> invite(Contact contact) async {
    try {
      await _repository.inviteContact(contact);
      
      // Update local state to show 'Invited' (pending status)
      final updatedDeviceContacts = state.deviceContacts.map((c) {
        // Use deviceId to match if available, otherwise try email/phone
        bool match = false;
        if (c.deviceId != null && contact.deviceId != null) {
          match = c.deviceId == contact.deviceId;
        } else {
          match = (c.email != null && c.email == contact.email) || 
                  (c.phoneNumber != null && c.phoneNumber == contact.phoneNumber);
        }
        
        if (match) {
          return c.copyWith(status: ContactStatus.pending);
        }
        return c;
      }).toList();
      
      state = state.copyWith(deviceContacts: updatedDeviceContacts);
    } catch (e) {
      state = state.copyWith(error: 'Failed to invite: ${e.toString()}');
    }
  }
}
