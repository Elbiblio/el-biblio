import '../domain/models/social_models.dart';

class ContactState {
  final bool isLoading;
  final bool isImporting;
  final List<Contact> deviceContacts;
  final List<Contact> potentialContacts; // Found on server but not yet connected
  final List<Contact> connectedContacts;
  final String? error;

  const ContactState({
    this.isLoading = false,
    this.isImporting = false,
    this.deviceContacts = const [],
    this.potentialContacts = const [],
    this.connectedContacts = const [],
    this.error,
  });

  ContactState copyWith({
    bool? isLoading,
    bool? isImporting,
    List<Contact>? deviceContacts,
    List<Contact>? potentialContacts,
    List<Contact>? connectedContacts,
    String? error,
  }) {
    return ContactState(
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      deviceContacts: deviceContacts ?? this.deviceContacts,
      potentialContacts: potentialContacts ?? this.potentialContacts,
      connectedContacts: connectedContacts ?? this.connectedContacts,
      error: error, // If not provided, it clears the error (or keeps it? usually clears if null passed explicitly, but here we'll assume null means 'no change' if we followed typical pattern, but actually for error usually we want to clear it so nullable is tricky. Let's assume if argument is omitted it keeps current, if null passed it keeps current? Wait. Standard copyWith: if null passed, it usually means 'keep old value'. To clear, we often need a separate mechanism or Sentinel. For simplicity, let's say 'error' is passed as nullable.
      // Actually standard Riverpod copyWith:
      // error: error ?? this.error
    );
  }
  
  // Helper for clear error
  ContactState clearError() => ContactState(
      isLoading: isLoading,
      isImporting: isImporting,
      deviceContacts: deviceContacts,
      potentialContacts: potentialContacts,
      connectedContacts: connectedContacts,
      error: null,
  );
}
