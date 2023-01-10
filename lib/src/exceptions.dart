/// Exception thrown when the parser attempts to process a key that does not
/// exist.
class MissingKeyException implements Exception {
  /// A message describing the missing key error.
  final String message;

  /// The name of the key that was missing.
  final String key;

  /// Creates a new `MissingKeyException` with an error [message] and a [key]
  /// indicating which key was missing.
  const MissingKeyException(this.message, this.key);

  /// Returns a description of this missing key exception.
  @override
  String toString() => '$message: The key $key does not exist.';
}

/// Exception thrown by the parser to indicate an issue with an expression.
class ParserException implements Exception {
  /// A brief description of the parser error.
  final String message;

  /// A more in-depth description of the error.
  final String cause;

  /// Creates a new `ParserException` with a titular [message] and the [cause]
  /// of this exception.
  const ParserException(this.message, this.cause);

  /// Returns a description of this parser exception.
  @override
  String toString() => '$message: $cause';
}
