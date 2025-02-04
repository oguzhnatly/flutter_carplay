/// Provides utility methods for managing enums.
class CPEnumUtils {
  /// Converts a string into an enum type.
  static T enumFromString<T>(Iterable<T> values, String string) {
    return values.firstWhere((f) {
      return f
              .toString()
              .substring(f.toString().indexOf('.') + 1)
              .toString()
              .toUpperCase() ==
          string.substring(string.indexOf('.') + 1).toString().toUpperCase();
    });
  }
}
