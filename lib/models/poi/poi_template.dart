import 'package:uuid/uuid.dart';
import 'poi.dart';

/// A template object that displays point of interest.
class CPPointOfInterestTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title will be shown in the navigation bar.
  final String title;
  final List<CPPointOfInterest> poi;

  /// Creates [CPPointOfInterestTemplate]
  CPPointOfInterestTemplate({
    required this.title,
    required this.poi
  });

  Map<String, dynamic> toJson() => {
    "_elementId": _elementId,
    "title": title,
    "poi": poi.map((e) => e.toJson()).toList(),
  };

  String get uniqueId {
    return _elementId;
  }
}
