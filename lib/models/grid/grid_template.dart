import 'package:uuid/uuid.dart';

import '../../helpers/carplay_helper.dart';
import '../template.dart';
import 'grid_button.dart';

/// A template object that displays and manages a grid of items.
class CPGridTemplate extends CPTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title will be shown in the navigation bar.
  final String? title;

  /// The array of grid buttons as [CPGridButton] displayed on the template.
  final List<CPGridButton> buttons;

  /// Creates [CPGridTemplate] in order to display a grid of items as buttons.
  /// When creating the grid template, provide an array of [CPGridButton] objects.
  /// Each button must contain a title that is shown in the grid template's navigation bar.
  CPGridTemplate({this.title, this.buttons = const []});

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'buttons': buttons.map((e) => e.toJson()).toList(),
      };

  @override
  String get uniqueId {
    return _elementId;
  }

  @override
  bool hasSameValues(CPTemplate other) {
    if (runtimeType != other.runtimeType) return false;
    other as CPGridTemplate;

    return title == other.title &&
        FlutterCarplayHelper().compareLists(buttons, other.buttons, (a, b) => a.hasSameValues(b));
  }
}
