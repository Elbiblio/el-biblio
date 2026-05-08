import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/settings_notifier.dart';
import '../../../core/di/app_providers.dart';
import '../../../core/storage/app_settings.dart';
import '../data/companion_repository.dart';
import '../domain/models/companion_character.dart';

class CompanionState {
  const CompanionState({this.activeCharacter});

  /// `null` means the user hasn't picked yet. Views should prompt for selection.
  final CompanionCharacter? activeCharacter;

  CompanionState copyWith({CompanionCharacter? activeCharacter}) {
    return CompanionState(
      activeCharacter: activeCharacter ?? this.activeCharacter,
    );
  }
}

class CompanionNotifier extends StateNotifier<CompanionState> {
  CompanionNotifier({
    required CompanionRepository repository,
    required SettingsNotifier settingsNotifier,
    required AppSettings initialSettings,
  })  : _repository = repository,
        _settingsNotifier = settingsNotifier,
        super(CompanionState(
          activeCharacter: CompanionCharacterX.tryFromCode(
            initialSettings.companionCharacterCode,
          ),
        ));

  final CompanionRepository _repository;
  final SettingsNotifier _settingsNotifier;

  Future<void> select(CompanionCharacter character) async {
    state = state.copyWith(activeCharacter: character);
    await _settingsNotifier.setCompanionCharacter(character.code);
    await _repository.selectCharacter(character);
  }

  /// Sets Naomi as the default if the user skipped the selection screen.
  /// Non-destructive: does nothing if a character has already been chosen.
  Future<void> applyDefaultIfUnset() async {
    if (state.activeCharacter != null) return;
    await select(CompanionCharacter.naomi);
  }

  /// Keeps the notifier in sync with external settings changes (e.g. when
  /// the user resets onboarding or restores from backup).
  void syncFromSettings(AppSettings settings) {
    final next = CompanionCharacterX.tryFromCode(settings.companionCharacterCode);
    if (next != state.activeCharacter) {
      state = state.copyWith(activeCharacter: next);
    }
  }
}

final companionRepositoryProvider = Provider<CompanionRepository>((ref) {
  return CompanionRepository(
    ref.watch(authenticatedDioClientProvider),
    ref.watch(loggerProvider),
  );
});

final companionProvider =
    StateNotifierProvider<CompanionNotifier, CompanionState>((ref) {
  final settings = ref.watch(settingsProvider);
  final notifier = CompanionNotifier(
    repository: ref.watch(companionRepositoryProvider),
    settingsNotifier: ref.read(settingsProvider.notifier),
    initialSettings: settings,
  );

  ref.listen<AppSettings>(settingsProvider, (_, next) {
    notifier.syncFromSettings(next);
  });

  return notifier;
});
