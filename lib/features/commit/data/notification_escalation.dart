/// Notification escalation ladder for missed commitment days.
///
/// As consecutive misses increase, the notification strategy escalates
/// from gentle reminders to urgent outreach involving companions and
/// accountability partners.
class NotificationEscalation {
  const NotificationEscalation._();

  /// Get the escalation level for a given consecutive miss count.
  static EscalationLevel levelForMisses(int consecutiveMisses) {
    if (consecutiveMisses <= 1) return EscalationLevel.standard;
    if (consecutiveMisses == 2) return EscalationLevel.withPreReminder;
    if (consecutiveMisses == 3) return EscalationLevel.companionInvolvement;
    if (consecutiveMisses == 4) return EscalationLevel.partnerAlert;
    if (consecutiveMisses >= 7) return EscalationLevel.graceRestart;
    return EscalationLevel.urgent;
  }

  /// Get the notification template key for a given level.
  ///
  /// Levels that require companion/partner variables (`companionInvolvement`,
  /// `partnerAlert`, `graceRestart`) fall back to `'struggle_support'` until
  /// companion and partner data is wired into the scheduling call chain.
  /// Use the preferred template keys once callers supply the required vars:
  ///   - `companionInvolvement` → `'companion_nudge'` (needs `companion`, `message`)
  ///   - `partnerAlert` → `'partner_activity'` (needs `partner`)
  ///   - `graceRestart` → `'failure_admission_response'` (needs `companion`)
  static String templateKey(EscalationLevel level) {
    switch (level) {
      case EscalationLevel.standard:
        return 'commitment_check_in';
      case EscalationLevel.withPreReminder:
        return 'struggle_support';
      case EscalationLevel.companionInvolvement:
        return 'struggle_support';
      case EscalationLevel.partnerAlert:
        return 'struggle_support';
      case EscalationLevel.urgent:
        return 'struggle_support';
      case EscalationLevel.graceRestart:
        return 'struggle_support';
    }
  }

  /// Whether to send a pre-reminder before the main check-in.
  static bool shouldSendPreReminder(EscalationLevel level) =>
      level.index >= EscalationLevel.withPreReminder.index;

  /// Whether to notify the accountability partner.
  static bool shouldNotifyPartner(EscalationLevel level) =>
      level.index >= EscalationLevel.partnerAlert.index;

  /// Whether the companion should send a proactive message.
  static bool shouldTriggerCompanion(EscalationLevel level) =>
      level.index >= EscalationLevel.companionInvolvement.index;
}

/// Escalation levels for missed commitment check-ins.
enum EscalationLevel {
  /// Day 1: Standard overlay at agreed time.
  standard,

  /// Day 2: Overlay + pre-reminder 15 minutes before.
  withPreReminder,

  /// Day 3: Overlay + companion message.
  companionInvolvement,

  /// Day 4: Overlay + partner/circle alert.
  partnerAlert,

  /// Day 5-6: Urgent overlay — commitment at risk.
  urgent,

  /// Day 7+: Grace restart offer.
  graceRestart,
}
