import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AALongMessageTemplate', () {
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
  });
}
