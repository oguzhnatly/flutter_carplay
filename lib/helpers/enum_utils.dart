class CPEnumUtils {
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

  static String stringFromEnum(dynamic value) {
    return value.toString().split('.').last;
  }
}
