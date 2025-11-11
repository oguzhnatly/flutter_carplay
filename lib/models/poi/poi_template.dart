import 'package:uuid/uuid.dart';

import '../template.dart';
import 'poi.dart';

/// A template object that displays point of interest.
class CPPointOfInterestTemplate implements CPTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title will be shown in the navigation bar.
  final String title;
  final List<CPPointOfInterest> poi;

  /// Creates [CPPointOfInterestTemplate]
  CPPointOfInterestTemplate({required this.title, required this.poi});

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'poi': poi.map((e) => e.toJson()).toList(),
      };

  @override
  String get uniqueId {
    return _elementId;
  }
}
