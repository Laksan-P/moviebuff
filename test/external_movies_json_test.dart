import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('external_movies.json is a valid top-level JSON array', () {
    final file = File('external_movies.json');
    expect(file.existsSync(), isTrue, reason: 'external_movies.json must exist');

    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<List>());

    final list = decoded as List;
    expect(list.isNotEmpty, isTrue);

    for (final item in list) {
      expect(item, isA<Map>());
      final map = item as Map;
      expect(map['title'], isNotNull);
      final image = map['image']?.toString() ?? '';
      final poster = map['posterUrl']?.toString() ?? '';
      expect(
        image.isNotEmpty || poster.isNotEmpty,
        isTrue,
        reason: 'Movie ${map['title']} needs image or posterUrl',
      );
    }
  });
}
