import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserNicknameNotifier extends Notifier<String?> {
  static const _key = 'user_nickname';

  @override
  String? build() {
    _loadNickname();
    return null;
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString(_key);
    if (nickname != null && nickname.isNotEmpty) {
      state = nickname;
    }
  }

  Future<void> setNickname(String nickname) async {
    state = nickname;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, nickname);
  }
}

final userNicknameProvider = NotifierProvider<UserNicknameNotifier, String?>(
  UserNicknameNotifier.new,
);

class UserSignatureNameNotifier extends Notifier<String?> {
  static const _key = 'user_signature_name';

  @override
  String? build() {
    _loadSignatureName();
    return null;
  }

  Future<void> _loadSignatureName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name != null && name.isNotEmpty) {
      state = name;
    }
  }

  Future<void> setSignatureName(String name) async {
    state = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name);
  }
}

final userSignatureNameProvider =
    NotifierProvider<UserSignatureNameNotifier, String?>(
      UserSignatureNameNotifier.new,
    );

class OnboardingCompleteNotifier extends Notifier<bool> {
  static const _key = 'onboarding_complete';

  @override
  bool build() {
    _loadComplete();
    return false;
  }

  Future<void> _loadComplete() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

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
  static const _key = 'pic_name_mode';

  @override
  PicNameMode build() {
    _load();
    return PicNameMode.self;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == PicNameMode.name.name) {
      state = PicNameMode.name;
    }
  }

  Future<void> setMode(PicNameMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final picNameModeProvider = NotifierProvider<PicNameModeNotifier, PicNameMode>(
  PicNameModeNotifier.new,
);
