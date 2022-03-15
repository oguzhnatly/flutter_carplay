import 'package:uuid/uuid.dart';
import '../button/text_button.dart';
/// A section object of list items that appear in a list template.
class CPPointOfInterest {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// Header text of the section.
  double latitude = 0.0;
  double longitude = 0.0;
  String title = "";
  String? subtitle;
  String? summary;
  String? detailTitle;
  String? detailSubtitle;
  String? detailSummary;
  String? image;

  final CPTextButton? primaryButton;
  final CPTextButton? secondaryButton;


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
    this.secondaryButton
  });

  Map<String, dynamic> toJson() => {
    "_elementId": _elementId,
    "latitude":latitude,
    "longitude":longitude,
    "title":title,
    "subtitle":subtitle,
    "summary":summary,
    "detailTitle":detailTitle,
    "detailSubtitle":detailSubtitle,
    "detailSummary":detailSummary,
    "image":image,
    "primaryButton":primaryButton?.toJson(),
    "secondaryButton":secondaryButton?.toJson()

  };

  String get uniqueId {
    return _elementId;
  }
}
