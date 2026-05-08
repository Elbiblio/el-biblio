import '../domain/models/accountability_partner.dart';
import '../domain/models/kingdom_action_models.dart';
import '../domain/models/mission_action.dart';
import '../domain/models/mission_focus.dart';

class MissionState {
  const MissionState({
    required this.focus,
    required this.actions,
    this.accountabilityPartner,
    this.personCommitments = const [],
    this.generosityRecords = const [],
    this.evangelismConversations = const [],
  });

  final MissionFocusType focus;
  final List<MissionAction> actions;
  final AccountabilityPartner? accountabilityPartner;
  final List<PersonCommitment> personCommitments;
  final List<GenerosityRecord> generosityRecords;
  final List<EvangelismConversation> evangelismConversations;

  List<MissionAction> get pendingActions =>
      actions.where((item) => !item.isCompleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<MissionAction> get completedActions =>
      actions.where((item) => item.isCompleted).toList()
        ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));

  MissionAction? get nextAction {
    final pending = pendingActions;
    return pending.isEmpty ? null : pending.first;
  }

  MissionState copyWith({
    MissionFocusType? focus,
    List<MissionAction>? actions,
    AccountabilityPartner? accountabilityPartner,
    bool clearAccountabilityPartner = false,
    List<PersonCommitment>? personCommitments,
    List<GenerosityRecord>? generosityRecords,
    List<EvangelismConversation>? evangelismConversations,
  }) {
    return MissionState(
      focus: focus ?? this.focus,
      actions: actions ?? this.actions,
      accountabilityPartner: clearAccountabilityPartner
          ? null
          : (accountabilityPartner ?? this.accountabilityPartner),
      personCommitments: personCommitments ?? this.personCommitments,
      generosityRecords: generosityRecords ?? this.generosityRecords,
      evangelismConversations: evangelismConversations ?? this.evangelismConversations,
    );
  }
}
