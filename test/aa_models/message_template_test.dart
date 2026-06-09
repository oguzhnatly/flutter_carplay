import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AAMessageTemplate', () {
    const channel = MethodChannel('com.oguzhnatly.flutter_android_auto');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('serializes message template', () {
      final template = AAMessageTemplate(
        id: '<AAMessageTemplate>',
        title: 'No saved places',
        message: 'Save places on your phone to access them here.',
      );

      expect(template.uniqueId, '<AAMessageTemplate>');
      expect(template.toJson(), {
        '_elementId': '<AAMessageTemplate>',
        'title': 'No saved places',
        'message': 'Save places on your phone to access them here.',
      });
    });

    test('updates local template values', () {
      final template = AAMessageTemplate(
        title: 'No saved places',
        message: 'Save places on your phone to access them here.',
      );

      template.updateTemplate(
        title: 'Saved places synced',
        message: 'Your saved places are now available in Android Auto.',
      );

      expect(template.title, 'Saved places synced');
      expect(
        template.message,
        'Your saved places are now available in Android Auto.',
      );
    });

    test('requires non-empty message', () {
      expect(
        () => AAMessageTemplate(title: 'No saved places', message: ''),
        throwsArgumentError,
      );
    });

    test('requires non-empty message when updating local values', () {
      final template = AAMessageTemplate(
        title: 'No saved places',
        message: 'Save places on your phone to access them here.',
      );

      expect(
        () => template.updateTemplate(title: 'No saved places', message: ''),
        throwsArgumentError,
      );
    });

    test('updates local values when native update succeeds', () async {
      final template = AAMessageTemplate(
        id: '<AAMessageTemplate>',
        title: 'No saved places',
        message: 'Save places on your phone to access them here.',
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        expect(methodCall.method, 'updateMessageTemplate');
        expect(methodCall.arguments, {
          'elementId': '<AAMessageTemplate>',
          'title': 'Saved places synced',
          'message': 'Your saved places are now available in Android Auto.',
        });
        return true;
      });

      await template.update(
        title: 'Saved places synced',
        message: 'Your saved places are now available in Android Auto.',
      );

      expect(template.title, 'Saved places synced');
      expect(
        template.message,
        'Your saved places are now available in Android Auto.',
      );
    });

    test('throws and keeps local values when native update fails', () async {
      final template = AAMessageTemplate(
        id: '<AAMessageTemplate>',
        title: 'No saved places',
        message: 'Save places on your phone to access them here.',
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(
          code: 'No screen found',
          message: 'No Android Auto screen found for template id',
        );
      });

      expect(
        template.setTitle('Saved places synced'),
        throwsA(isA<PlatformException>()),
      );

      expect(template.title, 'No saved places');
      expect(
          template.message, 'Save places on your phone to access them here.');
    });
  });
}
