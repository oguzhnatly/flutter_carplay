import 'package:uuid/uuid.dart';

/// A route choice object is used in [CPTrip].
class CPRouteChoice {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// summaryVariants is an array of summary variants for this route choice
  final List<String>? summaryVariants;

  /// selectionSummaryVariants is an array of selection summary variants
  /// for this route choice
  final List<String>? selectionSummaryVariants;

  /// additionalInformationVariants is an array of additional information
  /// variants for this route choice
  final List<String>? additionalInformationVariants;

  CPRouteChoice({
    this.summaryVariants,
    this.selectionSummaryVariants,
    this.additionalInformationVariants,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'summaryVariants': summaryVariants,
        'selectionSummaryVariants': selectionSummaryVariants,
        'additionalInformationVariants': additionalInformationVariants,
      };

  String get uniqueId {
    return _elementId;
  }
}
