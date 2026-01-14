import 'package:flutter_carplay/models/action_sheet/action_sheet_template.dart';
import 'package:flutter_carplay/models/alert/alert_template.dart';
import 'package:flutter_carplay/models/grid/grid_template.dart';
import 'package:flutter_carplay/models/information/information_template.dart';
import 'package:flutter_carplay/models/list/list_template.dart';
import 'package:flutter_carplay/models/poi/poi_template.dart';
import 'package:uuid/uuid.dart';

import '../template.dart';

/// A template object that contains a collection of [CPTemplate] templates,
/// each of which occupies one tab in the tab bar.
/// Supported template types: [CPListTemplate], [CPPointOfInterestTemplate],
/// [CPGridTemplate], [CPInformationTemplate], [CPActionSheetTemplate], [CPAlertTemplate]
class CPTabBarTemplate implements CPTemplate {
  /// Unique id of the object.
  final String _elementId = const Uuid().v4();

  /// A title that describes the content of the tab.
  ///
  /// CarPlay only displays the title when the template is a root-template of a tab
  /// bar, otherwise setting this property has no effect.
  final String? title;

  /// The templates to show as tabs.
  /// Supported types: [CPListTemplate], [CPPointOfInterestTemplate],
  /// [CPGridTemplate], [CPInformationTemplate]
  final List<CPTemplate> templates;

  /// When creating a [CPTabBarTemplate], provide an array of templates for the tab bar to display.
  /// CarPlay treats the array’s templates as root templates, each with its own
  /// navigation hierarchy. When a tab bar template is the rootTemplate of your
  /// app’s interface controller and you use the controller to add and remove templates,
  /// CarPlay applies those changes to the selected tab’s navigation hierarchy.
  ///
  /// [!] You can’t add a tab bar template to an existing navigation hierarchy,
  /// or present one modally.
  CPTabBarTemplate({this.title, required this.templates});

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'templates': templates.map((e) => _templateToJson(e)).toList(),
      };

  /// Converts a template to JSON with its runtime type identifier.
  Map<String, dynamic> _templateToJson(CPTemplate template) {
    final json = template.toJson();
    if (template is CPListTemplate) {
      json['runtimeType'] = 'FCPListTemplate';
    } else if (template is CPPointOfInterestTemplate) {
      json['runtimeType'] = 'FCPPointOfInterestTemplate';
    } else if (template is CPGridTemplate) {
      json['runtimeType'] = 'FCPGridTemplate';
    } else if (template is CPInformationTemplate) {
      json['runtimeType'] = 'FCPInformationTemplate';
    }
    return json;
  }

  @override
  String get uniqueId {
    return _elementId;
  }

  void updateTemplates(List<CPTemplate> newTemplates) {
    final copy = List<CPTemplate>.from(newTemplates);
    templates
      ..clear()
      ..addAll(copy);
  }
}
