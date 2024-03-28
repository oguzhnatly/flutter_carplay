import 'package:uuid/uuid.dart';

import 'map_item.dart';
import 'route_choice.dart';

/// CPTrip represents an origin and destination with route choices.
class CPTrip {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// Origin of the trip
  final MKMapItem origin;

  /// Destination of the trip
  final MKMapItem destination;

  /// Route choices
  final List<CPRouteChoice> routeChoices;

  CPTrip({
    required this.origin,
    required this.destination,
    this.routeChoices = const [],
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'routeChoices': routeChoices.map((e) => e.toJson()).toList(),
      };

  String get uniqueId {
    return _elementId;
  }
}
