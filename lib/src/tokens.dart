import 'package:text_expressions/src/lexer.dart';
import 'package:text_expressions/src/parser.dart';
import 'package:text_expressions/src/symbols.dart';
import 'package:text_expressions/src/utils.dart';

/// A representation of a part of a string which needs different handling
/// of [content] based on its [type]
class Token {
  /// Instance of the `Lexer` working with this token
  final Lexer lexer;

  /// Identifies the [content] as being of a certain type, and is used to
  /// decide how [content] should be parsed
  final TokenType type;

  /// The text content of this token
  final String content;

  /// Creates an instance of `Token` with the passed [type] and optional
  /// [content]
  const Token(this.lexer, this.type, this.content);

  /// Parses this token by calling the correct parsing function corresponding to
  /// the [type] of this token
  String parse(Arguments arguments) {
    switch (type) {
      case TokenType.External:
        return parseExternal(arguments);
      case TokenType.Expression:
        return parseExpression(arguments);
      case TokenType.Parameter:
        return parseParameter(arguments);
      case TokenType.Text:
        return parseText();
      case TokenType.Choice:
        return Parser.fallback;
    }
  }

  /// Fetches the external phrase from [Parser.phrases]. If the phrase is an
  /// expression, it is first parsed, and then returned
  String parseExternal(Arguments arguments) {
    if (!lexer.parser.phrases.containsKey(content)) {
      lexer.log.severe(
          "Could not parse external phrase: a phrase with the key '<$content>' "
          'does not exist.');
      return Parser.fallback;
    }

    final phrase = lexer.parser.phrases.containsKey(content)
        ? lexer.parser.phrases[content].toString()
        : Parser.fallback;

    if (isExternal(phrase)) {
      return lexer.parser.parse(phrase);
    }

    // Remove the surrounding brackets to leave just the content
    final phraseContent = phrase.substring(1, phrase.length - 1);

    return parseExpression(arguments, phraseContent);
  }

  /// Resolves the expression, and returns the result
  String parseExpression(Arguments arguments, [String? phrase]) {
    final tokens = lexer.getTokens(phrase ?? content);

    final controlVariable = tokens.removeAt(0).parse(arguments);
    final choices = lexer.getChoices(tokens);

    final matchedChoice =
        choices.firstWhereOrNull((choice) => choice.isMatch(controlVariable));

    if (matchedChoice != null) {
      return lexer.parser.parse(matchedChoice.result);
    }

    lexer.log.severe(
        "Could not parse expression: The control variable '$controlVariable' "
        'does not match any choice defined inside the expression.');
    return Parser.fallback;
  }

  /// Fetches the argument described by the parameter and returns its value
  String parseParameter(Arguments arguments) {
    if (isInteger(content)) {
      return parsePositionalParameter(arguments);
    }

    if (!arguments.named.containsKey(content)) {
      lexer.log.severe(
          'Could not parse a named parameter: An argument with the name '
          "$content' hadn't been supplied to the parser at the time of parsing "
          'the named parameter of the same name.');
      return Parser.fallback;
    }

    return arguments.named[content].toString();
  }

  /// Returns the parameter described by the index ([content]) of this `Token`.
  String parsePositionalParameter(Arguments arguments) {
    final index = int.parse(content);

    if (index < 0) {
      lexer.log.severe(
          'Could not parse a positional parameter: The index must not be '
          'negative.');
      return Parser.fallback;
    }

    if (index >= arguments.positional.length) {
      lexer.log.severe(
          'Could not parse a positional parameter: Attempted to access an '
          'argument at position $index, but '
          '${arguments.positional.length} argument/s were supplied.');
      return Parser.fallback;
    }

    return arguments.positional.elementAt(index).toString();
  }

  /// Returns this token's [content]
  String parseText() => content;

  /// Checks if [phrase] is an external phrase, which needs to be 'included'
  /// in the main phrase
  bool isExternal(String phrase) =>
      phrase.startsWith(Symbols.ExpressionOpen) &&
      phrase.endsWith(Symbols.ExpressionClosed);

  /// Returns `true` if [target] is an integer.
  bool isInteger(String target) => int.tryParse(target) != null;
}

/// The type of a token which decides how the parser will parse and
/// manipulate the token's content.
enum TokenType {
  /// A phrase (value) defined under a different key.
  External,

  /// A one-line switch-case statement.
  Expression,

  /// An argument designator which allows for external parameters to be inserted
  /// into the phrase being parsed.
  Parameter,

  /// A choice (case) in an expression (switch statement) that is matched
  /// against the control variable.
  Choice,

  /// A string of text which does not require to be parsed.
  Text,
}
