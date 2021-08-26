import 'package:sprint/sprint.dart';

import 'package:text_expressions/src/lexer.dart';

/// Map of letters used for range checks
const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

/// The face of the `text_expressions` library; parses expressions defined in
/// square brackets '[]', arguments defined in curly brackets '{}', and allows
/// for expressions to be defined externally and 'included' in a phrase through
/// the use of acute angles '<>'
class Parser {
  /// Used as a fallback 'translation' for an inexistent key
  static const String fallback = '?';

  /// Instance of `Sprint` message printer for the parser
  final Sprint log;

  /// Instace of `Lexer` for breaking phrases into their parsable components
  late final Lexer lexer;

  /// Map of keys and their corresponding expressions
  final Map<String, String> phrases = {};

  /// Creates an instance of an expression parser
  Parser({bool quietMode = true})
      : log = Sprint('Parser', quietMode: quietMode) {
    lexer = Lexer(this, quietMode: quietMode);
  }

  /// Loads a new set of [phrases] into the parser, clearing the previous set
  void load({required Map<String, String> phrases}) => phrases
    ..clear()
    ..addAll(phrases);

  /// Takes [target], tokenises it, parses each token and returns the
  /// accumulation of the parsed tokens as a string
  String parse(
    String target, {
    Map<String, dynamic> named = const <String, dynamic>{},
    Set<dynamic> positional = const <dynamic>{},
  }) =>
      lexer
          .getTokens(target)
          .map((token) => token.parse(Arguments(named, positional)))
          .join();
}

/// Container for parameters passed into the parser
class Arguments {
  /// Parameters whise values are to be matched by their name (key)
  final Map<String, dynamic> named;

  /// Parameters to be matched by their position in the `Set`
  final Set<dynamic> positional;

  /// Creates an instance of a container for arguments passed into the parser
  const Arguments(this.named, this.positional);
}
