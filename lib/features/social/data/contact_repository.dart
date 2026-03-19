import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../domain/models/social_models.dart';

class ContactRepository extends BaseRepository {
  final DioClient _dioClient;
  final Logger _logger;
  String? _hashSalt;

  static const String _hashSaltStorageKey = 'contacts_hash_salt';

  ContactRepository(this._dioClient, this._logger) : super(_logger);

  // Initialize and fetch configuration
  Future<void> init() async {
    try {
      final token = _dioClient.currentAuthToken;
      
      // For guest users, use default salt and skip API call
      if (isGuestToken(token)) {
        _logger.w('Guest user detected, using default hash salt');
        _hashSalt = 'salty_compass_os_default';
        return;
      }

      // Load cached salt first so offline use still matches last known backend salt
      final prefs = await SharedPreferences.getInstance();
      final cachedSalt = prefs.getString(_hashSaltStorageKey);
      if (cachedSalt != null && cachedSalt.trim().isNotEmpty) {
        _hashSalt = cachedSalt;
      }
      
      final response = await _dioClient.get('/public/mobile-config');
      final raw = response.data;
      final data = raw is Map<String, dynamic> ? raw['data'] : null;
      if (data is Map<String, dynamic> && data['contacts'] is Map<String, dynamic>) {
        final remoteSalt = data['contacts']['hash_salt']?.toString();
        if (remoteSalt != null && remoteSalt.trim().isNotEmpty) {
          _hashSalt = remoteSalt;
          await prefs.setString(_hashSaltStorageKey, remoteSalt);
        }
      }
    } catch (e) {
      _logger.e('Failed to fetch mobile config, using default salt', error: e);
      // Prefer cached salt if available, otherwise fall back to default.
      if (_hashSalt == null || _hashSalt!.trim().isEmpty) {
        _hashSalt = 'salty_compass_os_default';
      }
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
    final token = _dioClient.currentAuthToken;
    
    // For guest users, return empty list since social features require real accounts
    if (isGuestToken(token)) {
      _logger.w('Guest user detected, social features not available');
      return [];
    }
    
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

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Invalid server response while finding contacts');
      }
      if (payload['success'] != true) {
        throw Exception(payload['message']?.toString() ?? 'Failed to find contacts');
      }
      final data = payload['data'];
      final matches = data is Map<String, dynamic> ? data['potential_contacts'] : null;
      if (matches is! List) {
        return [];
      }
      
      return matches
          .whereType<Map>()
          .map((json) => Map<String, dynamic>.from(json))
          .where((match) => match['contact_hash'] != null)
          .map((match) {
        final hash = match['contact_hash']?.toString();
        final idRaw = match['id'];
        final deviceContact = contactMap[hash];
        
        return Contact(
          id: idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? ''),
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
    final token = _dioClient.currentAuthToken;
    
    // For guest users, return empty list since social features require real accounts
    if (isGuestToken(token)) {
      _logger.w('Guest user detected, social features not available');
      return [];
    }
    
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

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Invalid server response while creating connections');
      }
      if (payload['success'] != true) {
        throw Exception(payload['message']?.toString() ?? 'Failed to create connections');
      }

      final data = payload['data'];
      final created = data is Map<String, dynamic> ? data['connections'] : null;
      if (created is! List) {
        return [];
      }

      return created
          .whereType<Map>()
          .map((json) => Contact.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      _logger.e('Error creating connections', error: e);
      rethrow;
    }
  }

  // Invite a contact
  Future<ContactInvitation> inviteContact(Contact contact) async {
    final token = _dioClient.currentAuthToken;
    
    // For guest users, throw exception since social features require real accounts
    if (isGuestToken(token)) {
      _logger.w('Guest user detected, social features not available');
      throw GuestUserException('Social features not available for guest users', 'invite_contact');
    }
    
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
            'phone': _normalizePhone(contact.phoneNumber!),
            'is_anonymous': true,
          },
        );
      } else {
        throw Exception('Contact has no email or phone');
      }

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Invalid invitation response');
      }
      if (payload['success'] != true) {
        throw Exception(payload['message']?.toString() ?? 'Failed to send invitation');
      }

      final data = payload['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Missing invitation data');
      }

      final invitationId = data['invitation_id'] ?? data['id'];
      final expiresAtRaw = data['expires_at'];
      if (invitationId == null || expiresAtRaw == null) {
        throw Exception('Invalid invitation payload');
      }

      return ContactInvitation(
        id: invitationId is int ? invitationId : int.parse(invitationId.toString()),
        invitedEmail: data['invited_email']?.toString() ?? data['email']?.toString(),
        invitedPhone: data['invited_phone']?.toString() ?? data['phone']?.toString(),
        status: data['status']?.toString() ?? 'pending',
        invitationUrl: data['invitation_url']?.toString(),
        expiresAt: DateTime.parse(expiresAtRaw.toString()),
      );
    } catch (e) {
      _logger.e('Error inviting contact', error: e);
      rethrow;
    }
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}
