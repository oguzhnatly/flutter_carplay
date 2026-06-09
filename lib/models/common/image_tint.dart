import 'ui_color.dart';

/// Host-aware tint options for image glyphs shown in CarPlay and Android Auto.
///
/// Prefer [AutoImageTint.platform] for icons that must remain visible in focused
/// or selected rows. It lets the host choose an appropriate color on Android
/// Auto and uses a high-contrast system color on CarPlay.
///
/// Custom colors use [UIColor] RGB channels authored as byte values from `0` to
/// `255`. Native platforms convert those byte values internally, so callers do
/// not need to account for UIKit's normalized color component range.
class AutoImageTint {
  final AutoImageTintType type;

  /// Light-mode custom color. Only used by [AutoImageTint.custom].
  final UIColor? color;

  /// Dark-mode custom color. Falls back to [color] when omitted.
  final UIColor? darkColor;

  /// Adds contrast protection where the platform does not manage selected-state
  /// icon contrast for us. Currently this is applied by the CarPlay renderer.
  final bool selectedSafe;

  const AutoImageTint._({
    required this.type,
    this.color,
    this.darkColor,
    this.selectedSafe = true,
  });

  /// Uses the host platform's default icon tint.
  const AutoImageTint.platform({bool selectedSafe = true})
      : this._(
          type: AutoImageTintType.platform,
          selectedSafe: selectedSafe,
        );

  /// Uses the host platform's primary tint color.
  const AutoImageTint.primary({bool selectedSafe = true})
      : this._(
          type: AutoImageTintType.primary,
          selectedSafe: selectedSafe,
        );

  /// Uses the host platform's secondary tint color.
  const AutoImageTint.secondary({bool selectedSafe = true})
      : this._(
          type: AutoImageTintType.secondary,
          selectedSafe: selectedSafe,
        );

  /// Uses a platform-standard red tint.
  const AutoImageTint.red({bool selectedSafe = true})
      : this._(
          type: AutoImageTintType.red,
          selectedSafe: selectedSafe,
        );

  /// Uses a platform-standard green tint.
  const AutoImageTint.green({bool selectedSafe = true})
      : this._(
          type: AutoImageTintType.green,
          selectedSafe: selectedSafe,
        );

  /// Uses a platform-standard blue tint.
  const AutoImageTint.blue({bool selectedSafe = true})
      : this._(
          type: AutoImageTintType.blue,
          selectedSafe: selectedSafe,
        );

  /// Uses a platform-standard yellow tint.
  const AutoImageTint.yellow({bool selectedSafe = true})
      : this._(
          type: AutoImageTintType.yellow,
          selectedSafe: selectedSafe,
        );

  /// Uses custom RGB byte colors for light and optional dark mode.
  ///
  /// Pass [color] and [darkColor] as [UIColor] values with RGB channels from
  /// `0` to `255`. If [darkColor] is omitted, [color] is reused in dark mode.
  const AutoImageTint.custom({
    required UIColor color,
    UIColor? darkColor,
    bool selectedSafe = true,
  }) : this._(
          type: AutoImageTintType.custom,
          color: color,
          darkColor: darkColor,
          selectedSafe: selectedSafe,
        );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'color': color?.toJson(),
        'darkColor': darkColor?.toJson(),
        'selectedSafe': selectedSafe,
      };
}

/// Convenience helpers for configuring [AutoImageTint].
extension AutoImageTintDarkColor on AutoImageTint {
  /// Returns a copy of this tint with [darkColor] as its dark-mode custom color.
  ///
  /// [darkColor] is authored with RGB byte channels from `0` to `255`. Native
  /// platforms convert those values internally. For non-custom tint types this
  /// method creates a custom tint, using the provided [darkColor] for both light
  /// and dark mode unless the original tint already had a custom light [color].
  AutoImageTint withDarkColor(UIColor darkColor) {
    return AutoImageTint.custom(
      color: color ?? darkColor,
      darkColor: darkColor,
      selectedSafe: selectedSafe,
    );
  }
}

enum AutoImageTintType {
  platform,
  primary,
  secondary,
  red,
  green,
  blue,
  yellow,
  custom,
}
