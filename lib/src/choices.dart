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
