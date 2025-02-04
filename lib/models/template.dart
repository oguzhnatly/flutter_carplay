/// Base class for car play templates
abstract class CPTemplate {
  Map<String, dynamic> toJson();

  String get uniqueId;

  bool hasSameValues(CPTemplate other);
}
