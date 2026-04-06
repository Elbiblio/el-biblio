import '../domain/models/accountability_partner.dart';
import '../domain/models/check_in_request.dart';
import '../domain/models/mission_action.dart';
import '../domain/models/mission_focus.dart';

class MissionState {
  const MissionState({
    required this.focus,
    required this.actions,
    this.accountabilityPartner,
  });

  final MissionFocusType focus;
  final List<MissionAction> actions;
  final AccountabilityPartner? accountabilityPartner;

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
  }) {
    return MissionState(
      focus: focus ?? this.focus,
      actions: actions ?? this.actions,
      accountabilityPartner: accountabilityPartner ?? this.accountabilityPartner,
    );
  }
}
