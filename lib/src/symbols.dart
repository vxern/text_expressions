class Symbols {
  static const String externalOpen = '<';
  static const String externalClosed = '>';
  static const String expressionOpen = '[';
  static const String expressionClosed = ']';
  static const String parameterOpen = '{';
  static const String parameterClosed = '}';
  static const String caseIntroducer = '~';
  static const String caseDivider = '/';
  static const String caseResultDivider = ':';
  static const String argumentOpen = '(';
  static const String argumentClosed = ')';
}

extension BreakIntoSymbols on String {
  List<Symbol> toSymbols() {
    final List<Symbol> symbols = [];

    for (int position = 0; position < this.length; position++) {
      final SymbolType? symbolType;

      switch (this[position]) {
        case Symbols.externalOpen:
          symbolType = SymbolType.externalOpen;
          break;
        case Symbols.externalClosed:
          symbolType = SymbolType.externalClosed;
          break;
        case Symbols.expressionOpen:
          symbolType = SymbolType.expressionOpen;
          break;
        case Symbols.expressionClosed:
          symbolType = SymbolType.expressionClosed;
          break;
        case Symbols.parameterOpen:
          symbolType = SymbolType.parameterOpen;
          break;
        case Symbols.parameterClosed:
          symbolType = SymbolType.parameterClosed;
          break;
        case Symbols.caseIntroducer:
          symbolType = SymbolType.choiceIntroducer;
          break;
        case Symbols.caseDivider:
          symbolType = SymbolType.choiceDivider;
          break;
        default:
          symbolType = null;
          break;
      }

      if (symbolType != null) {
        symbols.add(Symbol(symbolType, position));
      }
    }

    symbols.add(Symbol(SymbolType.endOfString, this.length - 1));

    return symbols;
  }
}

/// A representation of a `Symbol` significant for breaking a string into `Tokens`
class Symbol {
  final SymbolType type;
  final int position;

  const Symbol(this.type, this.position);
}

/// The type of a `Symbol` which decides how the string will be broken into `Tokens`
enum SymbolType {
  externalOpen,
  externalClosed,
  expressionOpen,
  expressionClosed,
  parameterOpen,
  parameterClosed,
  choiceIntroducer,
  choiceDivider,
  endOfString,
}
