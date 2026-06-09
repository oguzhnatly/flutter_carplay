/// An object that stores color data and sometimes opacity.
///
/// Pass RGB channels as byte values from `0` to `255`. Native platforms convert
/// those byte channels internally to the format they need, such as UIKit's
/// normalized `0.0` to `1.0` components.
///
/// [alpha] accepts the existing normalized `0.0` to `1.0` range, and native
/// platforms also tolerate byte-style alpha values from `0` to `255`.
/// iOS 2.0+ | iPadOS 2.0+ | Mac Catalyst 13.1+
class UIColor {
  /// Red channel, authored as a byte value from `0` to `255`.
  final int red;

  /// Green channel, authored as a byte value from `0` to `255`.
  final int green;

  /// Blue channel, authored as a byte value from `0` to `255`.
  final int blue;

  /// Opacity. Prefer `0.0` to `1.0`; native platforms also accept `0` to `255`.
  final double alpha;

  /// Creates [UIColor].
  ///
  /// RGB values outside `0` to `255` are clamped when serialized.
  const UIColor({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'red': _clampByte(red),
      'green': _clampByte(green),
      'blue': _clampByte(blue),
      'alpha': alpha,
    };
  }

  static int _clampByte(int value) => value.clamp(0, 255).toInt();
}
