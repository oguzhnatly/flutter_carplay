import '../../constants/private_constants.dart';
import 'message_template_base.dart';

class AAMessageTemplate extends AAMessageTemplateBase {
  /// Creates a message template for Android Auto.
  ///
  /// [message] must not be empty because Android Auto requires a non-empty
  /// message when building the native template.
  AAMessageTemplate({required super.title, required super.message, super.id});

  @override
  FAAChannelTypes get updateChannelType =>
      FAAChannelTypes.updateMessageTemplate;
}
