import 'package:uuid/uuid.dart';

/// A trip preview text configuration object.
class CPTripPreviewTextConfiguration {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The title of the start button.
  final String? startButtonTitle;

  /// The title of the additional routes button.
  final String? additionalRoutesButtonTitle;

  /// The title of the overview button.
  final String? overviewButtonTitle;

  CPTripPreviewTextConfiguration({
    this.startButtonTitle,
    this.additionalRoutesButtonTitle,
    this.overviewButtonTitle,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'startButtonTitle': startButtonTitle,
        'additionalRoutesButtonTitle': additionalRoutesButtonTitle,
        'overviewButtonTitle': overviewButtonTitle,
      };

  String get uniqueId {
    return _elementId;
  }
}
