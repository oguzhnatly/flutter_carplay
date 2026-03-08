class EnumUtils {
  const EnumUtils._();

  static T enumFromString<T extends Enum>(Iterable<T> values, String string) {
    return values.firstWhere(
      (T f) => f.name.toUpperCase() == string.toUpperCase(),
    );
  }
}
