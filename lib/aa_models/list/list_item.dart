import 'package:uuid/uuid.dart';

class AAListItem {
  /// Unique id of the object.
  final String _elementId;

  final String title;
  final String? subtitle;
  /// Imagem exibida na região à esquerda do item. Suporta três formatos:
  /// - **Asset** (pubspec.yaml): `'images/logo.png'`
  /// - **Arquivo local**: `'file:///path/to/image.png'`
  /// - **URL de rede**: `'https://example.com/image.png'`
  final String? image;

  /// Text displayed as the header of the loading screen while the item's
  /// [onPress] handler is executing (until [complete] is called).
  ///
  /// When null the loading screen shows no title.
  final String? loadingMessage;

  final Function(Function() complete, AAListItem self)? onPress;

  AAListItem({
    required this.title,
    this.subtitle,
    this.image,
    this.loadingMessage,
    this.onPress,
  }) : _elementId = const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'title': title,
        'subtitle': subtitle,
        'image': image,
        'loadingMessage': loadingMessage,
        'onPress': onPress != null ? true : false,
      };
}
