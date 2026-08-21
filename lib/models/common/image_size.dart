/// How large an icon should be drawn inside the slot CarPlay reserves for it.
///
/// The value is a *fraction* of that slot rather than an absolute point size,
/// because the reserved slot differs per car and per app category — CarPlay
/// exposes it at runtime as `CPListItem.maximumImageSize` and friends. A
/// fraction stays correct across head units and can never overflow the slot.
///
/// The artwork is centred on a transparent canvas of exactly the reserved size,
/// so the fraction controls how much visual weight the glyph carries. Roughly
/// 0.7 ([AutoImageSize.medium]) matches the internal padding that SF Symbols
/// ship with, which is why untouched edge-to-edge artwork reads as oversized
/// next to native CarPlay icons.
///
/// Set a default for every icon via `FlutterCarplay.iconSize`, or override it
/// per image:
///
/// ```dart
/// FlutterCarplay.iconSize = const AutoImageSize.small();
///
/// CPListItem(
///   text: 'Navigation',
///   image: 'images/nav.svg',
///   imageSize: const AutoImageSize.large(),
/// );
/// ```
class AutoImageSize {
  /// Fraction of the reserved slot the artwork occupies.
  ///
  /// Clamped natively to `0.05 .. 1.0`.
  final double fraction;

  /// A custom fraction of the reserved slot, from `0.05` to `1.0`.
  const AutoImageSize.fraction(this.fraction);

  /// Half the reserved slot. Reads as a small, clearly inset glyph.
  const AutoImageSize.small() : fraction = 0.5;

  /// The default. Approximates the padding built into SF Symbols, so icons sit
  /// visually alongside native CarPlay artwork.
  const AutoImageSize.medium() : fraction = 0.7;

  /// Fills most of the reserved slot while keeping a small margin.
  const AutoImageSize.large() : fraction = 0.85;

  /// Fills the reserved slot edge to edge. Appropriate for artwork that is
  /// meant to read as a tile or photo rather than as an icon.
  const AutoImageSize.max() : fraction = 1.0;

  Map<String, dynamic> toJson() => {'fraction': fraction};

  @override
  bool operator ==(Object other) =>
      other is AutoImageSize && other.fraction == fraction;

  @override
  int get hashCode => fraction.hashCode;

  @override
  String toString() => 'AutoImageSize(fraction: $fraction)';
}
