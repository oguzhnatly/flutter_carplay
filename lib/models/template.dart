import 'alert/alert_action.dart';

abstract interface class CPTemplate {
  const CPTemplate();

  String get uniqueId;

  Map<String, dynamic> toJson();
}

abstract interface class CPActionsTemplate {
  const CPActionsTemplate();

  List<CPAlertAction> get actions;
}
