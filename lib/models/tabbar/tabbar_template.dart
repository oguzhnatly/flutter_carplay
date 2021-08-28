import 'package:flutter_carplay/models/list/list_template.dart';
import 'package:uuid/uuid.dart';

/// A template object that contains a collection of [CPListTemplate] templates,
/// each of which occupies one tab in the tab bar.
class CPTabBarTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title that describes the content of the tab.
  ///
  /// CarPlay only displays the title when the template is a root-template of a tab
  /// bar, otherwise setting this property has no effect.
  final String? title;

  /// The templates to show as tabs.
  final List<CPListTemplate> templates;

  /// When creating a [CPTabBarTemplate], provide an array of templates for the tab bar to display.
  /// CarPlay treats the array’s templates as root templates, each with its own
  /// navigation hierarchy. When a tab bar template is the rootTemplate of your
  /// app’s interface controller and you use the controller to add and remove templates,
  /// CarPlay applies those changes to the selected tab’s navigation hierarchy.
  ///
  /// [!] You can’t add a tab bar template to an existing navigation hierarchy,
  /// or present one modally.
  CPTabBarTemplate({
    this.title,
    required this.templates,
  });

  Map<String, dynamic> toJson() => {
        "_elementId": _elementId,
        "title": title,
        "templates": templates.map((e) => e.toJson()).toList(),
      };

  String get uniqueId {
    return _elementId;
  }
}
