import 'package:uuid/uuid.dart';

class AAToggle {
  bool isChecked;
  final bool? isEnabled;
  final Function(bool checked, AAListItem self)? onCheckedChange;

  AAToggle({
    this.isChecked = false,
    this.isEnabled,
    this.onCheckedChange,
  });

  Map<String, dynamic> toJson() => {
        'isChecked': isChecked,
        'isEnabled': isEnabled,
        'onCheckedChange': onCheckedChange != null ? true : false,
      };
}

class AAListItem {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final bool? isBrowsable;
  final AAToggle? toggle;
  final Function(Function() complete, AAListItem self)? onPress;

  AAListItem({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.isBrowsable,
    this.toggle,
    this.onPress,
  })  : assert(
          isBrowsable != true || toggle == null,
          'A browsable row must not have a toggle set.',
        ),
        assert(
          isBrowsable != true || onPress != null,
          'A browsable row must have an onClickListener set.',
        ),
        assert(
          toggle == null || onPress == null,
          'If a row contains a toggle, it must not have an onClickListener set.',
        ),
        _elementId = const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'isBrowsable': isBrowsable,
        'toggle': toggle?.toJson(),
        'onPress': onPress != null ? true : false,
      };
}
