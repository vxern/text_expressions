import 'package:sprint/sprint.dart';

import 'package:translation_parser/src/cases.dart';
import 'package:translation_parser/src/symbols.dart';
import 'package:translation_parser/src/tokens.dart';
import 'package:translation_parser/src/utils.dart';

class Parser {
  final Sprint log = Sprint('Parser');

  /// Used as a fallback 'translation' for an inexistent key
  static const String placeholder = '?';

  /// Map of keys and their corresponding translations
  Map<String, String> translations = {};

  /// Map of expressions resolved by the parser
  Map<String, String> expressions = {};

  /// Map of parameters passed into the parser when processing a translation
  Map<String, dynamic> namedParameters = {};

  /// List of parameters used for positional parameter checking
  List<dynamic> positionalParameters = [];

  /// Load translations and - optionally - expressions
  void load({
    required Map<String, String> translations,
    Map<String, String> expressions = const {},
  }) {
    this.translations = translations;
    this.expressions = expressions;
  }

  /// Takes a string, tokenises it, parses the tokens and returns the result
  String parseString(
    String target, {
    Map<String, dynamic> parameters = const {},
    List<dynamic>? positionalParameters,
  }) {
    this.namedParameters = parameters;
    this.positionalParameters = positionalParameters ?? parameters.values.toList();

    return target.toTokens().map((token) => parseToken(token)).join();
  }

  /// Takes a `Token` and decides which function should resolve it
  String parseToken(Token token) {
    switch (token.type) {
      case TokenType.External:
        return parseExternal(token);
      case TokenType.Expression:
        return parseExpression(token);
      case TokenType.Parameter:
        return parseParameter(token);
      case TokenType.Text:
        return parseText(token);
      default:
        return placeholder;
    }
  }

  /// Takes a `Token` of type `TokenType.External`, fetches the external
  /// string from [expressions] or [translations], resolves the expression if
  /// necessary, and returns the result
  String parseExternal(Token token) {
    if (!expressions.containsKey(token.content) && !translations.containsKey(token.content)) {
      log.error("Could not parse an external string: <${token.content}> does not exist!");
      return placeholder;
    }

    final String fetchedString = expressions[token.content] ?? translations[token.content] ?? placeholder;

    if (!fetchedString.startsWith(Symbols.expressionOpen) && !fetchedString.endsWith(Symbols.expressionClosed)) {
      return parseString(fetchedString);
    }

    return parseExpression(Token(
      TokenType.Expression,
      content: fetchedString.substring(1, fetchedString.length - 1),
    ));
  }

  /// Takes a `Token` of type `TokenType.Expression`, resolves the expression,
  /// and returns the result
  String parseExpression(Token token) {
    final tokens = token.content.toTokens();
    final condition = parseParameter(tokens.removeAt(0));
    final cases = tokens.toCases();

    try {
      final matchedCase = cases.firstWhere((case_) => case_.matchesCondition(condition));
      return parseString(matchedCase.result);
    } catch (_) {
      log.error('$condition did not match to any case');
      return placeholder;
    }
  }

  /// Takes a `Token` of type `TokenType.Parameter`, fetches the parameter
  /// designated indicated by the template and returns its value
  String parseParameter(Token token) {
    if (Utils.isInteger(token.content)) {
      return parsePositionalParameter(int.parse(token.content));
    }

    if (!namedParameters.containsKey(token.content)) {
      log.error('Could not parse a parameter designator:'
          "{${token.content}} hadn't been supplied into the string");
      return placeholder;
    }

    return namedParameters[token.content].toString();
  }

  /// Takes a [position] and returns the parameter found at that position in [positionalParameters]
  String parsePositionalParameter(int position) {
    if (position < 0 || position >= positionalParameters.length) {
      log.error('A positional parameter designator had an out-of-bounds position');
      return placeholder;
    }

    return positionalParameters[position].toString();
  }

  /// Takes a `Token` of type `TokenType.Text` and returns its [content]
  String parseText(Token token) => token.content;

  /// Whether the parser has a translation corresponding with the key
  bool hasTranslationFor(String key) => translations.containsKey(key);
}
