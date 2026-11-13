import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/oauth_callback_service.dart';
import '../services/oauth_service.dart';

final dropboxBackupProvider = Provider(
  (ref) => OAuthService(
    "dropbox",
    "https://www.dropbox.com/oauth2/authorize",
    "https://api.dropboxapi.com/oauth2/token",
    const String.fromEnvironment("DROPBOX_APP_KEY"),
    "zenithlogbook://dropbox",
    "account_info.read",
  ),
);
final dropboxAuthProvider = AsyncNotifierProvider<DropboxAuthNotifier, bool>(
  DropboxAuthNotifier.new,
);

class DropboxAuthNotifier extends AsyncNotifier<bool> {
  OAuthService get _service => ref.read(dropboxBackupProvider);
  @override
  Future<bool> build() => _service.isLoggedIn();
  Future<void> login() async {
    final url = await _service.startLogin();
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AsyncData(false);
  }
}

final callbackServiceProvider = Provider((ref) {
  final handler = OAuthCallbackHandler(
    oauthServices: [ref.watch(dropboxBackupProvider)],
    onLoginSuccess: () => ref.invalidate(dropboxAuthProvider),
  );
  ref.onDispose(handler.dispose);
  return handler;
});
