class Pair<T1, T2> {
  final T1 first;
  final T2 second;

  const Pair(this.first, this.second);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Pair<T1, T2>) return false;
    return first == other.first && second == other.second;
  }

  @override
  int get hashCode => Object.hash(first, second);

  @override
  String toString() {
    return 'Pair($first, $second)';
  }
}
