import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AALongMessageTemplate', () {
    const channel = MethodChannel('com.oguzhnatly.flutter_android_auto');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('serializes long message template', () {
      final template = AALongMessageTemplate(
        id: '<AALongMessageTemplate>',
        title: 'Terms and conditions',
        message: 'Read these longer terms before continuing in Android Auto.',
      );

      expect(template.uniqueId, '<AALongMessageTemplate>');
      expect(template.toJson(), {
        '_elementId': '<AALongMessageTemplate>',
        'title': 'Terms and conditions',
        'message': 'Read these longer terms before continuing in Android Auto.',
      });
    });

    test('updates local template values', () {
      final template = AALongMessageTemplate(
        title: 'Safety information',
        message: 'Review these safety notes before using the app in your car.',
      );

      template.updateTemplate(
        title: 'Safety information updated',
        message:
            'These updated safety notes are now available in Android Auto.',
      );

      expect(template.title, 'Safety information updated');
      expect(
        template.message,
        'These updated safety notes are now available in Android Auto.',
      );
    });

    test('requires non-empty message', () {
      expect(
        () => AALongMessageTemplate(title: 'Safety information', message: ''),
        throwsArgumentError,
      );
    });

    test('requires non-empty message when updating local values', () {
      final template = AALongMessageTemplate(
        title: 'Safety information',
        message: 'Review these safety notes before using the app in your car.',
      );

      expect(
        () => template.updateTemplate(title: 'Safety information', message: ''),
        throwsArgumentError,
      );
    });

    test('updates local values when native update succeeds', () async {
      final template = AALongMessageTemplate(
        id: '<AALongMessageTemplate>',
        title: 'Safety information',
        message: 'Review these safety notes before using the app in your car.',
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        expect(methodCall.method, 'updateLongMessageTemplate');
        expect(methodCall.arguments, {
          'elementId': '<AALongMessageTemplate>',
          'title': 'Safety information updated',
          'message':
              'These updated safety notes are now available in Android Auto.',
        });
        return true;
      });

      await template.update(
        title: 'Safety information updated',
        message:
            'These updated safety notes are now available in Android Auto.',
      );

      expect(template.title, 'Safety information updated');
      expect(
        template.message,
        'These updated safety notes are now available in Android Auto.',
      );
    });

    test('throws and keeps local values when native update fails', () async {
      final template = AALongMessageTemplate(
        id: '<AALongMessageTemplate>',
        title: 'Safety information',
        message: 'Review these safety notes before using the app in your car.',
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(
          code: 'No screen found',
          message: 'No Android Auto screen found for template id',
        );
      });

      expect(
        template.setMessage(
          'These updated safety notes are now available in Android Auto.',
        ),
        throwsA(isA<PlatformException>()),
      );

      expect(template.title, 'Safety information');
      expect(
        template.message,
        'Review these safety notes before using the app in your car.',
      );
    });
  });
}
