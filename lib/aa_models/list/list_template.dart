import 'package:uuid/uuid.dart';

import '../template.dart';
import 'list_section.dart';

class AAListTemplate implements AATemplate {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final List<AAListSection> sections;

  AAListTemplate({
    required this.title,
    required this.sections,
  }) : _elementId = const Uuid().v4();

  @override
  String get uniqueId => _elementId;

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'sections':
            sections.map((AAListSection section) => section.toJson()).toList(),
      };
}
