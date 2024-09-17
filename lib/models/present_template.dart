import '../flutter_carplay.dart';

/// A template object that represents a base present template.
abstract class CPPresentTemplate extends CPTemplate {
  final bool isDismissible;
  final String? routeName;

  CPPresentTemplate({this.isDismissible = true, this.routeName});
}
