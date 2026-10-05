import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('README image URLs remain visible on pub.dev', () {
    final readme = File('README.md').readAsStringSync();
    final urls = <String>[
      ...RegExp(
        r'!\[[^\]]*\]\(([^)]+)\)',
      ).allMatches(readme).map((match) => match.group(1)!),
      ...RegExp(
        r'''<(?:img|source)\b[^>]*\b(?:src|srcset)=["']([^"']+)["']''',
        caseSensitive: false,
      ).allMatches(readme).map((match) => match.group(1)!),
    ];

    expect(urls, isNotEmpty);
    for (final value in urls) {
      final uri = Uri.parse(value);
      expect(
        uri.scheme,
        'https',
        reason: 'Published README image URLs must not depend on the page path',
      );
      expect(uri.host, 'raw.githubusercontent.com');
      expect(uri.pathSegments.take(2), ['oguzhnatly', 'flutter_carplay']);
      expect(uri.pathSegments.length, greaterThanOrEqualTo(5));
      expect(uri.pathSegments[2], matches(RegExp(r'^[0-9a-f]{40}$')));
      expect(uri.pathSegments[3], 'previews');
      expect(
        File(
          uri.pathSegments.skip(3).join(Platform.pathSeparator),
        ).existsSync(),
        isTrue,
        reason: 'Each published image URL must name a bundled preview asset',
      );
    }
  });
}
