import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CPVoiceControlState state(String id) =>
      CPVoiceControlState(identifier: id, titleVariants: ['Listening']);

  test('public models serialize the native voice contract', () {
    final button = CPButton(
      image: 'mic.svg',
      title: 'Microphone',
      onPress: () {},
    );
    final voice = CPVoiceControlTemplate(
      id: 'voice',
      voiceControlStates: [
        CPVoiceControlState(
          identifier: 'listening',
          titleVariants: ['Listening', 'Listen'],
          image: 'listening.svg',
          repeats: true,
          actionButtons: [button],
        ),
      ],
      trailingNavigationBarButtons: [
        CPBarButton(title: 'Cancel', onPress: () {}),
      ],
    );
    final json = voice.toJson();
    expect(json['runtimeType'], 'FCPVoiceControlTemplate');
    expect(json['_elementId'], 'voice');
    final first = (json['voiceControlStates'] as List).single as Map;
    expect(first['runtimeType'], 'FCPVoiceControlState');
    expect(first['identifier'], 'listening');
    expect(first['repeats'], isTrue);
    expect((first['actionButtons'] as List).single['runtimeType'], 'FCPButton');
  });

  test(
    'collections are defensive immutable copies including serialized titles',
    () {
      final titles = ['Listening'];
      final buttons = <CPButton>[];
      final states = [
        CPVoiceControlState(
          identifier: 'a',
          titleVariants: titles,
          actionButtons: buttons,
        ),
      ];
      final bars = <CPBarButton>[];
      final voice = CPVoiceControlTemplate(
        voiceControlStates: states,
        leadingNavigationBarButtons: bars,
      );
      titles.clear();
      buttons.add(CPButton(image: 'mic.png', onPress: () {}));
      states.clear();
      bars.add(CPBarButton(title: 'Cancel', onPress: () {}));
      final first = voice.voiceControlStates.single;
      expect(first.titleVariants, ['Listening']);
      expect(first.actionButtons, isEmpty);
      expect(voice.leadingNavigationBarButtons, isEmpty);
      expect(() => voice.voiceControlStates.clear(), throwsUnsupportedError);
      expect(() => first.titleVariants!.clear(), throwsUnsupportedError);
      (first.toJson()['titleVariants'] as List).clear();
      expect(first.titleVariants, ['Listening']);
    },
  );

  test('rejects empty identifiers and invalid supplied titles or images', () {
    expect(() => state(' '), throwsArgumentError);
    expect(
      () => CPVoiceControlState(identifier: 'a', titleVariants: []),
      throwsArgumentError,
    );
    expect(
      () => CPVoiceControlState(identifier: 'a', titleVariants: [' ']),
      throwsArgumentError,
    );
    expect(
      () => CPVoiceControlState(identifier: 'a', image: ''),
      throwsArgumentError,
    );
    expect(
      () => CPVoiceControlTemplate(id: '', voiceControlStates: [state('a')]),
      throwsArgumentError,
    );
    expect(() => CPButton(image: '', onPress: () {}), throwsArgumentError);
    expect(
      () => CPButton(id: '', image: 'mic.png', onPress: () {}),
      throwsArgumentError,
    );
  });

  test('requires one to five distinct states without silent truncation', () {
    expect(
      () => CPVoiceControlTemplate(voiceControlStates: []),
      throwsArgumentError,
    );
    expect(
      () =>
          CPVoiceControlTemplate(voiceControlStates: [state('a'), state('a')]),
      throwsArgumentError,
    );
    expect(
      () => CPVoiceControlTemplate(
        voiceControlStates: List.generate(6, (i) => state('$i')),
      ),
      throwsArgumentError,
    );
    expect(
      CPVoiceControlTemplate(
        voiceControlStates: List.generate(5, (i) => state('$i')),
      ).voiceControlStates,
      hasLength(5),
    );
  });

  test('preserves action buttons for native platform limit validation', () {
    final buttons = List.generate(
      3,
      (i) => CPButton(id: 'action_$i', image: 'mic.png', onPress: () {}),
    );
    final voice = CPVoiceControlState(
      identifier: 'ready',
      actionButtons: buttons,
    );
    expect(voice.actionButtons, hasLength(3));
    expect(voice.toJson()['actionButtons'], hasLength(3));
  });

  test('rejects ambiguous actions and excess navigation buttons', () {
    final button = CPButton(id: 'same', image: 'mic.png', onPress: () {});
    expect(
      () =>
          CPVoiceControlState(identifier: 'a', actionButtons: [button, button]),
      throwsArgumentError,
    );

    expect(
      () => CPVoiceControlTemplate(
        voiceControlStates: [state('a')],
        leadingNavigationBarButtons: List.generate(
          3,
          (_) => CPBarButton(title: 'Cancel', onPress: () {}),
        ),
      ),
      throwsArgumentError,
    );
  });
}
