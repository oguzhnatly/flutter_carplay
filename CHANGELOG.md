## 1.2.1

- Update tabBar templates in https://github.com/oguzhnatly/flutter_carplay/pull/71

This allow updating a tabBar without removing entire stack. This is useful to add, update or remove tabs.

**Bug fixes :**
- Ensure that updateSections only recreate necessary entries.
- Ensure that updateSections take and memorise new entries (by using List.from).

## 1.2.0

- Add early support for Android Auto under a new controller `FlutterAndroidAuto`. Not all features are supported yet, see the README for more details. ([#71](https://github.com/oguzhnatly/flutter_carplay/pull/71)) (ty @EArminjon).
- History have been reworked to ensure that all templates are well ordered, presents and synchronized.
- Rename some classes to avoid confusion between Android Auto and CarPlay (breaking change)
  - `CPConnectionStatusTypes` -> `ConnectionStatusTypes`
  - `CPEnumUtils` -> `EnumUtils`

## 1.1.3

- Documentation and packaging improvements
- Automated publishing setup with GitHub Actions

## 1.1.1

- Add automated publishing support to pub.dev

## 1.1.0

- Add showNowPlaying, it can be called multiple times safely ([#33](https://github.com/oguzhnatly/flutter_carplay/issues/33)) (ty @vanlooverenkoen, @EArminjon)
- Add support for HTTP(s) images (ty @vanlooverenkoen)
- Add support to launch CarPlay without manually launch the iOS app ([#25](https://github.com/oguzhnatly/flutter_carplay/pull/25)) (ty @vanlooverenkoen)
- Update the iOS integration and its doc to fix various issues ([#17](https://github.com/oguzhnatly/flutter_carplay/issues/17), [#35](https://github.com/oguzhnatly/flutter_carplay/issues/35), [#38](https://github.com/oguzhnatly/flutter_carplay/issues/38), [#61](https://github.com/oguzhnatly/flutter_carplay/issues/61), [#67](https://github.com/oguzhnatly/flutter_carplay/issues/67)) (ty @EArminjon, @snipd-mikel)

## 1.0.3

- Build fix for the issue [#7](https://github.com/oguzhnatly/flutter_carplay/issues/7)

## 1.0.2+1

- Point Of Interest and Information Template added. Previews added to README.md.

## 1.0.2

- Point Of Interest and Information Template added.

## 1.0.1

- CarPlay List Template issue #4 fixed.

## 1.0.0+1

- Initial release of Flutter Apple CarPlay Package. Previews added to README.md.

## 1.0.0

- Initial release of Flutter Apple CarPlay Package.
