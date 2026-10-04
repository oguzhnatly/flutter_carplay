# Flutter CarPlay example

The default `lib/main.dart` demonstrates existing CarPlay and Android Auto templates. Its iOS target keeps the parking entitlement for the Point of Interest examples.

Use Flutter 3.44.2 with Dart 3.12, matching `.fvmrc` and CI. Run `flutter pub get` before building.

## Voice conversation

`lib/voice_control_main.dart` is a separate iOS entry point for an approved voice based conversational app on iOS 26.4 or later. It opens the native voice interface when CarPlay launches. Recording begins only after a microphone action and permission approval. Recognition text stays on iPhone; CarPlay shows activity states and responses are spoken.

The example composes `speech_to_text` and `flutter_tts`; neither is a dependency of the template package. Microphone and speech usage descriptions are included in `ios/Runner/Info.plist`. Configure permissions before driving, and use a provisioning profile with the app category Apple approved.

Build the simulator configuration without changing the parking default:

```sh
flutter pub get
flutter build ios --config-only --simulator --debug --target lib/voice_control_main.dart
cd ios
pod install
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug \
  -sdk iphonesimulator FLUTTER_TARGET=lib/voice_control_main.dart \
  CARPLAY_ENTITLEMENTS_FILE=Conversational.entitlements
```

`CARPLAY_ENTITLEMENTS_FILE` is consumed only by the app target. Do not override `CODE_SIGN_ENTITLEMENTS` globally, because that also changes embedded frameworks.

Voice playback follows native completion, cancellation and error events, rather than treating the speak method acknowledgement as completion. Cleanup owns both audio providers, waits for an active utterance to end, and explicitly deactivates the shared audio session. Foreground presentation waits for that cleanup; a subsequent disconnect or disposal invalidates the pending presentation. A rejected processing or ready transition uses the error state, which keeps the microphone available. The Cancel navigation action remains available if CarPlay also rejects the error state.

The pinned providers send terminal events without session or utterance identifiers. The example serializes teardown before reuse and guards callbacks belonging to an older operation. It cannot identify an arbitrarily duplicated native event delivered after a later utterance has begun. On iOS, TTS cancellation does not complete an awaited speak result, and the stop acknowledgement precedes the cancellation event. A missing terminal event cannot safely be replaced with a timeout that permits another utterance. The iOS TTS implementation does not emit a speech error event; rejected configuration and method results are checked separately. TTS completion with ducking notifies other audio sessions; the provider's explicit deactivation API used after cancellation or error does not expose that notification option. Other audio resumption and vehicle routing therefore require native host verification.

The native template can be checked in CarPlay Simulator. Vehicle microphone routing, Bluetooth or USB behavior, and audio interruptions require a real host and must be checked separately. The template does not provide Siri activation or microphone audio itself.

## Checks

```sh
flutter analyze
flutter test
flutter build ios --simulator --debug
flutter build apk --release
```

See the root README for the public API, lifecycle callbacks, limits and errors, and CONTRIBUTING for platform and verification standards.
