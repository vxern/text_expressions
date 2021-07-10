import 'package:enum_to_string/enum_to_string.dart';
import 'package:text_expressions/text_expressions.dart';

import 'utils.dart';

/// Service which acts as an interface for obtaining translations
/// corresponding to the given key
class Translation {
  /// The parser utilised by the translation service
  final Parser parser = Parser();

  /// Load the strings corresponding to the language code provided
  void load(Language language) {
    // Extract the language name in lowercase from the enumerator
    String languageName = EnumToString.convertToString(language);

    parser.load(
      expressions: Utils.readJsons([
        '$languageName/expressions.json',
        '$languageName/strings.json',
      ]),
    );
  }

  String getString(
    String key, {
    Map<String, dynamic> parameters = const {},
    List<dynamic> positionalParameters = const [],
  }) {
    return parser.getTranslation(
      key,
      namedParameters: parameters,
      positionalParameters: positionalParameters,
    );
  }
}

enum Language { english, polish, romanian }
