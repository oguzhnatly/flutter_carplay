import 'package:uuid/uuid.dart';

import '../../controllers/carplay_controller.dart';
import 'list_image_row_item/list_image_row_item_element.dart';
import 'list_template_item.dart';

/// A List template row that displays a series of images.
/// https://developer.apple.com/documentation/carplay/cplistimagerowitem
/// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
class CPListImageRowItem extends CPListTemplateItem {
  /// Unique id of the object.
  final String _elementId;

  /// The images that appear in the list item’s image row.
  /// iOS 14.0–26.0 | iPadOS 14.0–26.0 | Mac Catalyst 14.0–26.0
  final List<String>? gridImages;

  /// The titles displayed for each image in this image row item.
  /// iOS 14.0–26.0 | iPadOS 14.0–26.0 | Mac Catalyst 14.0–26.0'
  final List<String>? imageTitles;

  /// The array of elements used to draw visible elements.
  /// Can be one of the following types of elements:
  /// - [CPListImageRowItemCardElement]
  /// - [CPListImageRowItemCondensedElement]
  /// - [CPListImageRowItemRowElement]
  /// - [CPListImageRowItemGridElement]
  /// - [CPListImageRowItemImageGridElement]
  /// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
  List<CPListImageRowItemElement>? elements;

  /// A Boolean value indicating whether the elements should be visible in more than a single line.
  /// iOS 26.0+ | iPadOS 26.0+ | Mac Catalyst 26.0+
  final bool allowsMultipleLines;

  /// An optional closure that CarPlay invokes when the user selects the list item.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  Function(Function() complete, CPListImageRowItem self)? onPress;

  /// An optional closure that CarPlay invokes when the user selects an image.
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  Function(Function() complete, CPListImageRowItem self, int? index)?
      onItemPress;

  /// Creates [CPListImageRowItem]
  CPListImageRowItem({
    super.text,
    this.gridImages,
    this.imageTitles,
    this.elements,
    this.allowsMultipleLines = false,
    this.onPress,
    this.onItemPress,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'text': text,
        'gridImages': gridImages,
        'imageTitles': imageTitles,
        'elements': elements?.map((e) => e.toJson()).toList(),
        'allowsMultipleLines': allowsMultipleLines,
        'onPress': onPress != null ? true : false,
        'onItemPress': onItemPress != null ? true : false,
        'runtimeType': 'FCPListImageRowItem',
      };

  void setText(String text) {
    this.text = text;
    FlutterCarPlayController.updateCPListImageRowItem(this);
  }

  void setElements(List<CPListImageRowItemElement> elements) {
    this.elements = elements;
    FlutterCarPlayController.updateCPListImageRowItem(this);
  }

  @override
  String get uniqueId {
    return _elementId;
  }
}
