## 2.0.0 (Work in progress)

- Additions:
  - Exceptions:
    - `MissingKeyException` - Thrown when a key is not present.
    - `ParserException` - Thrown at various points during the parsing of
      expressions.
- Changes:
  - Removed `sprint` dependency.
    - BREAKING: Instead of logging an error, the package will now throw an
      exception.
  - Improved enums:
    - The members of all enums have been converted to `camelCase`.
  - 'Operations' have been renamed to 'matchers'.
    - Several matchers were renamed and/or received aliases:
      - `Default` is now known as `always` in the private API.
        - `Always`, `Fallback` and `Otherwise` are now synonymous with
          `Default`.
      -
        - `=` and `==` are now synonymous with `Equals`.
      - `Greater` has been renamed to `IsGreater`.
        - `Greater`, `GT`, `GTR` and `>` are now synonymous with `IsGreater`.
      - `GreaterOrEqual` has been renamed to `IsGreaterOrEqual`.
        - `GreaterOrEqual`, `GTE` and `>=` are now synonymous with
          `IsGreaterOrEqual`.
      - `Lesser` has been renamed to `IsLesser`.
        - `Lesser`, `LS`, `LSS` and `<` are now synonymous with `IsLesser`.
      - `LesserOrEqual` has been renamed to `IsLesserOrEqual`.
        - `LesserOrEqual`, `LSE` and `<=` are now synonymous with
          `IsLesserOrEqual`.
      - `In` has been renamed to `IsInGroup`.
        - `In`, 'IsIn' and 'InGroup' are now synonymous with `IsInGroup`.
      - `NotIn` has been renamed to `IsNotInGroup`.
        - `NotIn`, `!In`, `IsNotIn`, `NotInGroup` and `!InGroup` are now
          synonymous with `IsNotInGroup`.
      - `InRange` has been renamed to `IsInRange`.
        - `InRange` is now synonymous with `IsInRange`.
      - `NotInRange` has been renamed to `IsNotInRange`.
        - `NotInRange` and `!InRange` are now synonymous with `IsNotInRange`.
  - Reorganised project:
    - Removed `lexer.dart`, moving the declarations therein to:
      - `choices.dart`: `getChoices()`, `constructCondition()`,
        `constructMathematicalCondition()`, `constructSetCondition()`,
        `isNumeric()`, `isInRange()`.
      - `symbols.dart`: `getSymbols()`.
      - `tokens.dart`: `getTokens()`.
    - Reduced `Token` to a simple data class by:
      - Removing unused funtions: `isExternal()`.
      - Moving its parser-related methods into `parser.dart`:
        - Into `Parser`: `parse()` (as `parseToken()`), `parseExternal()`,
          `parseExpression()`, `parseParameter()`, `parsePositionalParameter()`.
        - As standalone functions: `isExpression()`, `isInteger()`.
    - Renamed declarations of `Parser`:
      - `parseKey()` -> `process()`.
      - `parse()` -> `_process()`.
      - `parseToken()` -> `_parseToken()`.
      - `parseExternal()` -> `_processExternalClause()`.
      - `parseExpression()` -> `_processExpressionClause()`.
      - `parseParameter()` -> `_processParameterClause()`.
      - `parsePositionalParameter()` -> `_processPositionalParameter()`.

## 1.2.0

- Updated SDK version from `2.12.0` to `2.17.0`.
- Removed `enum_as_string` package.

## 1.1.1+2

- Updated project description (again).

## 1.1.1+1

- Updated project description to fit Dart file conventions.

## 1.1.1

- Made full stops at the end of documentation comments consistent.

## 1.1.0+1

- Updated:
  - Package description.
  - Package dependencies.
  - Translations.

## 1.1.0

- Updated license bearer from 'Dorian Oszczęda' to 'WordCollector'.
- Introduced the `words` lints ruleset.
- Documented all public fields.
- Formatted files in accordance with the standard expected from other
  WordCollector projects.
- Lowered unnecessarily high SDK constraint to `>=2.12.0`.

## 1.0.1+1

- Fixed introductions of named and positional parameters.

## 1.0.1

- Added `In` and `NotIn` matchers.

## 1.0.0

- Created `text_expressions` from code extracted from the `WordCollector`
  application.
