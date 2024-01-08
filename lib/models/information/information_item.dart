import 'package:uuid/uuid.dart';

/// A information item  object displayed on a information template.
class CPInformationItem {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title will be shown in the navigation bar.
  final String? title;

  /// A detail will be shown in the navigation bar.
  final String? detail;

  /// Creates [CPInformationItem]
  CPInformationItem({this.title, this.detail});

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'detail': detail,
      };

  String get uniqueId {
    return _elementId;
  }
}
