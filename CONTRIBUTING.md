# Contributing

Contributions and reviews are welcome. Keep changes focused on an issue and include a runnable example for new public APIs.

## Dart checks

Use a Flutter SDK satisfying `pubspec.yaml`, currently Flutter 3.44 or later with Dart 3.12. Resolve dependencies, format changed Dart files, analyze, and run the full package and example suites:

```sh
flutter pub get
dart format lib test example/lib example/test
flutter analyze
flutter test
cd example
flutter pub get
flutter analyze
flutter test
```

Add regression coverage before fixing a defect. Test public exports, serialized field names, invalid input, rejected native operations and lifecycle transitions. Mock platform channels at the Flutter boundary when the host framework cannot run in a Dart test. Such tests do not establish native presentation or audio behavior.

## Native code and platform contracts

Place iOS Swift sources under `ios/flutter_carplay/Sources/flutter_carplay`. Swift Package Manager uses that directory, and the CocoaPods source glob includes it too. Keep both integration paths buildable. Match Dart method names, runtime type names, identifiers and event payloads exactly with Swift. Use safe input parsing and return a method result exactly once on every path.

Check the current Apple guide, API documentation and SDK headers. Distinguish API availability from the app's approved CarPlay category. Use compiler guards for symbols missing from older SDKs and runtime guards for newer iOS behavior. Do not pass modal templates into root, tab or navigation stacks. Reject unsupported input instead of silently truncating it.

Treat disconnect, dismissal, failed presentation and asynchronous work as normal states. Clear reservations on failure. Prevent stale image or service completions from reopening a closed session. Keep audio capture and speech provider dependencies out of the template package.

From the example directory, build the native integrations affected by your change:

```sh
flutter build ios --simulator --debug
flutter build apk --debug
```

For iOS, verify both the CocoaPods example and a Swift Package Manager consumer when changing source placement or native dependencies. Use the scheme, device and approved entitlements appropriate to the template. Confirm actual presentation, state changes, controls, dismissal and reconnect in CarPlay Simulator or a vehicle. For visual changes, include screenshots of the integrated example and describe the checked configuration. Verify light and dark appearance, long titles, different display sizes and accessibility settings. For audio changes, test permissions, interruptions, background transitions and the actual vehicle input and output route independently from template rendering.

## Documentation

Document every public API, return value, error, lifecycle callback and platform requirement. Update README examples, the support list and CHANGELOG together. Keep example dependencies and permissions scoped to the example. Describe which behavior is verified by automated tests and which requires a native host or vehicle. Never put credentials, generated build output or local diagnostic files into a contribution.
