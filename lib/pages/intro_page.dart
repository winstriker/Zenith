import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/carto_provider.dart';
import '../providers/user_provider.dart';

class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({super.key, required this.onPermissionGranted});
  final VoidCallback onPermissionGranted;

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

  Future<void> _onLocationContinue() => _requestPermission();

  Future<void> _skipLocation() async {
    await ref.read(onboardingCompleteProvider.notifier).setComplete();
    widget.onPermissionGranted();
  }

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);

    final permission = await Geolocator.requestPermission();

    if (!mounted) return;
    setState(() => _requesting = false);

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await ref.read(onboardingCompleteProvider.notifier).setComplete();
      widget.onPermissionGranted();
    } else {
      // Permission denied, still proceed to app but mark onboarding complete
      await ref.read(onboardingCompleteProvider.notifier).setComplete();
      widget.onPermissionGranted();
    }
  }

  static const _stepCount = 4;

  Widget _currentStep() {
    switch (_step) {
      case 0:
        return _TextInputStep(
          key: const ValueKey('nickname'),
          title: 'How should I call you?',
          subtitle: '(nickname for greetings)',
          controller: _nicknameController,
          focusNode: _nicknameFocus,
          label: 'Nickname',
          hint: 'e.g. Captain',
          icon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          busy: _requesting,
          onContinue: _onNicknameContinue,
        );
      case 1:
        return _TextInputStep(
          key: const ValueKey('signature'),
          title: "What's your full name?",
          subtitle: '(to digitally sign your logbook)',
          controller: _signatureController,
          focusNode: _signatureFocus,
          label: 'Full Name',
          hint: 'e.g. John A. Smith',
          icon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
          busy: _requesting,
          onContinue: _onSignatureContinue,
        );
      case 2:
        return _TextInputStep(
          key: const ValueKey('apiKey'),
          title: 'Map API Key (Optional)',
          subtitle:
              'Enter a CARTO API key for high-quality vector maps.\n'
              'Get a free key at carto.com/basemaps',
          controller: _apiKeyController,
          focusNode: _apiKeyFocus,
          label: 'CARTO API Key',
          hint: 'Paste your API key or skip',
          icon: Icons.vpn_key_outlined,
          errorText: _keyError,
          busy: _savingKey,
          onContinue: _onApiKeyContinue,
          onSkip: () {
            _apiKeyController.clear();
            _onApiKeyContinue(skip: true);
          },
        );
      default:
        return _LocationStep(
          key: const ValueKey('location'),
          requesting: _requesting,
          onAllow: _onLocationContinue,
          onSkip: _skipLocation,
        );
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
              const _IntroLogo(),
              const SizedBox(height: 40),
              Text(
                'Welcome to Zenith!',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your free & opensource personal logbook',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              const SizedBox(height: 8),
              Text(
                'Step ${_step + 1} of $_stepCount',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                child: _currentStep(),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroLogo extends StatelessWidget {
  const _IntroLogo();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
}

/// Title + subtitle shown at the top of each onboarding step.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StepPrimaryButton extends StatelessWidget {
  const _StepPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon,
      iconAlignment: IconAlignment.end,
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StepSkipButton extends StatelessWidget {
  const _StepSkipButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// An onboarding step made of a single text field and a Continue button.
class _TextInputStep extends StatelessWidget {
  const _TextInputStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.busy,
    required this.onContinue,
    this.errorText,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.none,
    this.onSkip,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool busy;
  final VoidCallback onContinue;
  final String? errorText;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 24),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon),
            errorText: errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          onFieldSubmitted: (_) => onContinue(),
        ),
        const SizedBox(height: 24),
        _StepPrimaryButton(
          label: 'Continue',
          icon: const Icon(Icons.arrow_forward, size: 24),
          onPressed: busy ? null : onContinue,
        ),
        if (onSkip != null) ...[
          const SizedBox(height: 12),
          _StepSkipButton(label: 'Skip', onPressed: busy ? null : onSkip),
        ],
      ],
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    super.key,
    required this.requesting,
    required this.onAllow,
    required this.onSkip,
  });

  final bool requesting;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeader(
          title: 'Location Access (Optional)',
          subtitle: 'Allow location access to find nearby airports',
        ),
        const SizedBox(height: 24),
        _StepPrimaryButton(
          label: requesting ? 'Requesting...' : 'Allow Location',
          icon: requesting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 24),
          onPressed: requesting ? null : onAllow,
        ),
        const SizedBox(height: 12),
        _StepSkipButton(
          label: 'Not Now',
          onPressed: requesting ? null : onSkip,
        ),
      ],
    );
  }
}
