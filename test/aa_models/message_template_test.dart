import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AAMessageTemplate', () {
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
  });
}
