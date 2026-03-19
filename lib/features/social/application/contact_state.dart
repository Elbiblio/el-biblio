import '../domain/models/social_models.dart';

class ContactState {
  final bool isLoading;
  final bool isImporting;
  final List<Contact> potentialContacts; // Found on server but not yet connected
  final List<Contact> connectedContacts;
  final List<Contact> deviceContacts; // All device contacts for inviting
  final String? error;

  const ContactState({
    this.isLoading = false,
    this.isImporting = false,
    this.potentialContacts = const [],
    this.connectedContacts = const [],
    this.deviceContacts = const [],
    this.error,
  });

  ContactState copyWith({
    bool? isLoading,
    bool? isImporting,
    List<Contact>? potentialContacts,
    List<Contact>? connectedContacts,
    List<Contact>? deviceContacts,
    String? error,
  }) {
    return ContactState(
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      potentialContacts: potentialContacts ?? this.potentialContacts,
      connectedContacts: connectedContacts ?? this.connectedContacts,
      deviceContacts: deviceContacts ?? this.deviceContacts,
      error: error,
    );
  }
  
  ContactState clearError() => ContactState(
      isLoading: isLoading,
      isImporting: isImporting,
      potentialContacts: potentialContacts,
      connectedContacts: connectedContacts,
      deviceContacts: deviceContacts,
      error: null,
  );
}
