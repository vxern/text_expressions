import 'package:text_expressions/text_expressions.dart';

import 'utils.dart';

/// A service acting as an interface for obtaining translations corresponding to
/// the given key.
class Translation {
  /// The parser utilised by the translation service.
  final Parser parser = Parser();

  /// Load the strings corresponding to the language code provided.
  void load(Language language) => parser.load(
        phrases: readJsons([
          '${language.name}/expressions.json',
          '${language.name}/strings.json',
        ]),
      );

  String translate(
    String key, {
    Map<String, Object> named = const <String, Object>{},
    Set<Object> positional = const <Object>{},
  }) =>
      parser.parseKey(key, named: named, positional: positional);
}

enum Language { english, polish, romanian }
