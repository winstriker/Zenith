import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:logging/logging.dart';

import 'oauth_service.dart';

class OAuthCallbackHandler {
  OAuthCallbackHandler({required this.oauthServices, this.onLoginSuccess});

  final List<OAuthService> oauthServices;
  final void Function()? onLoginSuccess;

  final AppLinks _appLinks = AppLinks();
  final Logger logger = Logger("OAuth Callback Service");

  StreamSubscription<Uri>? _subscription;

  bool _initialized = false;
  bool _processing = false;

  /// Start listening for OAuth callbacks.
  /// To be called once when the application starts.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error) {
        logger.severe('OAuth callback error: $error');
      },
    );

    // Handle the case where the OS launched the app because of the OAuth callback.
    try {
      final initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        await _handleUri(initialUri);
      }
    } catch (error) {
      logger.severe('OAuth initial callback error: $error');
    }
  }

  Future<void> _handleUri(Uri uri) async {
    if (!_isOAuthCallback(uri) || _processing) {
      return;
    }
    _processing = true;

    try {
      await oauthServices
          .firstWhere((element) => element.provider == uri.host)
          .handleCallback(uri);

      onLoginSuccess?.call();

      logger.info('OAuth login successful.');
    } catch (error) {
      logger.severe('OAuth login failed: $error');
    } finally {
      _processing = false;
    }
  }

  bool _isOAuthCallback(Uri uri) {
    return uri.scheme == 'zenithlogbook' &&
        oauthServices.any((element) => element.provider == uri.host);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
