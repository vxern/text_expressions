/// Extension with a superior implementation of the problematic `.firstWhere()`,
/// which defaults to throwing a `StateError`, rather than returning `null`
extension NullSafety<E> on Iterable<E> {
  /// Returns the first element that satisfies the given predicate [test]
  ///
  /// If no elements satisfy [test], the result of invoking the [orElse]
  /// function is returned
  ///
  /// Unlike `.firstWhere()`, this function defaults to returning `null`
  E? firstWhereOrNull(bool Function(E) test, {E Function()? orElse}) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    if (orElse != null) {
      return orElse();
    }
    return null;
  }
}
