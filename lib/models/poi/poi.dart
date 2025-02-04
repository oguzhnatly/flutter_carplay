import 'package:uuid/uuid.dart';

import '../button/text_button.dart';

/// A section object of list items that appear in a list template.
class CPPointOfInterest {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// The latitude of the point of interest.
  double latitude = 0.0;

  /// The longitude of the point of interest.
  double longitude = 0.0;

  /// A subtitle will be shown in the navigation bar.
  String? subtitle;

  /// A summary will be shown in the navigation bar.
  String? summary;

  /// A title will be shown in the navigation bar.
  String title = '';

  /// A detail title will be shown in the navigation bar.
  String? detailTitle;

  /// A detail subtitle will be shown in the navigation bar.
  String? detailSubtitle;

  /// A detail summary will be shown in the navigation bar.
  String? detailSummary;

  /// An image will be shown in the navigation bar.
  String? image;

  /// A primary button will be shown in the navigation bar.
  final CPTextButton? primaryButton;

  /// A secondary button will be shown in the navigation bar.
  final CPTextButton? secondaryButton;

  /// Creates [CPPointOfInterest]
  CPPointOfInterest({
    required this.latitude,
    required this.longitude,
    required this.title,
    this.detailTitle,
    this.subtitle,
    this.detailSubtitle,
    this.image,
    this.summary,
    this.detailSummary,
    this.primaryButton,
    this.secondaryButton,
  });

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'latitude': latitude,
        'longitude': longitude,
        'title': title,
        'subtitle': subtitle,
        'summary': summary,
        'detailTitle': detailTitle,
        'detailSubtitle': detailSubtitle,
        'detailSummary': detailSummary,
        'image': image,
        'primaryButton': primaryButton?.toJson(),
        'secondaryButton': secondaryButton?.toJson(),
      };

  String get uniqueId {
    return _elementId;
  }

  bool hasSameValues(CPPointOfInterest other) {
    return latitude == other.latitude &&
        longitude == other.longitude &&
        title == other.title &&
        subtitle == other.subtitle &&
        summary == other.summary &&
        detailTitle == other.detailTitle &&
        detailSubtitle == other.detailSubtitle &&
        detailSummary == other.detailSummary &&
        image == other.image &&
        _compareButton(primaryButton, other.primaryButton) &&
        _compareButton(secondaryButton, other.secondaryButton);
  }

  bool _compareButton(CPTextButton? button, CPTextButton? otherButton) {
    if (otherButton == null && button == null) return true;
    if (otherButton == null || button == null) return false;

    return otherButton.hasSameValues(button);
  }
}
