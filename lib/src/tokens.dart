import 'package:text_expressions/src/symbols.dart';

/// A representation of a part of a string which needs different handling
/// of [content] based on its [type].
class Token {
  /// Identifies the [content] as being of a certain type, and is used to
  /// decide how [content] should be parsed.
  final TokenType type;

  /// The text content of this token.
  final String content;

  /// Creates an instance of `Token` with the passed [type] and optional
  /// [content].
  const Token(this.type, this.content);
}

/// The type of a token which decides how the parser will parse and
/// manipulate the token's content.
enum TokenType {
  /// A phrase (value) defined under a different key.
  external,

  /// A one-line switch-case statement.
  expression,

  /// An argument designator which allows for external parameters to be inserted
  /// into the phrase being parsed.
  parameter,

  /// A choice (case) in an expression (switch statement) that is matched
  /// against the control variable.
  choice,

  /// A string of text which does not require to be parsed.
  text,
}

/// Extracts a `List` of `Tokens` from [target].
List<Token> getTokens(String target) {
  final tokens = <Token>[];

  // In order to break the string down correctly into tokens, the parser
  // must see exactly where each symbol lies in the string.
  final symbolsWithPositions = getSymbols(target);

  // How deeply nested the current symbol being parsed is.
  var nestingLevel = 0;
  // Used for obtaining substrings of the subject string.
  var lastSymbolPosition = 0;
  // Used for obtaining substrings of choices.
  var lastChoicePosition = 0;

  // Iterate over symbols, finding and extracting tokens.
  for (final symbolWithPosition in symbolsWithPositions) {
    TokenType? tokenType;
    String? content;

    final symbol = symbolWithPosition.object;

    switch (symbol) {
      case Symbol.externalOpen:
      case Symbol.expressionOpen:
      case Symbol.parameterOpen:
        tokenType = TokenType.text;

        if (nestingLevel == 0 && lastChoicePosition == 0) {
          final precedingString = target.substring(
            lastSymbolPosition,
            symbolWithPosition.position,
          );
          if (precedingString.isNotEmpty) {
            content = precedingString;
          }
          lastSymbolPosition = symbolWithPosition.position + 1;
        }

        nestingLevel++;
        break;
      case Symbol.externalClosed:
        tokenType = TokenType.external;
        continue closed;
      case Symbol.expressionClosed:
        tokenType = TokenType.expression;
        continue closed;
      closed:
      case Symbol.parameterClosed:
        tokenType ??= TokenType.parameter;

        if (nestingLevel == 1 && lastChoicePosition == 0) {
          content = target.substring(
            lastSymbolPosition,
            symbolWithPosition.position,
          );
          lastSymbolPosition = symbolWithPosition.position + 1;
        }

        nestingLevel--;
        break;
      case Symbol.choiceIntroducer:
        if (nestingLevel == 0 && lastChoicePosition == 0) {
          lastChoicePosition = symbolWithPosition.position + 1;
        }
        break;
      case Symbol.choiceSeparator:
        tokenType = TokenType.choice;

        if (nestingLevel == 0 && lastChoicePosition != 0) {
          content = target
              .substring(lastChoicePosition, symbolWithPosition.position)
              .trim();
          lastChoicePosition = symbolWithPosition.position + 1;
        }
        break;
      case Symbol.endOfString:
        if (lastSymbolPosition == target.length) {
          break;
        }

        if (lastChoicePosition == 0) {
          tokenType = TokenType.text;
          content = target.substring(lastSymbolPosition);
          break;
        }

        tokenType = TokenType.choice;
        content = target.substring(lastChoicePosition).trim();
        break;
      case Symbol.choiceResultDivider:
      case Symbol.argumentOpen:
      case Symbol.argumentClosed:
        break;
    }

    if (tokenType != null && content != null) {
      tokens.add(Token(tokenType, content));
    }
  }

  return tokens;
}
