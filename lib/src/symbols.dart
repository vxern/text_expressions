/// List of symbols' characters used and understood by the `Lexer`.
class Symbols {
  /// Opening bracket of an external phrase.
  static const ExternalOpen = '<';

  /// Closing bracket of an external phrase.
  static const ExternalClosed = '>';

  /// Opening bracket of an expression.
  static const ExpressionOpen = '[';

  /// Closing bracket of an expression.
  static const ExpressionClosed = ']';

  /// Opening bracket of a parameter designator.
  static const ParameterOpen = '{';

  /// Closing bracket of a parameter designator.
  static const ParameterClosed = '}';

  /// Separates the control variable and the choices inside an expression.
  static const ChoiceIntroducer = '~';

  /// Separates the choices inside an expression.
  static const ChoiceSeparator = '/';

  /// Separates the condition for matching a choice with the control variable
  /// and the result of the matching.
  static const ChoiceResultDivider = ':';

  /// Opening bracket of the arguments used by the operation in constructing a
  /// condition.
  static const ArgumentOpen = '(';

  /// Closing bracket of the arguments used by the operation in constructing a
  /// condition.
  static const ArgumentClosed = ')';
}

/// Enumerator representation of characters used in tokenising a string.
enum SymbolType {
  /// Opening bracket of an external phrase.
  ExternalOpen,

  /// Closing bracket of an external phrase.
  ExternalClosed,

  /// Opening bracket of an expression.
  ExpressionOpen,

  /// Closing bracket of an expression.
  ExpressionClosed,

  /// Opening bracket of a parameter designator.
  ParameterOpen,

  /// Closing bracket of a parameter designator.
  ParameterClosed,

  /// Separates the control variable and the choices inside an expression.
  ChoiceIntroducer,

  /// Separates the choices inside an expression.
  ChoiceSeparator,

  /// Symbol indicating the end of a string.
  EndOfString,
}

/// Representation of a character significant to the tokenisation of a string by
/// splitting it into its `Token` components by the `Lexer`.
class Symbol {
  /// The [type] of this `Symbol` which describes what `Token` this symbol is a
  /// component of.
  final SymbolType type;

  /// Zero-based index of the `Symbol` inside the parent string.
  final int position;

  /// Creates an instance of `Symbol` assigning a [type] and its [position]
  /// inside the string which is being parsed.
  const Symbol(this.type, this.position);
}
