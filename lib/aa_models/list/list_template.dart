import 'package:uuid/uuid.dart';

import '../template.dart';
import 'list_section.dart';

class AAListTemplate implements AATemplate {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final List<AAListSection> sections;

  /// An array of title variants displayed when the list is empty.
  ///
  /// Android Auto uses the first element as the message passed to
  /// `ItemList.Builder.setNoItemsMessage()`. When [sections] is empty and
  /// this list is null, the template falls back to a loading indicator.
  final List<String>? emptyViewTitleVariants;

  /// Label displayed on the tab bar item when this template is used as a tab
  /// inside an [AATabBarTemplate]. Falls back to [title] when not set.
  final String? tabTitle;

  /// Ícone exibido na aba quando este template é usado dentro de um
  /// [AATabBarTemplate]. Aceita três formatos:
  ///
  /// - **Nome de ícone do sistema** (ex: `"star"`, `"map"`) — mapeado para
  ///   um [CarIcon] built-in do Car App Library.
  /// - **Asset Flutter** (ex: `"images/logo.png"`) — carregado via
  ///   `AssetManager` do APK.
  /// - **Arquivo local** (ex: `"file:///path/to/icon.png"`) — lido do disco.
  /// - **URL de rede** (ex: `"https://example.com/icon.png"`) — download async.
  ///
  /// Quando [iconUrl] também está definido, [iconUrl] tem prioridade.
  final String? systemIcon;

  /// URL of an image to use as the tab bar icon. Loaded asynchronously.
  /// Takes precedence over [systemIcon] when set.
  final String? iconUrl;

  AAListTemplate({
    required this.title,
    required this.sections,
    this.emptyViewTitleVariants,
    this.tabTitle,
    this.systemIcon,
    this.iconUrl,
  }) : _elementId = const Uuid().v4();

  @override
  String get uniqueId => _elementId;

  @override
  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'sections':
            sections.map((AAListSection section) => section.toJson()).toList(),
        'emptyViewTitleVariants': emptyViewTitleVariants,
        'tabTitle': tabTitle,
        'systemIcon': systemIcon,
        'iconUrl': iconUrl,
      };
}
