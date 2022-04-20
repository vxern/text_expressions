import 'package:enum_as_string/enum_as_string.dart';
import 'package:text_expressions/text_expressions.dart';

import 'utils.dart';

/// A service acting as an interface for obtaining translations corresponding to
/// the given key.
class Translation {
  /// The parser utilised by the translation service.
  final Parser parser = Parser(quietMode: false);

  /// Load the strings corresponding to the language code provided.
  void load(Language language) {
    // Extract the language name in lowercase from the enumerator.
    final languageName = Enum.asString(language);

    final phrases = readJsons([
      '$languageName/expressions.json',
      '$languageName/strings.json',
    ]);

    parser.load(phrases: phrases);
  }

  String translate(
    String key, {
    Map<String, Object> named = const <String, Object>{},
    Set<Object> positional = const <Object>{},
  }) =>
      parser.parseKey(key, named: named, positional: positional);
}

enum Language { english, polish, romanian }
