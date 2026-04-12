/// An object that stores color data and sometimes opacity.
/// iOS 2.0+ | iPadOS 2.0+ | Mac Catalyst 13.1+
class UIColor {
  final int red;
  final int green;
  final int blue;
  final double alpha;

  /// Creates [UIColor]
  const UIColor({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'red': red,
      'green': green,
      'blue': blue,
      'alpha': alpha,
    };
  }
}
