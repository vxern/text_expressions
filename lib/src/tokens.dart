import 'package:text_expressions/src/symbols.dart';

extension BreakIntoTokens on String {
  List<Token> toTokens() {
    // In order to break the string down correctly into tokens, the parser must see where different
    // symbols are located that separate these tokens from each other.
    final List<Symbol> symbols = this.toSymbols();
    // Buffer for tokens
    final List<Token> tokens = [];

    // How deeply nested the current symbol being parsed is
    int nestingLevel = 0;
    // Used for obtaining substrings of the subject string
    int lastSymbolPosition = 0;
    // Used for obtaining substrings of choices
    int lastChoicePosition = 0;

    // Iterate over symbols, finding and extracting tokens
    for (final symbol in symbols) {
      TokenType? tokenType;
      String? content;

      switch (symbol.type) {
        case SymbolType.externalOpen:
        case SymbolType.expressionOpen:
        case SymbolType.parameterOpen:
          tokenType = TokenType.Text;

          if (nestingLevel == 0 && lastChoicePosition == 0) {
            String precedingString = this.substring(lastSymbolPosition, symbol.position);
            if (precedingString.isNotEmpty) {
              content = precedingString;
            }
            lastSymbolPosition = symbol.position + 1;
          }

          nestingLevel++;
          break;
        case SymbolType.externalClosed:
          tokenType = TokenType.External;
          continue closed;
        case SymbolType.expressionClosed:
          tokenType ??= TokenType.Expression;
          continue closed;
        closed:
        case SymbolType.parameterClosed:
          tokenType ??= TokenType.Parameter;

          if (nestingLevel == 1 && lastChoicePosition == 0) {
            content = this.substring(lastSymbolPosition, symbol.position);
            lastSymbolPosition = symbol.position + 1;
          }

          nestingLevel--;
          break;
        case SymbolType.choiceIntroducer:
          if (nestingLevel == 0 && lastChoicePosition == 0) {
            lastChoicePosition = symbol.position + 1;
          }
          break;
        case SymbolType.choiceDivider:
          tokenType = TokenType.Case;

          if (nestingLevel == 0 && lastChoicePosition != 0) {
            content = this.substring(lastChoicePosition, symbol.position).trim();
            lastChoicePosition = symbol.position + 1;
          }
          break;
        case SymbolType.endOfString:
          if (lastSymbolPosition == this.length) {
            break;
          }

          if (lastChoicePosition == 0) {
            tokenType = TokenType.Text;
            content = this.substring(lastSymbolPosition);
            break;
          }

          tokenType = TokenType.Case;
          content = this.substring(lastChoicePosition).trim();
          break;
      }

      if (tokenType != null && content != null) {
        tokens.add(Token(tokenType, content: content));
      }
    }

    return tokens;
  }
}

/// A representation of a part of a string which needs different handling
/// of [content] according to its [type]
class Token {
  final TokenType type;
  final String content;

  Token(this.type, {this.content = ''});
}

/// The type of a token which decides how the parser will parse and
/// manipulate the token's content.
enum TokenType {
  External, // A string stored in a different entry
  Expression, // An expression inside the translation string
  Parameter, // A parameter locator in whose place a parameter is placed
  Case, // A choice / case in an expression
  Text,
}
