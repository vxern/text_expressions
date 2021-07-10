import 'package:enum_to_string/enum_to_string.dart';

import 'package:text_expressions/src/symbols.dart';
import 'package:text_expressions/src/tokens.dart';
import 'package:text_expressions/src/utils.dart';

extension BreakIntoCases on List<Token> {
  List<Case> toCases() {
    final List<Case> cases = [];

    for (final token in this.where((token) => token.type == TokenType.Case)) {
      // Split case into operable parts
      final parts = token.content.split(Symbols.caseResultDivider);

      // The first part of a case is the command
      final operationRaw = parts.removeAt(0);

      // The other parts of a case are the result
      final resultRaw = parts.join(Symbols.caseResultDivider);

      var operation = Operation.Equals;
      final parameters = <String>[];
      final result = resultRaw;

      if (operationRaw.contains(Symbols.argumentOpen)) {
        final commandParts = operationRaw.split(Symbols.argumentOpen);
        operation = EnumToString.fromString(Operation.values, commandParts[0]) ?? Operation.Default;
        parameters.addAll(commandParts[1].substring(0, commandParts[1].length - 1).split(','));
      } else {
        parameters.add(operationRaw);
      }

      if (operationRaw == 'Default') {
        operation = Operation.Default;
      }

      cases.add(Case(
        operation: operation,
        parameters: parameters,
        result: result,
      ));
    }

    return cases;
  }
}

/// A representation of a choice in a switch case inside the parser
class Case {
  final Operation operation;
  final List<String> parameters;
  final String result;

  const Case({
    required this.operation,
    required this.parameters,
    required this.result,
  });

  bool matchesCondition(String condition) {
    if (operation == Operation.Default) {
      return true;
    }

    return parameters.any((parameter) {
      if (numericOperations.contains(operation)) {
        if (!Utils.areNumeric(condition, parameter)) {
          return false;
        }

        final subject = double.parse(condition);
        final object = double.parse(parameter);

        switch (operation) {
          case Operation.Greater:
            return subject > object;
          case Operation.GreaterOrEqual:
            return subject >= object;
          case Operation.Lesser:
            return subject < object;
          case Operation.LesserOrEqual:
            return subject <= object;
          default:
            return false;
        }
      }

      switch (operation) {
        case Operation.Equals:
          return parameter == condition;
        case Operation.StartsWith:
          return condition.startsWith(parameter);
        case Operation.EndsWith:
          return condition.endsWith(parameter);
        case Operation.Contains:
          return condition.contains(parameter);
        default:
          return false;
      }
    });
  }
}

/// The instruction associated with a choice
enum Operation {
  Default, // Fallback value
  Equals, // The default command for when no command is present
  StartsWith,
  EndsWith,
  Contains,
  Greater,
  GreaterOrEqual,
  Lesser,
  LesserOrEqual,
}

const List<Operation> numericOperations = const [
  Operation.Greater,
  Operation.GreaterOrEqual,
  Operation.Lesser,
  Operation.LesserOrEqual,
];
