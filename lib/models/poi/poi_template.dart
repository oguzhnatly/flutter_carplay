import 'package:uuid/uuid.dart';

import '../template.dart';
import 'poi.dart';

/// A template that displays a map with selectable points of interest.
/// https://developer.apple.com/documentation/carplay/cppointofinteresttemplate
/// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
class CPPointOfInterestTemplate extends CPTemplate {
  /// Unique id of the object.
  final String _elementId;

  /// The scrollable picker’s title.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final String title;

  /// The points of interest the template displays on the map and in the scrollable picker.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final List<CPPointOfInterest> poi;

  /// Creates [CPPointOfInterestTemplate]
  CPPointOfInterestTemplate({
    required this.title,
    required this.poi,
    super.tabTitle,
    super.showsTabBadge = false,
    super.systemIcon,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'poi': poi.map((e) => e.toJson()).toList(),
        'tabTitle': tabTitle,
        'showsTabBadge': showsTabBadge,
        'systemIcon': systemIcon,
        'runtimeType': 'FCPPointOfInterestTemplate',
      };

  @override
  String get uniqueId {
    return _elementId;
  }
}
