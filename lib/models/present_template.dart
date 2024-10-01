import 'package:flutter/foundation.dart';

import '../flutter_carplay.dart';

/// A template object that represents a base present template.
abstract class CPPresentTemplate extends CPTemplate {
  final bool isDismissible;
  final String? routeName;

  /// Fired when the modal presented to CarPlay. With this callback function, it can be
  /// determined whether an error was encountered while presenting, or if it was successfully opened,
  /// with the [bool] completed data in it.
  ///
  /// If completed is true, the alert successfully presented. If not, you may want to show an error to the user.
  final ValueChanged<bool>? onPresent;

  /// Fired when the modal presented in CarPlay is popped.
  final VoidCallback? onPop;

  CPPresentTemplate({
    this.isDismissible = true,
    this.routeName,
    this.onPresent,
    this.onPop,
  });
}
