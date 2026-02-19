import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../domain/models/social_models.dart';

class ContactRepository {
  final DioClient _dioClient;
  final Logger _logger;
  String? _hashSalt;

  ContactRepository(this._dioClient, this._logger);

  // Initialize and fetch configuration
  Future<void> init() async {
    try {
      final response = await _dioClient.get('/public/mobile-config');
      final data = response.data['data'];
      if (data != null && data['contacts'] != null) {
        _hashSalt = data['contacts']['hash_salt'];
      }
    } catch (e) {
      _logger.e('Failed to fetch mobile config', error: e);
      // Fallback if needed, or handle error
    }
  }

  // Get device contacts
  Future<List<Contact>> getDeviceContacts() async {
    if (!await fc.FlutterContacts.requestPermission(readonly: true)) {
      throw Exception('Permission denied');
    }

    final contacts = await fc.FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    return contacts.map((c) {
      String? phone;
      if (c.phones.isNotEmpty) {
        phone = c.phones.first.normalizedNumber;
      }
      
      String? email;
      if (c.emails.isNotEmpty) {
        email = c.emails.first.address;
      }

      // Compute hash if possible for de-duplication
      String? hash;
      if (email != null) {
        hash = _hashContact(email);
      } else if (phone != null) {
        hash = _hashContact(phone, isPhone: true);
      }

      return Contact(
        deviceId: c.id,
        displayName: c.displayName,
        phoneNumber: phone,
        email: email,
        avatar: c.photo,
        status: ContactStatus.unknown,
        contactHash: hash,
      );
    }).toList();
  }

  // Hash contact for privacy-preserving discovery
  String _hashContact(String value, {bool isPhone = false}) {
    if (_hashSalt == null) {
      _logger.w('Hash salt is missing, using default');
    }
    final salt = _hashSalt ?? 'salty_compass_os_default';
    
    String normalized = value.toLowerCase().trim();
    if (isPhone) {
      // Remove all non-digit and non-plus characters
      normalized = normalized.replaceAll(RegExp(r'[^0-9+]'), '');
    }

    final bytes = utf8.encode(normalized + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Find matches on the server
  Future<List<Contact>> findPotentialContacts(List<Contact> deviceContacts) async {
    final hashes = <String>[];
    final contactMap = <String, Contact>{};

    for (final contact in deviceContacts) {
      if (contact.email != null) {
        final hash = _hashContact(contact.email!);
        hashes.add(hash);
        // We use the hash to map back, but if contact already has hash set we are good.
        // We might want to map all possible hashes to this contact
        contactMap[hash] = contact;
      }
      if (contact.phoneNumber != null) {
        final hash = _hashContact(contact.phoneNumber!, isPhone: true);
        hashes.add(hash);
        contactMap[hash] = contact;
      }
    }

    if (hashes.isEmpty) return [];

    try {
      final response = await _dioClient.post(
        '/contacts/find',
        data: {'contact_hashes': hashes},
      );

      final List<dynamic> matches = response.data['data']['potential_contacts'];
      
      return matches.map((match) {
        final hash = match['contact_hash'];
        final deviceContact = contactMap[hash];
        
        return Contact(
          id: match['id'], // Potential contact's user ID
          contactHash: hash,
          displayName: deviceContact?.displayName ?? match['display_name'] ?? 'Unknown',
          status: ContactStatus.pending,
          // Merge other fields from device if available
          deviceId: deviceContact?.deviceId,
          phoneNumber: deviceContact?.phoneNumber,
          email: deviceContact?.email,
          avatar: deviceContact?.avatar,
        );
      }).toList();
    } catch (e) {
      _logger.e('Error finding contacts', error: e);
      rethrow;
    }
  }

  // Connect with found contacts
  Future<List<Contact>> connectContacts(List<Contact> contacts) async {
    final connections = contacts.map((c) {
      return {
        'id': c.id,
        'contact_hash': c.contactHash,
        'display_name': c.displayName,
        'connection_date': DateTime.now().toIso8601String(),
      };
    }).toList();

    try {
      final response = await _dioClient.post(
        '/contacts/connections',
        data: {'connections': connections},
      );

      final List<dynamic> created = response.data['data']['connections'];
      return created.map((json) => Contact.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Error creating connections', error: e);
      rethrow;
    }
  }

  // Invite a contact
  Future<ContactInvitation> inviteContact(Contact contact) async {
    try {
      Response response;
      if (contact.email != null) {
        response = await _dioClient.post(
          '/invitations/email',
          data: {
            'email': contact.email,
            'is_anonymous': true, // Default for El-Biblio
          },
        );
      } else if (contact.phoneNumber != null) {
        response = await _dioClient.post(
          '/invitations/phone',
          data: {
            'phone': contact.phoneNumber,
            'is_anonymous': true,
          },
        );
      } else {
        throw Exception('Contact has no email or phone');
      }

      return ContactInvitation.fromJson(response.data['data']);
    } catch (e) {
      _logger.e('Error inviting contact', error: e);
      rethrow;
    }
  }
}
