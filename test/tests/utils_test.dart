import 'package:test/test.dart';

import 'package:text_expressions/src/utils.dart';

const elements = ['a', 'b', 'c'];

void main() {
  late String? element;

  group('firstWhereOrNull()', () {
    test('returns element when found.', () {
      expect(
        () => element = elements.firstWhereOrNull((element) => element == 'a'),
        returnsNormally,
      );
      expect(element, equals('a'));
    });

    test('returns null when not found.', () {
      expect(
        () => element = elements.firstWhereOrNull((element) => element == '1'),
        returnsNormally,
      );
      expect(element, equals(null));
    });
  });
}
