import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _sponsorImage =
    'https://img.shields.io/badge/Sponsor-GitHub-ea4aaa?logo=github';
const _starHistoryImage =
    'https://star-history.dera.page/svg?repos=oguzhnatly/flutter_carplay&type=Date';
const _contributorsImage =
    'https://contrib.rocks/image?repo=oguzhnatly/flutter_carplay';
const _communityImages = {_sponsorImage, _starHistoryImage, _contributorsImage};

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
      if (_communityImages.contains(value)) continue;
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

  test('README community images retain their order and natural sizing', () {
    final readme = File('README.md').readAsStringSync();
    for (final image in _communityImages) {
      expect(image.allMatches(readme).length, 1);
    }
    expect(
      readme.indexOf(_sponsorImage),
      lessThan(readme.indexOf(_starHistoryImage)),
    );
    expect(
      readme.indexOf(_starHistoryImage),
      lessThan(readme.indexOf(_contributorsImage)),
    );
    expect(readme, contains('![Contributors]($_contributorsImage)'));
    expect(
      readme,
      contains(
        '[![Star History Chart]($_starHistoryImage)]'
        '(https://star-history.dera.page/#oguzhnatly/flutter_carplay&Date)',
      ),
    );
    expect(
      readme,
      contains(
        '[![Sponsor on GitHub]($_sponsorImage)]'
        '(https://github.com/sponsors/oguzhnatly)',
      ),
    );
  });
}
