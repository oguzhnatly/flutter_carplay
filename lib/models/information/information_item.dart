import 'package:uuid/uuid.dart';

/// A information item  object displayed on a information template.
class CPInformationItem {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  final String? title;
  final String? detail;

  CPInformationItem({
    this.title,
    this.detail
  });

  Map<String, dynamic> toJson() => {
    "_elementId": _elementId,
    "title": title,
    "detail": detail,
  };

  String get uniqueId {
    return _elementId;
  }
}
