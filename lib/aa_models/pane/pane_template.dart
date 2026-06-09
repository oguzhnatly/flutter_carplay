import 'package:flutter_carplay/models/common/image_tint.dart';
import 'package:uuid/uuid.dart';

import '../template.dart';
import 'pane_action.dart';
import 'pane_item.dart';

class AAPaneTemplate implements AATemplate {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final List<AAPaneItem> items;
  final List<AAPaneAction> actions;

  /// Optional image displayed alongside the pane content.
  ///
  /// Supports the same formats as [AAPaneItem.imageUrl], including Flutter
  /// asset SVGs rasterized before the payload is sent to native Android.
  final String? imageUrl;
  final AutoImageTint? imageTint;

  /// Shows Android Auto's loading state instead of rows.
  ///
  /// Android requires pane content to be either loading or non-empty. Native
  /// Android will also use loading automatically when [items] is empty.
  final bool isLoading;

  AAPaneTemplate({
    required this.title,
    required this.items,
    this.actions = const [],
    this.imageUrl,
    this.imageTint,
    this.isLoading = false,
    String? id,
  }) : _elementId = id ?? const Uuid().v4();

  @override
  String get uniqueId => _elementId;

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'items': items.map((AAPaneItem item) => item.toJson()).toList(),
        'actions':
            actions.map((AAPaneAction action) => action.toJson()).toList(),
        'imageUrl': imageUrl,
        'imageTint': imageTint?.toJson(),
        'isLoading': isLoading,
      };
}
