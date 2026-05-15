enum AccountabilityTone {
  gentle,
  balanced,
  firm;

  static AccountabilityTone fromStorage(String? value) {
    return switch (value) {
      'gentle' => AccountabilityTone.gentle,
      'firm' => AccountabilityTone.firm,
      _ => AccountabilityTone.balanced,
    };
  }

  String get storageValue => name;

  String get label {
    return switch (this) {
      AccountabilityTone.gentle => 'Gentle',
      AccountabilityTone.balanced => 'Balanced',
      AccountabilityTone.firm => 'Firm',
    };
  }

  String get description {
    return switch (this) {
      AccountabilityTone.gentle =>
        'Encouragement first, with space to reflect when a day gets hard.',
      AccountabilityTone.balanced =>
        'A steady mix of grace, structure, and clear next steps.',
      AccountabilityTone.firm =>
        'Stronger structure when you want the app to hold the line with you.',
    };
  }
}

enum CommitmentMonthlyReviewOutcome {
  continuePractice,
  deepen,
  switchFocus;

  static CommitmentMonthlyReviewOutcome? fromStorage(String? value) {
    return switch (value) {
      'continue' => CommitmentMonthlyReviewOutcome.continuePractice,
      'deepen' => CommitmentMonthlyReviewOutcome.deepen,
      'switch' => CommitmentMonthlyReviewOutcome.switchFocus,
      _ => null,
    };
  }

  String get storageValue {
    return switch (this) {
      CommitmentMonthlyReviewOutcome.continuePractice => 'continue',
      CommitmentMonthlyReviewOutcome.deepen => 'deepen',
      CommitmentMonthlyReviewOutcome.switchFocus => 'switch',
    };
  }
}
