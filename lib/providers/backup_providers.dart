import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/oauth_callback_service.dart';
import '../services/oauth_service.dart';

final callbackServiceProvider = Provider((ref) {
  return OAuthCallbackHandler(oauthServices: [ref.read(dropboxBackupProvider)]);
});

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

final dropboxBackupUIProvider = StreamProvider((ref) {
  final dropbox = ref.watch(dropboxBackupProvider);
  return Stream.value(dropbox);
});
