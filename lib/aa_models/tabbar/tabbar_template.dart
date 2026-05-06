import 'package:uuid/uuid.dart';

import '../grid/grid_template.dart';
import '../list/list_template.dart';
import '../template.dart';

/// A container template that displays multiple child templates as tabs on
/// Android Auto. Rendered as [TabTemplate] from the Car App Library (API 6+).
///
/// Each child [AATemplate] is shown in its own tab. The tab's label is taken
/// from [AAListTemplate.tabTitle] (falling back to [AAListTemplate.title]).
/// An optional tab icon can be provided via [AAListTemplate.systemIcon]
/// (mapped to a CarIcon built-in) or [AAListTemplate.iconUrl] (loaded async).
///
/// Currently supported child template types: [AAListTemplate].
///
/// Devices that do not support API level 6 will fall back to showing the first
/// tab's content as a plain [ListTemplate].
class AATabBarTemplate implements AATemplate {
  final String _elementId;

  /// The templates shown in each tab (max 5, per Android Auto restrictions).
  final List<AATemplate> tabs;

  AATabBarTemplate({
    required List<AATemplate> tabs,
    String? id,
  })  : tabs = List<AATemplate>.from(tabs),
        _elementId = id ?? const Uuid().v4();

  @override
  String get uniqueId => _elementId;

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'tabs': tabs
            .map((t) => {
                  'elementId': t.uniqueId,
                  'runtimeType': _runtimeTypeOf(t),
                  'template': t.toJson(),
                })
            .toList(),
      };

  /// Updates the tabs list in-place (mirrors CPTabBarTemplate.updateTemplates).
  void updateTabs(List<AATemplate> newTabs) {
    final copy = List<AATemplate>.from(newTabs);
    tabs
      ..clear()
      ..addAll(copy);
  }

  static String _runtimeTypeOf(AATemplate t) {
    if (t is AAListTemplate) return 'FAAListTemplate';
    if (t is AAGridTemplate) return 'FAAGridTemplate';
    return 'FAAUnknown';
  }
}
