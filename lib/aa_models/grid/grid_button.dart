import 'package:uuid/uuid.dart';

/// A single cell in an [AAGridTemplate].
///
/// Each button shows a [titleVariants] label and an optional [image].
/// The first element of [titleVariants] is used as the primary title on
/// Android Auto (Car App Library shows the most appropriate variant
/// according to available space).
class AAGridButton {
  /// Unique id of the object.
  final String _elementId;

  /// Label variants displayed beneath the cell image. Must not be empty.
  final List<String> titleVariants;

  /// Imagem exibida dentro da célula do grid. Suporta três formatos:
  /// - **Asset** (pubspec.yaml): `'images/logo.png'`
  /// - **Arquivo local**: `'file:///path/to/image.png'`
  /// - **URL de rede**: `'https://example.com/image.png'`
  ///
  /// Falls back to a default icon when null or when the load fails.
  final String? image;

  /// Texto exibido como título da tela de loading enquanto o [onPress] é
  /// executado (até que [complete] seja chamado). Quando nulo, o loading
  /// não exibe título.
  final String? loadingMessage;

  /// Callback fired when the user taps this button.
  ///
  /// - `complete` deve ser chamado após o processamento para remover o loading
  ///   e reconstruir o template — idêntico ao comportamento do [AAListItem].
  /// - `self` é a referência ao próprio botão pressionado.
  final Function(Function() complete, AAGridButton self)? onPress;

  AAGridButton({
    required this.titleVariants,
    this.image,
    this.loadingMessage,
    this.onPress,
  })  : assert(titleVariants.isNotEmpty, 'titleVariants must not be empty'),
        _elementId = const Uuid().v4();

  String get uniqueId => _elementId;

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'titleVariants': titleVariants,
        'image': image,
        'loadingMessage': loadingMessage,
        'onPress': onPress != null,
      };
}
