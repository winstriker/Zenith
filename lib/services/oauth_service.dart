import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// OAuthService for PKCE-compliant providers
/// Flow:
/// - startLogin() ->
/// - web browser authentication, redirect ->
/// - handleCallback(), which calls
///   - _exchangeCodeForTokens(), which calls
///     - _saveTokens()
class OAuthService {
  OAuthService(
    this.provider,
    this.authorizationEndpoint,
    this.tokenEndpoint,
    this.clientId,
    this.redirectUri,
    this.scope, {
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  ///Unique identifier of the service, used to store tokens separately for different providers
  final String provider;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String clientId;
  final String redirectUri;
  final String scope;

  late Logger logger = Logger("$provider OAuth Service");

  late String accessTokenKey = '${provider}_access_token';
  late String refreshTokenKey = '${provider}_refresh_token';
  late String expiresAtKey = '${provider}_expires_at';

  late String verifierKey = '${provider}_pending_verifier';
  late String stateKey = '${provider}_pending_state';

  final FlutterSecureStorage _storage;

  Future<Uri> startLogin() async {
    final verifier = _generateCodeVerifier();
    final challenge = _generateCodeChallenge(verifier);

    final state = _generateRandomString(32);

    await _storage.write(key: verifierKey, value: verifier);

    await _storage.write(key: stateKey, value: state);

    final uri = Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scope,
        'state': state,
        'code_challenge': challenge,
        'token_access_type': 'offline',
        'code_challenge_method': 'S256',
      },
    );

    return uri;
  }

  Future<void> handleCallback(Uri callbackUri) async {
    final error = callbackUri.queryParameters['error'];

    if (error != null) {
      final description = callbackUri.queryParameters['error_description'];

      throw OAuthException(
        'OAuth error: $error'
        '${description != null ? ' - $description' : ''}',
      );
    }

    final code = callbackUri.queryParameters['code'];

    if (code == null || code.isEmpty) {
      throw const OAuthException('Authorization code was not returned.');
    }

    final returnedState = callbackUri.queryParameters['state'];

    final expectedState = await _storage.read(key: stateKey);

    if (expectedState == null) {
      throw const OAuthException('No pending OAuth state found.');
    }

    if (returnedState != expectedState) {
      throw const OAuthException('OAuth state validation failed.');
    }

    final verifier = await _storage.read(key: verifierKey);

    if (verifier == null) {
      throw const OAuthException('No PKCE verifier found.');
    }

    await _exchangeCodeForTokens(code: code, verifier: verifier);

    await _storage.delete(key: verifierKey);
    await _storage.delete(key: stateKey);
  }

  Future<void> _exchangeCodeForTokens({
    required String code,
    required String verifier,
  }) async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': verifier,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OAuthException(
        'Token exchange failed.\n'
        'Status: ${response.statusCode}\n'
        'Body: ${response.body}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    await _saveTokens(data);
  }

  /// Returns the existing access token if it is still valid.
  /// Otherwise it uses the refresh token to obtain a new one.
  Future<String> getAccessToken() async {
    final accessToken = await _storage.read(key: accessTokenKey);

    final expiresAtString = await _storage.read(key: expiresAtKey);

    if (accessToken != null && expiresAtString != null) {
      final expiresAt = DateTime.tryParse(expiresAtString);

      if (expiresAt != null) {
        // Refresh 60 seconds before actual expiration.
        final refreshTime = expiresAt.subtract(const Duration(seconds: 60));

        if (DateTime.now().isBefore(refreshTime)) {
          return accessToken;
        }
      }
    }

    // Access token is missing or expired.
    return refreshAccessToken();
  }

  Future<String> refreshAccessToken() async {
    final refreshToken = await _storage.read(key: refreshTokenKey);

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const OAuthException(
        'No refresh token available. User must log in again.',
      );
    }

    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // The refresh token may have expired/revoked.
      // Delete credentials so the application can request another login.
      await logout();

      throw OAuthException(
        'Token refresh failed.\n'
        'Status: ${response.statusCode}\n'
        'Body: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    await _saveTokens(
      data,

      // Some OAuth servers rotate refresh tokens.
      // If the response doesn't contain a new refresh token,
      // keep the existing one.
      existingRefreshToken: refreshToken,
    );

    final newAccessToken = data['access_token'];

    if (newAccessToken is! String || newAccessToken.isEmpty) {
      throw const OAuthException(
        'Token refresh response did not contain an access token.',
      );
    }

    return newAccessToken;
  }

  /// Save access/refresh tokens
  Future<void> _saveTokens(
    Map<String, dynamic> data, {
    String? existingRefreshToken,
  }) async {
    final accessToken = data['access_token'];

    if (accessToken is! String || accessToken.isEmpty) {
      throw const OAuthException(
        'OAuth response did not contain an access token.',
      );
    }
    await _storage.write(key: accessTokenKey, value: accessToken);

    // Refresh token
    final returnedRefreshToken = data['refresh_token'];

    if (returnedRefreshToken is String && returnedRefreshToken.isNotEmpty) {
      await _storage.write(key: refreshTokenKey, value: returnedRefreshToken);
    } else if (existingRefreshToken != null) {
      // Provider didn't rotate the refresh token.
      await _storage.write(key: refreshTokenKey, value: existingRefreshToken);
    }

    final expiresIn = data['expires_in'];

    if (expiresIn is num) {
      final expiresAt = DateTime.now().add(
        Duration(seconds: expiresIn.toInt()),
      );

      await _storage.write(
        key: expiresAtKey,
        value: expiresAt.toIso8601String(),
      );
    } else {
      // If OAuth server doesn't return expires_in,
      // this should be adapted to provider's behavior.
      await _storage.delete(key: expiresAtKey);
    }
  }

  /// Authenticated get request
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    final accessToken = await getAccessToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        ...?headers,
      },
    );

    // Optional defensive retry.
    // If the token expired unexpectedly, refresh it and retry once.
    if (response.statusCode == 401) {
      final newAccessToken = await refreshAccessToken();

      return http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $newAccessToken',
          'Accept': 'application/json',
          ...?headers,
        },
      );
    }

    return response;
  }

  Future<bool> isLoggedIn() async {
    logger.info("Checking if user is logged in...");
    final refreshToken = await _storage.read(key: refreshTokenKey);
    logger.info(
      "User is ${refreshToken != null && refreshToken.isNotEmpty ? '' : 'not '}logged in.",
    );
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.delete(key: accessTokenKey);

    await _storage.delete(key: refreshTokenKey);

    await _storage.delete(key: expiresAtKey);

    await _storage.delete(key: verifierKey);

    await _storage.delete(key: stateKey);
  }

  //PKCE HELPERS

  String _generateCodeVerifier() {
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        'abcdefghijklmnopqrstuvwxyz'
        '0123456789-._~';

    return _generateRandomString(64, characters: characters);
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);

    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  String _generateRandomString(int length, {String? characters}) {
    const defaultCharacters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        'abcdefghijklmnopqrstuvwxyz'
        '0123456789';

    final chars = characters ?? defaultCharacters;

    final random = Random.secure();

    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

class OAuthException implements Exception {
  const OAuthException(this.message);

  final String message;

  @override
  String toString() => 'OAuthException: $message';
}
