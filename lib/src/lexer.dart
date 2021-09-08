import 'package:enum_as_string/enum_as_string.dart';
import 'package:sprint/sprint.dart';

import 'package:text_expressions/src/choices.dart';
import 'package:text_expressions/src/parser.dart';
import 'package:text_expressions/src/symbols.dart';
import 'package:text_expressions/src/tokens.dart';

/// The lexer handles the breaking of strings into singular `Tokens`s and
/// `Symbol`s for the purpose of fine-grained control over parsing
class Lexer {
  /// Instance of `Sprint` for logging messages specific to the `Lexer`
  final Sprint log;

  /// Instance of the `Parser` by which this `Lexer` is employed
  final Parser parser;

  /// Creates an instance of `Lexer`, passing in the parser it is employed by
  Lexer(this.parser, {bool quietMode = false})
      : log = Sprint('Lexer', quietMode: quietMode);

  /// Extracts a `List` of `Token`s from [target]
  List<Token> getTokens(String target) {
    final tokens = <Token>[];

    // In order to break the string down correctly into tokens, the parser
    // must see exactly where each symbol lies in the string
    final symbols = getSymbols(target);

    // How deeply nested the current symbol being parsed is
    var nestingLevel = 0;
    // Used for obtaining substrings of the subject string
    var lastSymbolPosition = 0;
    // Used for obtaining substrings of choices
    var lastChoicePosition = 0;

    // Iterate over symbols, finding and extracting tokens
    for (final symbol in symbols) {
      TokenType? tokenType;
      String? content;

      switch (symbol.type) {
        case SymbolType.ExternalOpen:
        case SymbolType.ExpressionOpen:
        case SymbolType.ParameterOpen:
          tokenType = TokenType.Text;

          if (nestingLevel == 0 && lastChoicePosition == 0) {
            final precedingString =
                target.substring(lastSymbolPosition, symbol.position);
            if (precedingString.isNotEmpty) {
              content = precedingString;
            }
            lastSymbolPosition = symbol.position + 1;
          }

          nestingLevel++;
          break;
        case SymbolType.ExternalClosed:
          tokenType = TokenType.External;
          continue closed;
        case SymbolType.ExpressionClosed:
          tokenType = TokenType.Expression;
          continue closed;
        closed:
        case SymbolType.ParameterClosed:
          tokenType ??= TokenType.Parameter;

          if (nestingLevel == 1 && lastChoicePosition == 0) {
            content = target.substring(lastSymbolPosition, symbol.position);
            lastSymbolPosition = symbol.position + 1;
          }

          nestingLevel--;
          break;
        case SymbolType.ChoiceIntroducer:
          if (nestingLevel == 0 && lastChoicePosition == 0) {
            lastChoicePosition = symbol.position + 1;
          }
          break;
        case SymbolType.ChoiceSeparator:
          tokenType = TokenType.Choice;

          if (nestingLevel == 0 && lastChoicePosition != 0) {
            content =
                target.substring(lastChoicePosition, symbol.position).trim();
            lastChoicePosition = symbol.position + 1;
          }
          break;
        case SymbolType.EndOfString:
          if (lastSymbolPosition == target.length) {
            break;
          }

          if (lastChoicePosition == 0) {
            tokenType = TokenType.Text;
            content = target.substring(lastSymbolPosition);
            break;
          }

          tokenType = TokenType.Choice;
          content = target.substring(lastChoicePosition).trim();
          break;
      }

      if (tokenType != null && content != null) {
        tokens.add(Token(this, tokenType, content));
      }
    }

    return tokens;
  }

  /// Extracts a `List` of `Symbol`s from [target]
  List<Symbol> getSymbols(String target) {
    final symbols = <Symbol>[];

    for (var position = 0; position < target.length; position++) {
      SymbolType? symbolType;

      switch (target[position]) {
        case Symbols.ExternalOpen:
          symbolType = SymbolType.ExternalOpen;
          break;
        case Symbols.ExternalClosed:
          symbolType = SymbolType.ExternalClosed;
          break;
        case Symbols.ExpressionOpen:
          symbolType = SymbolType.ExpressionOpen;
          break;
        case Symbols.ExpressionClosed:
          symbolType = SymbolType.ExpressionClosed;
          break;
        case Symbols.ParameterOpen:
          symbolType = SymbolType.ParameterOpen;
          break;
        case Symbols.ParameterClosed:
          symbolType = SymbolType.ParameterClosed;
          break;
        case Symbols.ChoiceIntroducer:
          symbolType = SymbolType.ChoiceIntroducer;
          break;
        case Symbols.ChoiceSeparator:
          symbolType = SymbolType.ChoiceSeparator;
          break;
      }

      if (symbolType != null) {
        symbols.add(Symbol(symbolType, position));
      }
    }

    symbols.add(Symbol(SymbolType.EndOfString, target.length - 1));

    return symbols;
  }

  /// Extracts a `List` of `Choice`s from [tokens]
  List<Choice> getChoices(List<Token> tokens) {
    final choices = <Choice>[];

    for (final token in tokens.where(
      (token) => token.type == TokenType.Choice,
    )) {
      // Split case into operable parts
      final parts = token.content.split(Symbols.ChoiceResultDivider);

      // The first part of a case is the command
      final conditionRaw = parts.removeAt(0);

      // The other parts of a case are the result
      final resultRaw = parts.join(Symbols.ChoiceResultDivider);

      var operation = Operation.Default;
      final arguments = <String>[];
      final result = resultRaw;

      if (conditionRaw.contains(Symbols.ArgumentOpen)) {
        final commandParts = conditionRaw.split(Symbols.ArgumentOpen);
        if (commandParts.length > 2) {
          log.severe('''
Could not parse choice: Expected a command and optional arguments inside parentheses, but found multiple parentheses.''');
        }

        final command = commandParts[0];
        operation = Enum.fromString(
          Operation.values,
          command,
          orDefault: Operation.Default,
        )!;

        final argumentsString =
            commandParts[1].substring(0, commandParts[1].length - 1);
        arguments.addAll(
          argumentsString.contains(',')
              ? argumentsString.split(',')
              : argumentsString.split('-'),
        );
      } else {
        operation = Enum.fromString(
          Operation.values,
          conditionRaw,
          orDefault: Operation.Equals,
        )!;
        arguments.add(conditionRaw);
      }

      choices.add(Choice(
        condition: constructCondition(operation, arguments),
        result: result,
      ));
    }

    return choices;
  }

  /// Taking the [operation] and the [arguments] passed into it, construct a
  /// `Condition` which must be met for a `Choice` to be matched to the control
  /// variable of an expression
  Condition<String> constructCondition(
    Operation operation,
    List<String> arguments,
  ) {
    switch (operation) {
      case Operation.Default:
        return (_) => true;

      case Operation.StartsWith:
        return (var control) => arguments.any(control.startsWith);
      case Operation.EndsWith:
        return (var control) => arguments.any(control.endsWith);
      case Operation.Contains:
        return (var control) => arguments.any(control.contains);
      case Operation.Equals:
        return (var control) =>
            arguments.any((argument) => control == argument);

      case Operation.Greater:
      case Operation.GreaterOrEqual:
      case Operation.Lesser:
      case Operation.LesserOrEqual:
        final argumentsAreNumeric = arguments.map(isNumeric);
        if (argumentsAreNumeric.contains(false)) {
          log.severe('''
Could not construct mathematical condition: '${Enum.asString(operation)}' requires that its argument(s) be numeric.
One of the provided arguments $arguments is not numeric, and thus is not parsable as a number.

To prevent runtime exceptions, the condition has been set to evaluate to `false`.''');
          return (_) => false;
        }

        final argumentsAsNumbers = arguments.map(num.parse);
        final mathematicalConditions = argumentsAsNumbers.map(
          (argument) => constructMathematicalCondition(
            operation,
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

      case Operation.In:
      case Operation.NotIn:
      case Operation.InRange:
      case Operation.NotInRange:
        final numberOfNumericArguments = arguments.fold<int>(
          0,
          (previousValue, argument) =>
              isNumeric(argument) ? previousValue + 1 : previousValue,
        );
        final isTypeMismatch = numberOfNumericArguments != 0 &&
            numberOfNumericArguments != arguments.length;

        if (isTypeMismatch) {
          log.severe('''
Could not construct a set condition: All arguments must be of the same type.''');
          return (_) => false;
        }

        final rangeType = numberOfNumericArguments == 0 ? String : num;
        // If the character is a number, parse it, otherwise get its position
        // within the [characters] array.
        final getNumericValue =
            rangeType is String ? characters.indexOf : num.parse;

        final argumentsAsNumbers = arguments.map(getNumericValue);
        final setCondition = constructSetCondition(
          operation,
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

  /// Construct a `Condition` based on mathematical checks
  Condition<num> constructMathematicalCondition(
      Operation operation, num argument) {
    switch (operation) {
      case Operation.Greater:
        return (var control) => control > argument;
      case Operation.GreaterOrEqual:
        return (var control) => control >= argument;
      case Operation.Lesser:
        return (var control) => control < argument;
      case Operation.LesserOrEqual:
        return (var control) => control <= argument;
    }
    return (_) => false;
  }

  /// Construct a `Condition` based on set checks
  Condition<num> constructSetCondition(
      Operation operation, Iterable<num> arguments) {
    switch (operation) {
      case Operation.In:
        return (var control) => arguments.contains(control);
      case Operation.NotIn:
        return (var control) => !arguments.contains(control);
      case Operation.InRange:
        return (var control) => isInRange(
              control,
              arguments.elementAt(0),
              arguments.elementAt(1),
            );
      case Operation.NotInRange:
        return (var control) => !isInRange(
              control,
              arguments.elementAt(0),
              arguments.elementAt(1),
            );
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

// ignore_for_file: missing_enum_constant_in_switch
