/// A function which returns `true` if the condition for matching the control
/// variable with a `Choice` has been met
typedef Condition<T> = bool Function(T controlVariable);

/// A single `Choice` ('case') inside an `Expression` ('switch statement'). The
/// control variable of the expression is tested against the `Choice` by testing
/// [condition]. If [condition] yields `true`, [result] is parsed and returned
class Choice {
  /// The condition that must be met for this `Choice`'s [result] to be accepted
  /// as the result of the expression in which this `Choice` lies
  final Condition<String> condition;

  /// The 'return value' of this `Choice`
  final String result;

  /// Creates an instance of `Choice` with the [condition] required for this
  /// `Choice` to match and the [result] returned if matched
  Choice({
    required this.condition,
    required this.result,
  });

  /// Returns `true` if the [condition] for this `Choice` being matched with
  /// the control variable yields `true`
  bool isMatch(String controlVariable) => condition(controlVariable);
}

/// Describes how the control variable is matched to the argument/s
enum Operation {
  /// The choice is accepted regardless of the condition
  Default,

  /// The control variable is identical to the argument
  Equals,

  /// The control variable starts with a portion or the entirety of the argument
  StartsWith,

  /// The control variable ends with a portion or the entirety of the argument
  EndsWith,

  /// The control variable contains a portion or the entirety of the argument
  Contains,

  /// The control variable is greater than the argument
  Greater,

  /// The control variable is greater than or equal to the argument
  GreaterOrEqual,

  /// The control variable is lesser than the argument
  Lesser,

  /// The control variable is lesser than or equal to the argument
  LesserOrEqual,

  /// The control variable lies within the list of arguments
  In,

  /// The control variable does not lie within the list of arguments
  NotIn,

  /// The control variable falls in the range described by the arguments
  InRange,

  /// The control variable does not fall in the range described by the arguments
  NotInRange,
}
