import 'package:text_expressions/src/parser.dart';
import 'package:text_expressions/src/symbols.dart';
import 'package:text_expressions/src/tokens.dart';

/// A signature for a function that will return `true` if the condition for
/// matching the control variable with a `Choice` has been met, and `false`
/// otherwise.
typedef Condition<T> = bool Function(T controlVariable);

/// A single `Choice` (case) within an `Expression` (switch statement). The
/// control variable of the expression is tested against the `Choice` by testing
/// [condition]. If [condition] yields true, [result] is parsed and returned.
class Choice {
  /// The condition that must be met for this `Choice`'s [result] to be accepted
  /// as the result of the expression in which this `Choice` lies.
  final Condition<String> condition;

  /// The 'return value' of this `Choice`.
  final String result;

  /// Creates an instance of `Choice` with the [condition] required for this
  /// `Choice` to match and the [result] returned if matched.
  Choice({required this.condition, required this.result});

  /// Returns true if the [condition] for this `Choice` being matched with
  /// the control variable yields true.
  bool isMatch(String controlVariable) => condition(controlVariable);
}

/// Defines the method by which the control variable is checked against a
/// condition.
enum Matcher {
  /// Always matches. This matcher acts as a fallback for when no other case has
  /// matched.
  always('Default', aliases: {'Always', 'Fallback', 'Otherwise'}),

  /// The argument is identical to the control variable.
  equals('Equals', aliases: {'=', '=='}),

  /// The control variable string starts with the same sequence of characters
  /// as the argument.
  startsWith('StartsWith'),

  /// The control variable string ends with the same sequence of characters as
  /// the argument.
  endsWith('EndsWith'),

  /// The control variable string contains with the same sequence of characters
  /// as the argument.
  contains('Contains'),

  /// The control variable is greater than the argument.
  ///
  /// If the argument is not numeric, the character(s) of the argument and the
  /// control variable will be compared by codepoint instead.
  isGreater('IsGreater', aliases: {'Greater', 'GT', 'GTR', '>'}),

  /// The control variable is greater than or equal to the argument.
  ///
  /// If the argument is not numeric, the character(s) of the argument and the
  /// control variable will be compared by codepoint instead.
  isGreaterOrEqual(
    'IsGreaterOrEqual',
    aliases: {'GreaterOrEqual', 'GTE', '>='},
  ),

  /// The control variable is lesser than the argument.
  ///
  /// If the argument is not numeric, the character(s) of the argument and the
  /// control variable will be compared by codepoint instead.
  isLesser('IsLesser', aliases: {'Lesser', 'LS', 'LSS', '<'}),

  /// The control variable is lesser than or equal to the argument.
  ///
  /// If the argument is not numeric, the character(s) of the argument and the
  /// control variable will be compared by codepoint instead.
  isLesserOrEqual('IsLesserOrEqual', aliases: {'LesserOrEqual', 'LSE', '<='}),

  /// The control variable lies within the provided list of arguments.
  isInGroup('IsInGroup', aliases: {'IsIn', 'In', 'InGroup'}),

  /// The control variable does not lie within the provided list of arguments.
  isNotInGroup(
    'IsNotInGroup',
    aliases: {'IsNotIn', 'NotIn', '!In', 'NotInGroup', '!InGroup'},
  ),

  /// The control variable falls in the range expression specified as the
  /// argument.
  isInRange('IsInRange', aliases: {'InRange'}),

  /// The control variable does not fall in the range expression specified as
  /// the argument.
  isNotInRange('IsNotInRange', aliases: {'NotInRange', '!InRange'});

  /// The name of this matcher, as defined in the phrase getting parsed.
  final String name;

  /// Aliases for this matcher.
  final Set<String> aliases;

  /// Creates a `Matcher`.
  const Matcher(this.name, {this.aliases = const {}});

  /// Taking a [string], attempts to resolve it to a `Matcher` by checking if it
  /// matches the name of a particular matcher, or alternatively if it uses one
  /// of the defined aliases.
  static Matcher? fromString(String string) {
    for (final matcher in Matcher.values) {
      if (matcher.name == string) {
        return matcher;
      }

      if (matcher.aliases.contains(string)) {
        return matcher;
      }
    }

    return null;
  }
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
      return (var control) => arguments.any((argument) => control == argument);

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
