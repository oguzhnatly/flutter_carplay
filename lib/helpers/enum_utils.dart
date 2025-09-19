class EnumUtils {
  const EnumUtils();

  static T enumFromString<T>(Iterable<T> values, String string) {
    return values.firstWhere(
      (f) =>
          f
              .toString()
              .substring(f.toString().indexOf('.') + 1)
              .toString()
              .toUpperCase() ==
          string.substring(string.indexOf('.') + 1).toString().toUpperCase(),
    );
  }

  static String stringFromEnum(Object value) {
    return value.toString().split('.').last;
  }
}
