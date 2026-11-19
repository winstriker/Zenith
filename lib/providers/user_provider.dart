import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, nickname);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, name);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
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
  PicNameMode build() {
    _load();
    return PicNameMode.self;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == PicNameMode.name.name) {
      state = PicNameMode.name;
    }
  }

  Future<void> setMode(PicNameMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, mode.name);
  }
}

final picNameModeProvider = NotifierProvider<PicNameModeNotifier, PicNameMode>(
  PicNameModeNotifier.new,
);
