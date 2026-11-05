import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('list template serializes the assistant cell configuration', () {
    final template = CPListTemplate(
      sections: [],
      assistantCellConfiguration: const CPAssistantCellConfiguration(
        position: CPAssistantCellPosition.bottom,
        visibility: CPAssistantCellVisibility.whileLimitedUIActive,
        action: CPAssistantCellActionType.startCall,
      ),
    );

    expect(template.toJson()['assistantCellConfiguration'], {
      'position': 'bottom',
      'visibility': 'whileLimitedUIActive',
      'action': 'startCall',
    });
  });

  test('assistant cell defaults to the top and always visible', () {
    const config = CPAssistantCellConfiguration(
      action: CPAssistantCellActionType.playMedia,
    );

    expect(config.toJson(), {
      'position': 'top',
      'visibility': 'always',
      'action': 'playMedia',
    });
  });

  test('list template omits the assistant cell when none is set', () {
    final template = CPListTemplate(sections: []);

    expect(template.toJson()['assistantCellConfiguration'], isNull);
  });
}
