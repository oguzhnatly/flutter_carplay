import 'package:flutter_carplay/models/action_sheet/action_sheet_template.dart';
import 'package:flutter_carplay/models/alert/alert_template.dart';
import 'package:flutter_carplay/models/grid/grid_template.dart';
import 'package:flutter_carplay/models/information/information_template.dart';
import 'package:flutter_carplay/models/list/list_template.dart';
import 'package:flutter_carplay/models/poi/poi_template.dart';
import 'package:uuid/uuid.dart';

import '../template.dart';

/// A container template that displays and manages other templates, presenting them as tabs.
/// Supported template types: [CPListTemplate], [CPPointOfInterestTemplate],
/// [CPGridTemplate], [CPInformationTemplate], [CPActionSheetTemplate], [CPAlertTemplate]
/// https://developer.apple.com/documentation/carplay/cptabbartemplate
/// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
class CPTabBarTemplate extends CPTemplate {
  /// Unique id of the object.
  final String _elementId;

  /// The tab bar’s templates.
  /// Supported types: [CPListTemplate], [CPPointOfInterestTemplate],
  /// [CPGridTemplate], [CPInformationTemplate]
  /// iOS 14.0+ | iPadOS 14.0+ | Mac Catalyst 14.0+
  final List<CPTemplate> templates;

  /// When creating a [CPTabBarTemplate], provide an array of templates for the tab bar to display.
  /// CarPlay treats the array’s templates as root templates, each with its own
  /// navigation hierarchy. When a tab bar template is the rootTemplate of your
  /// app’s interface controller and you use the controller to add and remove templates,
  /// CarPlay applies those changes to the selected tab’s navigation hierarchy.
  ///
  /// [!] You can’t add a tab bar template to an existing navigation hierarchy,
  /// or present one modally.
  CPTabBarTemplate({
    required List<CPTemplate> templates,
    super.tabTitle,
    super.showsTabBadge = false,
    super.systemIcon,
    String? id,
  })  : templates = List<CPTemplate>.from(templates),
        _elementId = id ?? const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'tabTitle': tabTitle,
        'templates': templates.map((e) => e.toJson()).toList(),
        'showsTabBadge': showsTabBadge,
        'systemIcon': systemIcon,
        'runtimeType': 'FCPTabBarTemplate',
      };

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
