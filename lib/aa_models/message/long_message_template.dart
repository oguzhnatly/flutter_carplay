import 'package:flutter_carplay/controllers/android_auto_controller.dart';
import 'package:uuid/uuid.dart';

import '../../constants/private_constants.dart';
import '../template.dart';

class AALongMessageTemplate implements AATemplate {
  /// Unique id of the object.
  final String _elementId;

  String title;
  String message;

  /// Creates a long message template for Android Auto.
  ///
  /// [message] must not be empty because Android Auto requires a non-empty
  /// message when building the native template.
  AALongMessageTemplate({
    required this.title,
    required this.message,
    String? id,
  }) : _elementId = id ?? const Uuid().v4() {
    _validateMessage(message);
  }

  @override
  String get uniqueId => _elementId;

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'message': message,
      };

  /// Updates the template content on Android Auto.
  ///
  /// Android Auto templates are immutable. This method asks the native side to
  /// rebuild the long message template and invalidate the current screen.
  ///
  /// [message] must not be empty.
  Future<void> update({String? title, String? message}) async {
    final nextTitle = title ?? this.title;
    final nextMessage = message ?? this.message;
    _validateMessage(nextMessage);

    final bool? isCompleted =
        await FlutterAndroidAutoController.flutterToNativeModuleStatic(
      FAAChannelTypes.updateLongMessageTemplate,
      {'elementId': _elementId, 'title': nextTitle, 'message': nextMessage},
    );

    if (isCompleted == true) {
      updateTemplate(title: nextTitle, message: nextMessage);
    }
  }

  Future<void> setTitle(String title) {
    return update(title: title);
  }

  Future<void> setMessage(String message) {
    return update(message: message);
  }

  void updateTemplate({required String title, required String message}) {
    _validateMessage(message);
    this.title = title;
    this.message = message;
  }

  static void _validateMessage(String message) {
    if (message.isEmpty) {
      throw ArgumentError.value(message, 'message', 'Message cannot be empty');
    }
  }
}
