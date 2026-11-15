import 'package:flutter/material.dart';

import '../models/crew.dart';

class AppTheme {
  AppTheme._();

  static const seedColor = Color(0xFF1565C0);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      extensions: [
        if (brightness == Brightness.light) AppColors.light else AppColors.dark,
      ],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// App-specific semantic colors that [ColorScheme] doesn't cover.
///
/// Access with `Theme.of(context).appColors` (or `context.appColors`).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.overlay,
    required this.onOverlay,
    required this.crewRoles,
    required this.avatar,
    required this.onAvatar,
  });

  /// Positive state (GPS fix, connected account, ...).
  final Color success;

  /// Attention / secondary accent.
  final Color warning;

  /// Neutral informational accent.
  final Color info;

  /// Dark scrim drawn on top of maps and imagery. Same in both themes,
  /// because maps don't follow the app brightness.
  final Color overlay;

  /// Foreground on [overlay] (text, icons, map marker borders).
  final Color onOverlay;

  /// Badge background per crew role. Foreground is [onOverlay].
  final Map<CrewRole, Color> crewRoles;

  /// Neutral grey background for people without a profile picture.
  final Color avatar;

  /// Initial letter drawn on [avatar].
  final Color onAvatar;

  Color crewRole(CrewRole role) => crewRoles[role] ?? info;

  static const _crewRoles = {
    CrewRole.pic: Color(0xFF1565C0),
    CrewRole.picus: Color(0xFFE65100),
    CrewRole.sic: Color(0xFF1976D2),
    CrewRole.dual: Color(0xFF2E7D32),
    CrewRole.spic: Color(0xFF388E3C),
    CrewRole.ins: Color(0xFFD32F2F),
    CrewRole.exm: Color(0xFFE53935),
    CrewRole.p3: Color(0xFF42A5F5),
    CrewRole.sp: Color(0xFF00897B),
    CrewRole.att: Color(0xFF757575),
    CrewRole.oth: Color(0xFF757575),
  };

  static const light = AppColors(
    success: Color(0xFF2E7D32),
    warning: Color(0xFFEF6C00),
    info: Color(0xFF1976D2),
    overlay: Colors.black,
    onOverlay: Colors.white,
    crewRoles: _crewRoles,
    avatar: Color(0xFF9E9E9E),
    onAvatar: Colors.white,
  );

  static const dark = AppColors(
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    info: Color(0xFF64B5F6),
    overlay: Colors.black,
    onOverlay: Colors.white,
    crewRoles: _crewRoles,
    avatar: Color(0xFF616161),
    onAvatar: Colors.white,
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? overlay,
    Color? onOverlay,
    Map<CrewRole, Color>? crewRoles,
    Color? avatar,
    Color? onAvatar,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      overlay: overlay ?? this.overlay,
      onOverlay: onOverlay ?? this.onOverlay,
      crewRoles: crewRoles ?? this.crewRoles,
      avatar: avatar ?? this.avatar,
      onAvatar: onAvatar ?? this.onAvatar,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      onOverlay: Color.lerp(onOverlay, other.onOverlay, t)!,
      crewRoles: {
        for (final role in CrewRole.values)
          role: Color.lerp(crewRole(role), other.crewRole(role), t)!,
      },
      avatar: Color.lerp(avatar, other.avatar, t)!,
      onAvatar: Color.lerp(onAvatar, other.onAvatar, t)!,
    );
  }
}

extension AppColorsTheme on ThemeData {
  AppColors get appColors => extension<AppColors>() ?? AppColors.light;
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).appColors;
}
