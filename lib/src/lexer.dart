import 'package:text_expressions/src/choices.dart';
import 'package:text_expressions/src/parser.dart';
import 'package:text_expressions/src/symbols.dart';
import 'package:text_expressions/src/tokens.dart';

/// The lexer handles the breaking of strings into singular `Tokens`s and
/// `Symbol`s for the purpose of fine-grained control over parsing.
class Lexer {
  /// Instance of the `Parser` by whom this `Lexer` is employed.
  final Parser parser;

  /// Creates an instance of `Lexer`, passing in the parser it is employed by.
  Lexer(this.parser);

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
        tokens.add(Token(this, tokenType, content));
      }
    }

    return tokens;
  }

  /// Extracts a `List` of `Symbols` from [target].
  List<WithPosition<Symbol>> getSymbols(String target) {
    final symbols = <WithPosition<Symbol>>[];

    for (var position = 0; position < target.length; position++) {
      final symbol = Symbol.fromCharacter(target[position]);

      if (symbol != null) {
        symbols.add(WithPosition(symbol, position));
      }
    }

    symbols.add(WithPosition(Symbol.endOfString, target.length - 1));

    return symbols;
  }

  /// Extracts a `List` of `Choices` from [tokens].
  List<Choice> getChoices(List<Token> tokens) {
    final choices = <Choice>[];

    for (final token in tokens.where(
      (token) => token.type == TokenType.choice,
    )) {
      // Split case into operable parts.
      final parts = token.content.split(Symbol.choiceResultDivider.character);

      // The first part of a case is the command.
      final conditionRaw = parts.removeAt(0);

      // The other parts of a case are the result.
      final resultRaw = parts.join(Symbol.choiceResultDivider.character);

      var matcher = Matcher.always;
      final arguments = <String>[];
      final result = resultRaw;

      if (conditionRaw.contains(Symbol.argumentOpen.character)) {
        final commandParts = conditionRaw.split(Symbol.argumentOpen.character);
        if (commandParts.length > 2) {
          throw const FormatException(
            'Could not parse choice: Expected a command and optional arguments '
            'inside parentheses, but found multiple parentheses.',
          );
        }

        final command = commandParts[0];
        matcher = Matcher.fromString(command) ?? Matcher.always;

        final argumentsString =
            commandParts[1].substring(0, commandParts[1].length - 1);
        arguments.addAll(
          argumentsString.contains(',')
              ? argumentsString.split(',')
              : argumentsString.split('-'),
        );
      } else {
        matcher = Matcher.fromString(conditionRaw) ?? Matcher.equals;

        arguments.add(conditionRaw);
      }

      choices.add(
        Choice(
          condition: constructCondition(matcher, arguments),
          result: result,
        ),
      );
    }

    return choices;
  }

  /// Taking the [matcher] and the [arguments] passed into it, construct a
  /// `Condition` that must be met for a `Choice` to be matched to the control
  /// variable of an expression.
  Condition<String> constructCondition(
    Matcher matcher,
    List<String> arguments,
  ) {
    switch (matcher) {
      case Matcher.always:
        return (_) => true;

      case Matcher.startsWith:
        return (var control) => arguments.any(control.startsWith);
      case Matcher.endsWith:
        return (var control) => arguments.any(control.endsWith);
      case Matcher.contains:
        return (var control) => arguments.any(control.contains);
      case Matcher.equals:
        return (var control) =>
            arguments.any((argument) => control == argument);

      case Matcher.isGreater:
      case Matcher.isGreaterOrEqual:
      case Matcher.isLesser:
      case Matcher.isLesserOrEqual:
        final argumentsAreNumeric = arguments.map(isNumeric);
        if (argumentsAreNumeric.contains(false)) {
          throw FormatException(
            '''
Could not construct mathematical condition: '${matcher.name}' requires that its argument(s) be numeric.
One of the provided arguments $arguments is not numeric, and thus is not parsable as a number.

To prevent runtime exceptions, the condition has been set to evaluate to `false`.''',
          );
        }

        final argumentsAsNumbers = arguments.map(num.parse);
        final mathematicalConditions = argumentsAsNumbers.map(
          (argument) => constructMathematicalCondition(
            matcher,
            argument,
          ),
        );

        return (var control) {
          if (!isNumeric(control)) {
            return false;
          }
          final controlVariableAsNumber = num.parse(control);
          return mathematicalConditions.any(
            (condition) => condition.call(controlVariableAsNumber),
          );
        };

      case Matcher.isInGroup:
      case Matcher.isNotInGroup:
      case Matcher.isInRange:
      case Matcher.isNotInRange:
        final numberOfNumericArguments = arguments.fold<int>(
          0,
          (previousValue, argument) =>
              isNumeric(argument) ? previousValue + 1 : previousValue,
        );
        final isTypeMismatch = numberOfNumericArguments != 0 &&
            numberOfNumericArguments != arguments.length;

        if (isTypeMismatch) {
          throw const FormatException(
            'Could not construct a set condition: All arguments must be of the '
            'same type.',
          );
        }

        final rangeType = numberOfNumericArguments == 0 ? String : num;
        // If the character is a number, parse it, otherwise get its position
        // within the [characters] array.
        final getNumericValue =
            rangeType is String ? characters.indexOf : num.parse;

        final argumentsAsNumbers = arguments.map(getNumericValue);
        final setCondition = constructSetCondition(
          matcher,
          argumentsAsNumbers,
        );

        return (var control) {
          if (!isNumeric(control)) {
            return false;
          }
          final controlVariableAsNumber = num.parse(control);
          return setCondition(controlVariableAsNumber);
        };
    }
  }

  /// Construct a `Condition` based on mathematical checks.
  Condition<num> constructMathematicalCondition(
    Matcher matcher,
    num argument,
  ) {
    switch (matcher) {
      case Matcher.isGreater:
        return (var control) => control > argument;
      case Matcher.isGreaterOrEqual:
        return (var control) => control >= argument;
      case Matcher.isLesser:
        return (var control) => control < argument;
      case Matcher.isLesserOrEqual:
        return (var control) => control <= argument;
      case Matcher.always:
      case Matcher.equals:
      case Matcher.startsWith:
      case Matcher.endsWith:
      case Matcher.contains:
      case Matcher.isInGroup:
      case Matcher.isNotInGroup:
      case Matcher.isInRange:
      case Matcher.isNotInRange:
        break;
    }
    return (_) => false;
  }

  /// Construct a `Condition` based on set checks.
  Condition<num> constructSetCondition(
    Matcher matcher,
    Iterable<num> arguments,
  ) {
    switch (matcher) {
      case Matcher.isInGroup:
        return (var control) => arguments.contains(control);
      case Matcher.isNotInGroup:
        return (var control) => !arguments.contains(control);
      case Matcher.isInRange:
        return (var control) => isInRange(
              control,
              arguments.elementAt(0),
              arguments.elementAt(1),
            );
      case Matcher.isNotInRange:
        return (var control) => !isInRange(
              control,
              arguments.elementAt(0),
              arguments.elementAt(1),
            );
      case Matcher.always:
      case Matcher.equals:
      case Matcher.startsWith:
      case Matcher.endsWith:
      case Matcher.contains:
      case Matcher.isGreater:
      case Matcher.isGreaterOrEqual:
      case Matcher.isLesser:
      case Matcher.isLesserOrEqual:
        break;
    }
    return (_) => false;
  }

  /// Returns `true` if [target] is numeric.
  bool isNumeric(String target) => num.tryParse(target) != null;

  /// Returns `true` if [subject] falls within the range bound by [minimum]
  /// (inclusive) and [maximum] (inclusive).
  bool isInRange(num subject, num minimum, num maximum) =>
      minimum <= subject || subject <= maximum;
}
