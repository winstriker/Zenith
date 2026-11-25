import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/fab_hero_tags.dart';
import '../services/network.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_title.dart';

/// Where the privacy policy and terms of service markdown are published.
const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
const termsOfServiceUrl = String.fromEnvironment('TERMS_OF_SERVICE_URL');

final _legalDocProvider = FutureProvider.family<String, String>((
  ref,
  url,
) async {
  final response = await http.get(Uri.parse(url)).withTimeout();
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('Server replied ${response.statusCode}');
  }
  return utf8.decode(response.bodyBytes);
});

/// Renders a legal document (privacy policy, terms of service) fetched as
/// markdown from [url].
class LegalPage extends ConsumerWidget {
  const LegalPage({required this.title, required this.url, super.key});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(_legalDocProvider(url));

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        heroTag: closeFabHeroTag,
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          PageTitle(title, belowCloseButton: true, horizontalPadding: 0),
          ...switch (text) {
            AsyncError(:final error) => [
              EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load this page',
                subtitle: '$error',
                action: FilledButton(
                  onPressed: () => ref.invalidate(_legalDocProvider(url)),
                  child: const Text('Retry'),
                ),
              ),
            ],
            AsyncData(:final value) => [
              MarkdownBody(
                data: value,
                onTapLink: (_, href, _) {
                  final uri = href == null ? null : Uri.tryParse(href);
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
            _ => const [
              Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ],
      ),
    );
  }
}
