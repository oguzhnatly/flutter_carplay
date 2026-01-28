## 1.2.10

- Add `@objc(FlutterCarPlaySceneDelegate)` annotation for iOS 26 compatibility (#87)

This enables apps to reference the delegate class as `flutter_carplay.FlutterCarPlaySceneDelegate` in their scene manifest configuration. Required for runtime class discovery via `NSClassFromString`. Thanks @APIUM!

## 1.2.9

- Add missing `@available(iOS 14.0, *)` annotations to `makeUIImage` and `loadUIImageAsync` (#84)

These functions reference `SwiftFlutterCarplayPlugin` which requires iOS 14.0+, so Swift requires the availability annotation to propagate. This was missing since v1.2.5.

## 1.2.8

- Fix build failure on Xcode without iOS 26 SDK (follow up to #84)

The v1.2.7 fix using `#if compiler(>=6.0)` didn't work because Swift 6.0 shipped with Xcode 16 (iOS 18), before iOS 26. Now uses dynamic selector invocation to avoid compile time symbol lookup for `updateImage`.

## 1.2.7

- Fix build failure on Xcode versions without iOS 26 SDK (#84)

The `CPGridButton.updateImage()` API introduced in 1.2.5 is only available in iOS 26+. This caused compile errors on older Xcode versions since `#available` only handles runtime checks, not compile time SDK availability. iOS 26 specific code is now wrapped in `#if compiler(>=6.0)` to ensure older toolchains skip it entirely.

- Fix type mismatch in `updateTabBarTemplates` that prevented compilation

## 1.2.6

- Fix compatibility with Dart's `--obfuscate` flag by using explicit type checks instead of `runtimeType.toString()` (fixes #28)
- Add security policy (SECURITY.md)

## 1.2.5

- Fix main thread image loading crash for CPListItem and CPGridButton in https://github.com/oguzhnatly/flutter_carplay/pull/79 (ty @EArminjon)

This fixes a crash caused by creating UIImage on background threads. Network images are now loaded asynchronously using URLSession, and placeholder images are shown until the actual image loads. For iOS 26+, CPGridButton uses the new `updateImage()` API for async updates.

## 1.2.4

- Fix file URI percent encoding for album art paths with spaces in https://github.com/oguzhnatly/flutter_carplay/pull/82 (ty @APIUM)
- Add `sectionIndexEnabled` option to CPListTemplate for hiding section index letters in https://github.com/oguzhnatly/flutter_carplay/pull/83 (ty @APIUM)

## 1.2.3

- Update tab bar template to support mixed template types in https://github.com/oguzhnatly/flutter_carplay/pull/81

This enhances the tab bar template by enabling support for multiple template types (not just list templates) as tab bar children. Supported template types: CPListTemplate, CPPointOfInterestTemplate, CPGridTemplate, CPInformationTemplate (ty @shihabkandil).

## 1.2.2

**Issues:**
Calling `updateTemplates` or `updateSections` updates the layout correctly when the CarPlay is already active, but fail to do when CarPlay not yet started. Using `updateTemplates` or `updateSections` doesn’t refresh ListItem's handler properly, causing missing callbacks. This results in items showing a loading indicator for several seconds because the end event never fires. 

It's been updated by @EArminjon in https://github.com/oguzhnatly/flutter_carplay/pull/77

**Fixes :**
- Ensure `updateTemplate` and `updateSections` correctly refresh all relevant data and update the `final _super.handler`.
- Reformatted the code.
- Reuse existing `CPTemplate` instances instead of recreating them.
- Renamed variables to improve clarity.

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
