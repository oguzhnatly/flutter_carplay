import 'package:uuid/uuid.dart';

/// A map item object used in [CPTrip]
class MKMapItem {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// latitude and longitude
  final double latitude;
  final double longitude;

  /// Location name
  final String? name;

  MKMapItem({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
      };

  String get uniqueId {
    return _elementId;
  }
}
