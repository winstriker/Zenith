import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/user_provider.dart';
import '../providers/carto_provider.dart';

class IntroPage extends ConsumerStatefulWidget {
  final VoidCallback onPermissionGranted;

  const IntroPage({super.key, required this.onPermissionGranted});

  @override
  ConsumerState<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends ConsumerState<IntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _requesting = false;
  bool _savingKey = false;
  String? _keyError;
  int _step = 0;
  final _nicknameController = TextEditingController();
  final _signatureController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _nicknameFocus = FocusNode();
  final _signatureFocus = FocusNode();
  final _apiKeyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nicknameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nicknameController.dispose();
    _signatureController.dispose();
    _apiKeyController.dispose();
    _nicknameFocus.dispose();
    _signatureFocus.dispose();
    _apiKeyFocus.dispose();
    super.dispose();
  }

  Future<void> _onNicknameContinue() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      _nicknameFocus.requestFocus();
      return;
    }

    await ref.read(userNicknameProvider.notifier).setNickname(nickname);

    setState(() => _step = 1);
    _controller.reset();
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _signatureFocus.requestFocus();
    });
  }

  Future<void> _onSignatureContinue() async {
    final signatureName = _signatureController.text.trim();
    if (signatureName.isEmpty) {
      _signatureFocus.requestFocus();
      return;
    }

    await ref
        .read(userSignatureNameProvider.notifier)
        .setSignatureName(signatureName);

    setState(() => _step = 2);
    _controller.reset();
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiKeyFocus.requestFocus();
    });
  }

  Future<void> _onApiKeyContinue({bool skip = false}) async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty && !skip) {
      setState(() => _keyError = 'Please enter an API key');
      _apiKeyFocus.requestFocus();
      return;
    }

    setState(() {
      _savingKey = true;
      _keyError = null;
    });

    await ref.read(cartoApiKeyProvider.notifier).setKey(key);

    if (!mounted) return;
    setState(() => _savingKey = false);

    setState(() => _step = 3);
    _controller.reset();
    _controller.forward();
  }

  Future<void> _onLocationContinue() async {
    _requestPermission();
  }

  Future<void> _skipLocation() async {
    widget.onPermissionGranted();
  }

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);

    final permission = await Geolocator.requestPermission();

    if (!mounted) return;
    setState(() => _requesting = false);

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      widget.onPermissionGranted();
    } else {
      // Permission denied, still proceed to app
      widget.onPermissionGranted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildLogo(cs),
              const SizedBox(height: 40),
              _buildTitle(theme, cs),
              const SizedBox(height: 12),
              Text(
                'Your free & opensource personal logbook',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 1),
              if (_step == 1) ...[
                const SizedBox(height: 8),
                Text(
                  'Step 2 of 4',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (_step == 2) ...[
                const SizedBox(height: 8),
                Text(
                  'Step 3 of 4',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (_step == 3) ...[
                const SizedBox(height: 8),
                Text(
                  'Step 4 of 4',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Step 1 of 4',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                  );
                },
                child: _step == 0
                    ? _buildNicknameStep(theme, cs)
                    : _step == 1
                    ? _buildSignatureStep(theme, cs)
                    : _step == 2
                    ? _buildApiKeyStep(theme, cs)
                    : _buildLocationStep(theme, cs),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme cs) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.flight, size: 60, color: cs.onPrimary),
    );
  }

  Widget _buildTitle(ThemeData theme, ColorScheme cs) {
    return Column(
      children: [
        Text(
          'Welcome to Zenith!',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNicknameStep(ThemeData theme, ColorScheme cs) {
    return Column(
      key: const ValueKey('nickname'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How should I call you?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '(nickname for greetings)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nicknameController,
          focusNode: _nicknameFocus,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nickname',
            hintText: 'e.g. Captain',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          onFieldSubmitted: (_) => _onNicknameContinue(),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _requesting ? null : _onNicknameContinue,
          icon: const Icon(Icons.arrow_forward, size: 24),
          iconAlignment: IconAlignment.end,
          label: const Text('Continue'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureStep(ThemeData theme, ColorScheme cs) {
    return Column(
      key: const ValueKey('signature'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What\'s your full name?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '(to digitally sign your logbook)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _signatureController,
          focusNode: _signatureFocus,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'e.g. John A. Smith',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          onFieldSubmitted: (_) => _onSignatureContinue(),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _requesting ? null : _onSignatureContinue,
          icon: const Icon(Icons.arrow_forward, size: 24),
          iconAlignment: IconAlignment.end,
          label: const Text('Continue'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyStep(ThemeData theme, ColorScheme cs) {
    return Column(
      key: const ValueKey('apiKey'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Map API Key (Optional)',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter a CARTO API key for high-quality vector maps.\nGet a free key at carto.com/basemaps',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _apiKeyController,
          focusNode: _apiKeyFocus,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'CARTO API Key',
            hintText: 'Paste your API key or skip',
            prefixIcon: const Icon(Icons.vpn_key_outlined),
            errorText: _keyError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          onFieldSubmitted: (_) => _onApiKeyContinue(),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _savingKey ? null : _onApiKeyContinue,
          icon: const Icon(Icons.arrow_forward, size: 24),
          iconAlignment: IconAlignment.end,
          label: const Text('Continue'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _savingKey
              ? null
              : () {
                  _apiKeyController.clear();
                  _onApiKeyContinue(skip: true);
                },
          child: Text(
            'Skip',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep(ThemeData theme, ColorScheme cs) {
    return Column(
      key: const ValueKey('location'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Location Access (Optional)',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Allow location access to find nearby airports',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _requesting ? null : _onLocationContinue,
          icon: _requesting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 24),
          iconAlignment: IconAlignment.end,
          label: Text(_requesting ? 'Requesting...' : 'Allow Location'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _requesting ? null : _skipLocation,
          child: Text(
            'Not Now',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
