import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/airport_providers.dart';
import '../providers/carto_provider.dart';
import '../providers/user_provider.dart';
import '../services/airport_service.dart';
import '../widgets/sync_progress_indicator.dart';

class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({super.key, required this.onPermissionGranted});
  final VoidCallback onPermissionGranted;

  @override
  ConsumerState<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends ConsumerState<IntroPage>
    with SingleTickerProviderStateMixin {
  static const _logoAsset = AssetImage('assets/images/zenith_logo.png');

  /// Drives the hero's fade-in on first show.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _entranceCurve = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutCubic,
  );
  bool _entranceScheduled = false;

  bool _requesting = false;
  bool _savingKey = false;
  bool _finishing = false;
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
    _entrance.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      // Both are deferred until the hero has settled: opening the keyboard
      // resizes the page every frame (and collapses the hero), and the
      // airport sync does network work on this isolate. Either one during
      // the entrance makes it stutter.
      if (_step == 0) _nicknameFocus.requestFocus();
      // Start downloading airport data now, so it's usually done by the
      // time the user reaches the last step.
      ref.read(airportLoadProvider);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceScheduled) return;
    _entranceScheduled = true;
    // Start the entrance once the logo is decoded and the (expensive) first
    // frame of the page is out, so the animation doesn't lose its first
    // frames or pop the logo in halfway through.
    precacheImage(_logoAsset, context).whenComplete(() {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entrance.forward();
      });
      WidgetsBinding.instance.scheduleFrame();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
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
  }

  Future<void> _onLocationContinue() => _requestPermission();

  void _skipLocation() => _goToAirportDataStep();

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);

    // Whatever the answer, setup continues.
    await Geolocator.requestPermission();

    if (!mounted) return;
    setState(() => _requesting = false);
    _goToAirportDataStep();
  }

  /// Goes to the last step: the airport download progress, which becomes
  /// an "all set" confirmation once the data is in, so the user always sees
  /// 5/5 and enters the app with a tap.
  void _goToAirportDataStep() => setState(() => _step = 4);

  /// Marks onboarding as complete and enters the app. Any running airport
  /// download keeps going in the background.
  Future<void> _finishSetup() async {
    if (_finishing) return;
    _finishing = true;
    await ref.read(onboardingCompleteProvider.notifier).setComplete();
    widget.onPermissionGranted();
  }

  static const _stepCount = 5;

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
              'Enter a CARTO API key for vector maps, or skip to use '
              'OpenStreetMap.',
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
      case 3:
        return _LocationStep(
          key: const ValueKey('location'),
          requesting: _requesting,
          onAllow: _onLocationContinue,
          onSkip: _skipLocation,
        );
      default:
        final progress = ref.watch(airportLoadProvider);
        if (progress.phase == SyncPhase.done) {
          return _AllSetStep(
            key: const ValueKey('allSet'),
            nickname: _nicknameController.text.trim(),
            onContinue: _finishSetup,
          );
        }
        return _AirportDataStep(
          key: const ValueKey('airportData'),
          progress: progress,
          onContinue: _finishSetup,
          onRetry: () => ref.read(airportLoadProvider.notifier).refresh(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The available height shrinks when the keyboard is open (the
            // Scaffold resizes), so the hero collapses to leave room for
            // the form on short screens.
            final compact = constraints.maxHeight < 620;
            final narrow = constraints.maxWidth < 360;
            final horizontalPadding = narrow ? 20.0 : 28.0;

            // Scrollable so nothing ends up outside the screen (and
            // therefore untappable) on small phones; the min height keeps
            // the content spread out when there is room for it.
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: compact ? 16 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 480,
                    minHeight: constraints.maxHeight - (compact ? 32 : 64),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _IntroHero(
                        compact: compact,
                        entrance: _entranceCurve,
                        logo: _logoAsset,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: compact ? 20 : 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StepProgress(step: _step, count: _stepCount),
                            SizedBox(height: compact ? 16 : 24),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.topCenter,
                                children: [...previous, ?current],
                              ),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.08, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _currentStep(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Zenith logo, welcome title and tagline. Fades in on first show and
/// shrinks when vertical space is tight (e.g. keyboard open).
class _IntroHero extends StatelessWidget {
  const _IntroHero({
    required this.compact,
    required this.entrance,
    required this.logo,
  });

  final bool compact;
  final Animation<double> entrance;
  final ImageProvider logo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const duration = Duration(milliseconds: 250);

    // Transitions instead of a rebuilding Opacity/Transform: they only
    // update layer properties each frame, and the RepaintBoundary keeps the
    // hero (color-filtered logo, text) from being repainted while it moves.
    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(entrance),
        child: RepaintBoundary(
          child: Column(
            children: [
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: compact ? 72 : 112,
                height: compact ? 72 : 112,
                // The launcher foreground is a white silhouette: recolor it so it
                // reads on both light and dark backgrounds. A color matrix keeps
                // the alpha untouched (a srcIn blend leaves a faint frame around
                // the image bounds on Impeller).
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix([
                    0, 0, 0, 0, cs.primary.r * 255, //
                    0, 0, 0, 0, cs.primary.g * 255, //
                    0, 0, 0, 0, cs.primary.b * 255, //
                    0, 0, 0, 1, 0, //
                  ]),
                  child: Image(image: logo, semanticLabel: 'Zenith logo'),
                ),
              ),
              SizedBox(height: compact ? 12 : 24),
              // Scale down instead of wrapping on narrow screens.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  style:
                      (compact
                              ? theme.textTheme.headlineMedium
                              : theme.textTheme.displaySmall)!
                          .copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                            letterSpacing: -0.5,
                          ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Welcome to '),
                        TextSpan(
                          text: 'Zenith',
                          style: TextStyle(color: cs.primary),
                        ),
                        const TextSpan(text: '!'),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Your free & open-source personal logbook',
                  maxLines: 1,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented progress bar for the onboarding steps.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.count});

  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      label: 'Step ${step + 1} of $count',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == step ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i <= step ? cs.primary : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Text(
              'Step ${step + 1} of $count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Title + subtitle shown at the top of each onboarding step.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

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
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

/// Last onboarding step: waits for the OurAirports download to finish.
class _AirportDataStep extends StatelessWidget {
  const _AirportDataStep({
    super.key,
    required this.progress,
    required this.onContinue,
    required this.onRetry,
  });

  final SyncProgress progress;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isError = progress.phase == SyncPhase.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          title: isError ? 'Download Failed' : 'Downloading Airport Data',
          subtitle: isError
              ? 'Check your connection and try again, or continue and '
                    'retry later from the Airports tab'
              : 'Fetching airports, runways and frequencies from OurAirports',
        ),
        const SizedBox(height: 24),
        SyncProgressIndicator(progress: progress),
        const SizedBox(height: 24),
        if (isError) ...[
          _StepPrimaryButton(
            label: 'Retry',
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: onRetry,
          ),
          const SizedBox(height: 12),
        ],
        _StepSkipButton(
          label: isError ? 'Continue Without Data' : 'Continue in Background',
          onPressed: onContinue,
        ),
      ],
    );
  }
}

/// Last onboarding step when the airport data is already downloaded.
class _AllSetStep extends StatelessWidget {
  const _AllSetStep({
    super.key,
    required this.nickname,
    required this.onContinue,
  });

  final String nickname;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_outline, size: 48, color: cs.primary),
        const SizedBox(height: 16),
        _StepHeader(
          title: nickname.isEmpty
              ? "You're all set!"
              : "You're all set, $nickname!",
        ),
        const SizedBox(height: 24),
        _StepPrimaryButton(
          label: 'Get Started',
          icon: const Icon(Icons.arrow_forward, size: 24),
          onPressed: onContinue,
        ),
      ],
    );
  }
}
