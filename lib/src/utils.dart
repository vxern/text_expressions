/// Extension on `Iterable` providing a `firstWhereOrNull()` function that
/// returns `null` if an element is not found, rather than throw `StateError`.
extension NullSafeAccess<E> on Iterable<E> {
  /// Returns the first element that satisfies the given predicate [test].
  ///
  /// If no elements satisfy [test], the result of invoking the [orElse]
  /// function is returned.
  ///
  /// Unlike `Iterable.firstWhere()`, this function defaults to returning `null`
  /// if an element is not found.
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
