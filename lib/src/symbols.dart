/// Enumerator representation of characters used in tokenising a string.
enum Symbol {
  /// Opening bracket of a parameter designator.
  parameterOpen('{'),

  /// Closing bracket of a parameter designator.
  parameterClosed('}'),

  /// Opening bracket of an external phrase.
  externalOpen('<'),

  /// Closing bracket of an external phrase.
  externalClosed('>'),

  /// Opening bracket of an expression.
  expressionOpen('['),

  /// Closing bracket of an expression.
  expressionClosed(']'),

  /// Separates the control variable and the choices inside an expression.
  choiceIntroducer('~'),

  /// Separates the choices inside an expression.
  choiceSeparator('/'),

  /// Separates the condition for matching a choice with the control variable
  /// and the result of the matching.
  choiceResultDivider(':'),

  /// Opening bracket of the arguments used by the matcher in constructing a
  /// condition.
  argumentOpen('('),

  /// Closing bracket of the arguments used by the matcher in constructing a
  /// condition.
  argumentClosed(')'),

  /// Symbol indicating the end of a string.
  endOfString('');

  /// The character representing this `SymbolType`.
  final String character;

  /// Creates a `SymbolType` with the [character] that represents it.
  const Symbol(this.character);

  /// Taking a [character], attempts to resolve it to the `Symbol` that is
  /// represented by the character. Otherwise, returns `null`.
  static Symbol? fromCharacter(String character) {
    for (final symbol in Symbol.values) {
      if (symbol.character == character) {
        return symbol;
      }
    }
    return null;
  }
}

/// Represents an object of type `T` with an additional [position] relative to
/// its parent object.
class WithPosition<T> {
  /// The stored object.
  final T object;

  /// Position relative to the parent object of [object].
  final int position;

  /// Creates an instance of `WithPosition` with the given [object] and its
  /// [position] relative to its parent object.
  const WithPosition(this.object, this.position);
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
