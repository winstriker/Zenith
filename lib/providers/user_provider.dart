import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_preferences_provider.dart';

class UserNicknameNotifier extends Notifier<String?> {
  static const prefsKey = 'user_nickname';

  @override
  String? build() {
    final nickname = ref.read(sharedPreferencesProvider).getString(prefsKey);
    return nickname == null || nickname.isEmpty ? null : nickname;
  }

  Future<void> setNickname(String nickname) async {
    state = nickname;
    await ref.read(sharedPreferencesProvider).setString(prefsKey, nickname);
  }
}

final userNicknameProvider = NotifierProvider<UserNicknameNotifier, String?>(
  UserNicknameNotifier.new,
);

class UserSignatureNameNotifier extends Notifier<String?> {
  static const prefsKey = 'user_signature_name';

  @override
  String? build() {
    final name = ref.read(sharedPreferencesProvider).getString(prefsKey);
    return name == null || name.isEmpty ? null : name;
  }

  Future<void> setSignatureName(String name) async {
    state = name;
    await ref.read(sharedPreferencesProvider).setString(prefsKey, name);
  }
}

final userSignatureNameProvider =
    NotifierProvider<UserSignatureNameNotifier, String?>(
      UserSignatureNameNotifier.new,
    );

class OnboardingCompleteNotifier extends Notifier<bool> {
  static const _key = 'onboarding_complete';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> setComplete() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

final onboardingCompleteProvider =
    NotifierProvider<OnboardingCompleteNotifier, bool>(
      OnboardingCompleteNotifier.new,
    );

enum PicNameMode { self, name }

class PicNameModeNotifier extends Notifier<PicNameMode> {
  static const prefsKey = 'pic_name_mode';

  @override
  PicNameMode build() =>
      ref.read(sharedPreferencesProvider).getString(prefsKey) ==
          PicNameMode.name.name
      ? PicNameMode.name
      : PicNameMode.self;

  Future<void> setMode(PicNameMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(prefsKey, mode.name);
  }
}

final picNameModeProvider = NotifierProvider<PicNameModeNotifier, PicNameMode>(
  PicNameModeNotifier.new,
);

/// Whether the exported logbook has a PICUS column, PICUS time going there
/// instead of in the PIC one.
class PicusColumnNotifier extends Notifier<bool> {
  static const prefsKey = 'pdf_picus_column';

  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(prefsKey) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(prefsKey, value);
  }
}

final picusColumnProvider = NotifierProvider<PicusColumnNotifier, bool>(
  PicusColumnNotifier.new,
);
