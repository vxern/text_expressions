import 'package:text_expressions/src/choices.dart';
import 'package:text_expressions/src/exceptions.dart';
import 'package:text_expressions/src/symbols.dart';
import 'package:text_expressions/src/tokens.dart';
import 'package:text_expressions/src/utils.dart';

/// Map of letters used for range checks.
const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

/// The face of the `text_expressions` library; parses expressions defined in
/// square brackets '[]', arguments defined in curly brackets '{}', and allows
/// for expressions to be defined externally and 'included' in a phrase through
/// the use of acute angles '<>'.
class Parser {
  /// Map of keys and their corresponding expressions.
  final Map<String, String> phrases = {};

  /// Loads a new set of [phrases] into the parser, clearing the previous set.
  void load({required Map<String, String> phrases}) => this.phrases
    ..clear()
    ..addAll(phrases);

  /// Takes [key], retrieves the phrase associated with [key] and parses it.
  @Deprecated('Use `process()` instead')
  String parseKey(
    String key, {
    Map<String, Object> named = const <String, Object>{},
    Set<Object> positional = const <Object>{},
  }) =>
      process(key, named: named, positional: positional);

  /// Takes [key], retrieves the phrase associated with [key] and parses it.
  String process(
    String key, {
    Map<String, Object> named = const <String, Object>{},
    Set<Object> positional = const <Object>{},
  }) {
    if (!phrases.containsKey(key)) {
      throw MissingKeyException('Could not parse phrase', key);
    }

    final phrase = phrases[key]!;

    return _process(phrase, Arguments(named, positional));
  }

  /// Takes [phrase], tokenises it, parses each `Token` and returns the
  /// accumulation of the parsed tokens as a string.
  String _process(String phrase, Arguments arguments) =>
      getTokens(phrase).map((token) => _processToken(token, arguments)).join();

  /// Taking a [token] and an [arguments] object, processes the [token] and
  /// returns the produced `String`.
  String _processToken(Token token, Arguments arguments) {
    switch (token.type) {
      case TokenType.external:
        return _processExternalClause(token, arguments);
      case TokenType.expression:
        return _processExpressionClause(token, arguments);
      case TokenType.parameter:
        return _processParameterClause(token, arguments);
      case TokenType.text:
        return token.content;
      case TokenType.choice:
        throw const ParserException(
          'Could not parse phrase',
          'Choices cannot be parsed as stand-alone entities.',
        );
    }
  }

  /// Fetches the external phrase from [Parser.phrases].  If the phrase is an
  /// expression, it is first parsed, and then returned.
  String _processExternalClause(Token token, Arguments arguments) {
    if (!phrases.containsKey(token.content)) {
      throw MissingKeyException(
        'Could not parse external phrase',
        token.content,
      );
    }

    final phrase = phrases[token.content].toString();

    if (!isExpression(phrase)) {
      return phrase;
    }

    return _processExpressionClause(token, arguments, phrase);
  }

  // TODO(vxern): Document.
  String _processExpressionClause(
    Token token,
    Arguments arguments, [
    String? phrase,
  ]) {
    // Remove the surrounding brackets to leave just the content.
    final phraseContent =
        phrase != null ? phrase.substring(1, phrase.length - 1) : token.content;

    final tokens = getTokens(phraseContent);

    final controlVariable = _processToken(tokens.removeAt(0), arguments);
    final choices = getChoices(tokens);

    final matchedChoice =
        choices.firstWhereOrNull((choice) => choice.isMatch(controlVariable));

    if (matchedChoice != null) {
      return _process(matchedChoice.result, arguments);
    }

    throw ParserException(
      'Could not parse expression',
      "The control variable '$controlVariable' "
          'does not match any choice defined inside the expression.',
    );
  }

  // TODO(vxern): Document.
  String _processParameterClause(Token token, Arguments arguments) {
    if (isInteger(token.content)) {
      return _processPositionalParameter(token, arguments);
    }

    return _processNamedParameter(token, arguments);
  }

  // TODO(vxern): Document.
  String _processNamedParameter(Token token, Arguments arguments) {
    if (!arguments.named.containsKey(token.content)) {
      throw ParserException(
        'Could not parse a named parameter',
        "An argument with the name '${token.content}' hadn't been supplied to "
            'the parser at the time of parsing the named parameter of the same '
            'name.',
      );
    }

    return arguments.named[token.content].toString();
  }

  // TODO(vxern): Document.
  String _processPositionalParameter(Token token, Arguments arguments) {
    final index = int.parse(token.content);

    if (index < 0) {
      throw const ParserException(
        'Could not parse a positional parameter',
        'The index must not be negative.',
      );
    }

    if (index >= arguments.positional.length) {
      throw ParserException(
        'Could not parse a positional parameter',
        'Attempted to access an argument at position $index, but '
            '${arguments.positional.length} argument(s) were supplied.',
      );
    }

    return arguments.positional.elementAt(index).toString();
  }
}

/// Container for parameters passed into the parser.
class Arguments {
  /// Parameters whise values are to be matched by their name (key).
  final Map<String, Object> named;

  /// Parameters to be matched by their position in the `Set`.
  final Set<Object> positional;

  /// Creates an instance of a container for arguments passed into the parser.
  const Arguments(this.named, this.positional);
}

/// Checks if [phrase] is an expression, which needs to be 'included' in the
/// main phrase.
bool isExpression(String phrase) =>
    phrase.startsWith(Symbol.expressionOpen.character) &&
    phrase.endsWith(Symbol.expressionClosed.character);

/// Returns `true` if [target] is an integer.
bool isInteger(String target) => int.tryParse(target) != null;
