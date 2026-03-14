import 'package:uuid/uuid.dart';

/// A data object that provides content for an information template.
/// https://developer.apple.com/documentation/carplay/cpinformationitem
/// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
class CPInformationItem {
  /// Unique id of the object.
  final String _elementId;

  /// The text that the template displays as the item’s title.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final String? title;

  /// The text that the template displays below or beside the item’s title.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final String? detail;

  /// Creates [CPInformationItem]
  CPInformationItem({
    this.title,
    this.detail,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'detail': detail,
        'runtimeType': 'FCPInformationItem',
      };

  String get uniqueId {
    return _elementId;
  }
}
