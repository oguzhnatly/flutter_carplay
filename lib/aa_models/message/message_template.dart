import 'package:flutter_carplay/controllers/android_auto_controller.dart';
import 'package:uuid/uuid.dart';

import '../../constants/private_constants.dart';
import '../template.dart';

class AAMessageTemplate implements AATemplate {
  /// Unique id of the object.
  final String _elementId;

  String title;
  String message;

  AAMessageTemplate({required this.title, required this.message, String? id})
    : _elementId = id ?? const Uuid().v4();

  @override
  String get uniqueId => _elementId;

  @override
  Map<String, dynamic> toJson() => {
    '_elementId': _elementId,
    'title': title,
    'message': message,
  };

  Future<void> update({String? title, String? message}) async {
    final nextTitle = title ?? this.title;
    final nextMessage = message ?? this.message;
    final bool? isCompleted =
        await FlutterAndroidAutoController.flutterToNativeModuleStatic(
          FAAChannelTypes.updateMessageTemplate,
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
    this.title = title;
    this.message = message;
  }
}
