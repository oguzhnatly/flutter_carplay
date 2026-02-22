import 'package:uuid/uuid.dart';

import '../button/text_button.dart';

/// A section object of list items that appear in a list template.
/// https://developer.apple.com/documentation/carplay/cppointofinterest
/// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
class CPPointOfInterest {
  /// Unique id of the object.
  final String _elementId;

  /// The latitude of the geographical coordinate.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  double latitude;

  /// The longitude of the geographical coordinate.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  double longitude;

  /// The title that the picker displays for the item.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  String title;

  /// The subtitle that the picker displays for the item.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  String? subtitle;

  /// A brief summary that the picker displays for the item.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  String? summary;

  /// The detail card’s title.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  String? detailTitle;

  /// The detail card’s subtitle.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  String? detailSubtitle;

  /// A brief summary that the detail card displays.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  String? detailSummary;

  /// A custom image that the map annotation displays.
  /// Supports three formats:
  /// - **Asset path**: `images/marker.png` (from pubspec.yaml assets)
  /// - **File path**: `file:///path/to/image.png` (local file on device)
  /// - **Network URL**: `https://example.com/image.png` (remote image)
  String? image;

  /// The detail card’s primary action button.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  CPTextButton? primaryButton;

  /// The detail card’s secondary action button.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  CPTextButton? secondaryButton;

  /// Creates [CPPointOfInterest]
  CPPointOfInterest({
    required this.latitude,
    required this.longitude,
    required this.title,
    this.subtitle,
    this.summary,
    this.detailTitle,
    this.detailSubtitle,
    this.detailSummary,
    this.image,
    this.primaryButton,
    this.secondaryButton,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

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
}
