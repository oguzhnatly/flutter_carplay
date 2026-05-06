import 'package:uuid/uuid.dart';

/// A single cell in an [AAGridTemplate].
///
/// Each button shows a [titleVariants] label and an optional [image].
/// The first element of [titleVariants] is used as the primary title on
/// Android Auto (Car App Library shows the most appropriate variant
/// according to available space).
class AAGridButton {
  /// Unique id of the object.
  final String _elementId;

  /// Label variants displayed beneath the cell image. Must not be empty.
  final List<String> titleVariants;

  /// Image displayed inside the grid cell. Supports three formats:
  /// - **Asset** (pubspec.yaml): `'images/logo.png'`
  /// - **Local file**: `'file:///path/to/image.png'`
  /// - **Network URL**: `'https://example.com/image.png'`
  ///
  /// Falls back to a default icon when null or when the load fails.
  final String? image;

  /// Text displayed as the loading screen title while [onPress] is executing
  /// (until [complete] is called). When null, no title is shown.
  final String? loadingMessage;

  /// Maximum time in seconds the loading screen stays visible waiting for
  /// [onPress] to call [complete]. When null, no safety timeout is scheduled
  /// and the loading persists until [complete] is called. Values below 1 are
  /// ignored.
  final int? onPressTimeout;

  /// Callback fired when the user taps this button.
  ///
  /// - `complete` must be called after processing to dismiss the loading screen
  ///   and rebuild the template — identical to [AAListItem] behaviour.
  /// - `self` is a reference to the tapped button itself.
  final Future<void> Function(Function() complete, AAGridButton self)? onPress;

  AAGridButton({
    required this.titleVariants,
    this.image,
    this.loadingMessage,
    this.onPressTimeout,
    this.onPress,
  })  : assert(titleVariants.isNotEmpty, 'titleVariants must not be empty'),
        _elementId = const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'titleVariants': titleVariants,
        'image': image,
        'loadingMessage': loadingMessage,
        'onPressTimeout': onPressTimeout,
        'onPress': onPress != null,
      };
}
