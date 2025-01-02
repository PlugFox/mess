/// Returns `true` if the generic types of `List<A>` and `List<B>` match.
bool matchGenerics<A, B>() => List<A>.empty(growable: false) is List<B>;
