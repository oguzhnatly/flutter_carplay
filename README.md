# Flutter CarPlay

<picture>
  <source media="(max-width: 600px)" srcset="https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/banner-dashboard-mobile.webp">
  <img src="https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/banner-dashboard.webp" alt="Flutter CarPlay on a physical dashboard, with the original Apple CarPlay and Android Auto compatibility badges.">
</picture>

**Your Flutter app, on Apple CarPlay and Android Auto.**

Add a native car experience to the Flutter app you already have. `flutter_carplay` brings your app's content and actions to the car's built-in display, with screens you define in Dart and callbacks that connect them to your app.

CarPlay and Android Auto handle the native layouts and vehicle controls. You focus on what drivers can browse, choose and do, using each platform's templates rather than resizing your phone's Flutter UI.

- **Build in Dart.** Create templates, handle selections, and update content through the same package import.
- **Keep each platform native.** Build with CarPlay's `CP` models and Android Auto's `AA` models, while sharing your application's content and business logic.
- **Go beyond a static menu.** Work with navigation, connection events, images, incremental updates, and CarPlay's modal voice states.

[Get the package](https://pub.dev/packages/flutter_carplay) · [Try the example](#example-app) · [Explore templates](#templates) · [Read the wiki](https://github.com/oguzhnatly/flutter_carplay/wiki)

**CarPlay voice control:** voice states, activation, action buttons and dismissal callbacks, with an optional conversational speech example for eligible iOS 26.4 apps. See the [voice catalogue entry](#carplay-voice-control).

Version **1.7.0+2** is the latest published release. **1.7.0+3** is in development with the updated community footer. [Read the changelog](CHANGELOG.md).

## Start with a native screen

```sh
flutter pub add flutter_carplay
```

Create native content in Dart. Keep a controller alive to receive events, then prepare the root during your app's startup:

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

final carplay = FlutterCarplay();

Future<void> prepareCarPlayHome() => FlutterCarplay.setRootTemplate(
  rootTemplate: CPListTemplate(
    title: 'My app',
    sections: [
      CPListSection(items: [
        CPListItem(
          text: 'Saved places',
          detailText: 'Pick up where you left off',
          onPress: (complete, item) async => complete(),
        ),
      ]),
    ],
  ),
);
```

Complete the [platform setup](#installation-and-platform-setup) to connect the app to its car host. Android Auto uses its own `AA` models; the full example below selects the current mobile platform and keeps its event listener alive.

<details>
<summary>Complete Flutter app for CarPlay and Android Auto</summary>

The phone UI remains a normal Flutter app.

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DashboardApp());
}

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  FlutterCarplay? _carplay;
  FlutterAndroidAuto? _androidAuto;
  String _status = ConnectionStatusTypes.unknown.name;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _carplay = FlutterCarplay()
        ..addListenerOnConnectionChange(_connectionChanged);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      _androidAuto = FlutterAndroidAuto()
        ..addListenerOnConnectionChange(_connectionChanged);
    }
    if (_carplay != null) {
      unawaited(_installRoot());
    } else if (_androidAuto != null &&
        FlutterAndroidAuto.connectionStatus ==
            ConnectionStatusTypes.connected.name) {
      _connectionChanged(ConnectionStatusTypes.connected);
    }
  }

  void _connectionChanged(ConnectionStatusTypes status) {
    if (!mounted) return;
    final newlyConnected = status == ConnectionStatusTypes.connected &&
        _status != ConnectionStatusTypes.connected.name;
    setState(() => _status = status.name);
    if (_androidAuto != null && newlyConnected) {
      unawaited(_installRoot());
    }
  }

  Future<void> _installRoot() async {
    try {
      if (_carplay != null) {
        await FlutterCarplay.setRootTemplate(
          rootTemplate: CPListTemplate(
            title: 'On the road',
            sections: [
              CPListSection(items: [
                CPListItem(
                  text: 'Welcome aboard',
                  detailText: 'Tap to update this native row',
                  onPress: (complete, item) async {
                    try {
                      item.setDetailText('Your Flutter app is connected');
                    } finally {
                      await complete();
                    }
                  },
                ),
              ]),
            ],
          ),
        );
      } else if (_androidAuto != null) {
        await FlutterAndroidAuto.setRootTemplate(
          template: AAListTemplate(
            title: 'On the road',
            sections: [
              AAListSection(items: [
                AAListItem(
                  title: 'Welcome aboard',
                  subtitle: 'A native Android Auto row',
                  onPress: (complete, item) async {
                    try {
                      debugPrint('Selected ${item.title}');
                    } finally {
                      await complete();
                    }
                  },
                ),
              ]),
            ],
          ),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) setState(() => _status = error.message ?? error.code);
    }
  }

  @override
  void dispose() {
    _carplay?.removeListenerOnConnectionChange();
    _carplay?.closeConnection();
    _androidAuto?.removeListenerOnConnectionChange();
    _androidAuto?.closeConnection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Dashboard companion')),
      body: Center(child: Text('Car connection: $_status')),
    ),
  );
}
```

The CarPlay root can be prepared before the car attaches. The Android Auto example waits for `connected` and resubmits its root on reconnect, without rebuilding twice for consecutive connected events. Native tabs and string-based raster artwork need the live Android car context when the template is built. A successful root setter has no Dart boolean result and does not mean a car screen is already visible. Native setup, a compatible host and the app's approved category still determine what can be presented.

</details>

## Find your way

[Platform overview](#platform-overview) · [Installation](#installation-and-platform-setup) · [Usage](#usage) · [Images](#images-and-icons) · [Templates](#templates) · [Example](#example-app) · [Limitations and roadmap](#limitations-and-roadmap) · [Community](#community-and-support)

## Platform overview

![The example's authentic native dashboard interface](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/banner-example.webp)

One Flutter app can support both platforms. The template trees are separate because the native frameworks are separate.

| | Apple CarPlay | Android Auto |
| --- | --- | --- |
| Dart controller | `FlutterCarplay` | `FlutterAndroidAuto` |
| Template family | `CPTemplate` and `CP` models | `AATemplate` and `AA` models |
| Renderer | Apple's CarPlay framework | Android for Cars App Library host |
| Package deployment floor | iOS 14.0 | Android API 21; use the higher minimum required by your Flutter SDK |
| Tabs | List, grid, information, and point-of-interest children | List and grid children; native tabs need Car App API level 6 or later |
| Modal flows | Alerts, action sheets, voice control | Alerts use a full-screen message pushed onto the screen stack |
| Voice | Native indicator and states; newer controls on iOS 26.4 | No voice-control template API |
| Media screen | Opens CarPlay's shared Now Playing template | System-owned media UI; no working package method to open it |

### Android Auto is not Android Automotive OS

Android Auto projects an experience from an Android phone into a compatible car host. Android Automotive OS (AAOS) runs Android directly in the vehicle. Installing a Flutter APK on AAOS and opening its activity displays that app's Flutter UI; it does not make this plugin render Android Auto templates.

Use this package for Android Auto template integration. A standalone AAOS app needs its own vehicle-app design and integration. See Google's [Android for Cars documentation](https://developer.android.com/training/cars/apps) for the distinction and supported app categories.

### Native templates, not arbitrary widgets

Car hosts decide how a template looks and which controls and content are available. Your entitlement or app category can further restrict the templates you may use. Design short, focused flows and handle content limits instead of relying on the phone layout being reproduced in the car.

Apple requires approval for a CarPlay entitlement and matching signing configuration for device use and distribution. Google has category, quality, and distribution requirements for Android Auto apps. Installing the package does not approve an app for either platform.

[Apple CarPlay Developer Guide](https://developer.apple.com/download/files/CarPlay-Developer-Guide.pdf) · [Apple design guidance](https://developer.apple.com/design/human-interface-guidelines/carplay) · [Android Auto template design](https://developer.android.com/design/ui/cars/guides/templates/overview)

## Installation and platform setup

### Add the dependency

Use Flutter **3.44.0 or later** and Dart **3.12.0 or later, below 4.0.0**. The repository example and CI use Flutter 3.44.2.

```sh
flutter pub add flutter_carplay
```

To use the latest published release or a compatible update:

```yaml
dependencies:
  flutter_carplay: ^1.7.0+2
```

All public models and both controllers are available from `package:flutter_carplay/flutter_carplay.dart`. There is no speech-recognition or TTS dependency in the package itself.

### CarPlay setup

<img src="https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/carplay-icon.webp" width="40" alt="CarPlay" />

CarPlay uses two scenes backed by one Flutter engine: a phone window and a native CarPlay scene. Follow the example's shared-engine arrangement so the car can launch your app without first opening its phone interface.

#### 1. Set the deployment target

Set the Runner target and relevant build configurations to **iOS 14.0 or later**. For CocoaPods, set this in `ios/Podfile`:

```ruby
platform :ios, '14.0'
```

After resolving Flutter dependencies, run CocoaPods normally:

```sh
flutter pub get
cd ios
pod install
```

The plugin also includes a [Swift Package Manager manifest](ios/flutter_carplay/Package.swift). Use Flutter's supported SwiftPM integration for your project; the plugin manifest expects the Flutter-generated `FlutterFramework` package. Do not independently add a second copy of the plugin alongside CocoaPods.

The iOS deployment target is not the same as the SDK needed to compile newer APIs. Use an Xcode SDK containing the iOS 26 list-image element APIs used by the source. Voice action and navigation buttons specifically need **Xcode 26.4 or later** and **iOS 26.4 or later** at runtime.

#### 2. Start and register the shared engine

In `ios/Runner/AppDelegate.swift`, start the engine during application launch and register plugins against that engine. Adapt existing application hooks rather than registering the same plugins on two engines.

<details>
<summary>Complete shared-engine AppDelegate</summary>

```swift
import UIKit
import Flutter

let flutterEngine = FlutterEngine(
    name: "SharedEngine",
    project: nil,
    allowHeadlessExecution: true
)

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        flutterEngine.run()
        GeneratedPluginRegistrant.register(with: flutterEngine)
        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }
}
```

</details>

#### 3. Attach the phone window to that engine

Add `SceneDelegate.swift` to the Runner target. The phone scene uses the existing engine, not a new engine that would isolate the car's Dart state.

<details>
<summary>Complete phone SceneDelegate</summary>

```swift
import UIKit
import Flutter

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let phoneWindow = UIWindow(windowScene: windowScene)
        let controller = FlutterViewController(
            engine: flutterEngine,
            nibName: nil,
            bundle: nil
        )
        controller.loadDefaultSplashScreenView()
        phoneWindow.rootViewController = controller
        window = phoneWindow
        phoneWindow.makeKeyAndVisible()
    }
}
```

</details>

#### 4. Register both scenes

Merge this `UIApplicationSceneManifest` into `ios/Runner/Info.plist`. The CarPlay delegate name is case-sensitive: **`flutter_carplay.FlutterCarPlaySceneDelegate`**.

<details>
<summary>Scene manifest</summary>

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>CPTemplateApplicationSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>CarPlay Configuration</string>
                <key>UISceneDelegateClassName</key>
                <string>flutter_carplay.FlutterCarPlaySceneDelegate</string>
            </dict>
        </array>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                <key>UISceneStoryboardFile</key>
                <string>Main</string>
            </dict>
        </array>
    </dict>
</dict>
```

</details>

Keep storyboard names aligned with your app. The example uses `Main` for the phone scene and `LaunchScreen` for launch UI. There is no need to relocate Flutter engine files or generated plugin registrants.

#### 5. Choose the approved CarPlay category

[Request CarPlay access from Apple](https://developer.apple.com/contact/carplay), then configure the entitlement, bundle identifier, provisioning profile, and Runner signing settings together. Apple Simulator development is useful before approval, but it does not replace device or distribution approval.

The example's default `Runner.entitlements` uses parking so its point-of-interest demo remains available. Choose your own category; do not copy parking into every app.

| App category | Entitlement key |
| --- | --- |
| Parking | `com.apple.developer.carplay-parking` |
| Maps and navigation | `com.apple.developer.carplay-maps` |
| Quick ordering | `com.apple.developer.carplay-quick-ordering` |
| EV charging | `com.apple.developer.carplay-charging` |
| Fueling | `com.apple.developer.carplay-fueling` |
| Driving tasks | `com.apple.developer.carplay-driving-task` |
| Calling or messaging | `com.apple.developer.carplay-communication` |
| Audio | `com.apple.developer.carplay-audio` |
| Voice-based conversation, iOS 26.4 | `com.apple.developer.carplay-voice-based-conversation` |

This is a category-selection reference, not a promise that every category can use every package template. Check the [current CarPlay guide](https://developer.apple.com/download/files/CarPlay-Developer-Guide.pdf) and [entitlement configuration instructions](https://developer.apple.com/documentation/carplay/requesting-the-carplay-entitlements) before building your template tree. The conversational configuration is covered under [Voice Control](#carplay-voice-control).

### Android Auto setup

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/android-auto-wordmark-light.svg">
  <img src="https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/android-auto-wordmark-dark.svg" width="160" alt="Android Auto">
</picture>

Android Auto launches a `CarAppService` that talks to a host-rendered screen. The service and phone activity should reuse the same cached Flutter engine.

#### 1. Meet the Android build requirements

The plugin has `minSdk = 21`, compiles against Android SDK 35, and depends on `androidx.car.app:app:1.7.0`. Your application must also satisfy the minimum required by Flutter; keep `flutter.minSdkVersion` when that is higher. The plugin does not apply the Kotlin Gradle Plugin itself. Do not add an extra Kotlin plugin application to the library to work around older build instructions.

#### 2. Declare the car service and category

Merge the following into the application's `android/app/src/main/AndroidManifest.xml`. This is the repository example's **media-template** configuration. Select the service category and permissions appropriate to your supported app type using Google's [Android Auto setup guide](https://developer.android.com/training/cars/apps/auto).

<details>
<summary>Android Auto manifest additions</summary>

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature
        android:name="android.software.car.app.library"
        android:required="false"/>
    <uses-permission android:name="androidx.car.app.MEDIA_TEMPLATES"/>

    <application>
        <meta-data
            android:name="com.google.android.gms.car.application"
            android:resource="@xml/automotive_app_desc"/>
        <meta-data
            android:name="androidx.car.app.minCarApiLevel"
            android:value="1"/>
        <service
            android:name="com.oguzhnatly.flutter_android_auto.AndroidAutoService"
            android:exported="true">
            <intent-filter>
                <action android:name="androidx.car.app.CarAppService"/>
                <category android:name="androidx.car.app.category.MEDIA"/>
            </intent-filter>
        </service>
    </application>
</manifest>
```

</details>

Keep your existing activity, application attributes, Flutter embedding metadata, and other permissions. This fragment is not a replacement for the whole application's manifest.

Create `android/app/src/main/res/xml/automotive_app_desc.xml`:

```xml
<automotiveApp xmlns:android="http://schemas.android.com/apk/res/android">
    <uses name="template"/>
</automotiveApp>
```

A template service is not a media playback implementation. Add Google's media-app integration only if your app actually supplies a media service and session. If your app depends on native tabs without fallback, account for their Car App API level 6 requirement rather than relying on the example's minimum API level 1 declaration.

#### 3. Share the cached engine

Use your own application package declaration in `MainActivity.kt`. This complete activity body matches the service's `FAAConstants.flutterEngineId` cache key:

```kotlin
package com.example.flutter_carplay_example

import android.content.Context
import com.oguzhnatly.flutter_android_auto.FAAConstants
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? =
        FlutterEngineCache.getInstance().get(FAAConstants.flutterEngineId)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        FlutterEngineCache.getInstance()
            .put(FAAConstants.flutterEngineId, flutterEngine)
        super.configureFlutterEngine(flutterEngine)
    }
}
```

The car service starts and caches an engine with the default Dart entry point when no cached engine exists. If the phone activity starts first, its engine is cached for the service to reuse. Initialize car-facing application state from app startup, not from a phone-only button or navigation route. Submit Android roots when the connection listener reports `connected`; if a root was prepared earlier, submit it again so native tabs and raster artwork are rebuilt against the live car context.

**Host validation:** the bundled `AndroidAutoService` currently uses `HostValidator.ALLOW_ALL_HOSTS_VALIDATOR`. That is permissive, not a production host allowlist. Review Google's [host-validation guidance](https://developer.android.com/reference/androidx/car/app/validation/HostValidator) and your service configuration before distribution. This package does not currently expose a Dart host-validator configuration API.

## Usage

### Own the controller lifecycle

Static methods send commands. A retained controller instance subscribes to native events and dispatches selections, buttons, connection changes, and CarPlay dismissal callbacks. Keep one long-lived instance for the current platform and remove its listener and close its subscription when its owner is disposed.

| Lifecycle API | Meaning |
| --- | --- |
| `addListenerOnConnectionChange(callback)` | Installs a connection callback on that controller instance; a later call replaces it |
| `removeListenerOnConnectionChange()` | Removes the callback, but does not close the event subscription |
| `pauseConnection()` / `resumeConnection()` | Pauses or resumes event delivery; does not disconnect the vehicle |
| `closeConnection()` | Cancels the event subscription; resuming a cancelled subscription does not recreate it |
| `connectionStatus` | Static **String** containing an enum name, not a `ConnectionStatusTypes` value |
| `rootTemplate` | The Dart-side root retained in template history, not a query of the visible native screen |

Connection callbacks receive `ConnectionStatusTypes`. CarPlay reports `connected`, `background`, and `disconnected`; `unknown` is the initial Dart state. Android Auto's current session emits connected and disconnected events. The shared enum also contains `background`, but do not depend on Android emitting that state in this implementation.

Create only the matching platform controller if you intend to call its lifecycle methods. In particular, Android Auto's subscription methods assume its Android event subscription exists.

<details>
<summary>CarPlay connection listener and cleanup</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

class CarConnection {
  final FlutterCarplay controller = FlutterCarplay();

  CarConnection() {
    controller.addListenerOnConnectionChange((status) {
      debugPrint('CarPlay: ${status.name}');
    });
  }

  bool get connected =>
      FlutterCarplay.connectionStatus == ConnectionStatusTypes.connected.name;

  void dispose() {
    controller.removeListenerOnConnectionChange();
    controller.closeConnection();
  }
}
```

</details>

### Navigation and return values

Prepare the CarPlay root during startup. For Android Auto, submit or resubmit the root after `connected` so context-dependent tabs and raster artwork are built for the live host. Push screens only when the host is connected and a root exists. Keep flows shallow: CarPlay navigation is limited to five templates including the root, and the host/category may impose further restrictions.

A returned `true` means what that particular operation reports, not that every asynchronous transition, download, or app action is finished. Native channel errors can throw `PlatformException`; catch them at your application boundary. Dart-side invalid model arguments may throw `ArgumentError`, `RangeError`, or assertions; an unsupported CarPlay root or push type throws `TypeError`.

#### CarPlay controller API

| Method | Dart result | Use |
| --- | --- | --- |
| `setRootTemplate(rootTemplate:, animated:)` | `Future<void>` | Replace/install a list, grid, tab bar, information, point-of-interest, or search root |
| `push(template:, animated:)` | `Future<bool>` | Push list, grid, information, point-of-interest, or search; not tabs or modals |
| `pop(animated:, count:)` | `Future<bool>` | Pop pushed screens; default count is 1; supply a positive count within the stack depth |
| `popToRoot(animated:)` | `Future<bool>` | Return to the root |
| `showAlert(template:, animated:)` | `Future<void>` | Request an alert; inspect the template's `onPresent(bool)` callback |
| `showActionSheet(template:, animated:)` | `Future<void>` | Request an action sheet; no presentation boolean is exposed |
| `showVoiceControl(template:, animated:)` | `Future<bool>` | Present a modal voice template with native presentation result |
| `activateVoiceControlState(elementId:, identifier:)` | `Future<bool>` | Activate a state on the current voice modal |
| `popModal(animated:)` | `Future<bool>` | Dismiss a modal, or cancel one that is still being prepared |
| `showSharedNowPlaying(animated:)` | `Future<bool>` | Push the system's shared Now Playing instance if it is not already in the stack |

The following are **instance** methods on `FlutterCarplay`:

| Method | Dart result | Use |
| --- | --- | --- |
| `forceUpdateRootTemplate()` | `Future<void>` | Reapply the retained native root |
| `updateListTemplateSections(elementId:, sections:)` | `Future<void>` | Replace a known list's sections |
| `updateInformationTemplateItems(elementId:, items:)` | `Future<void>` | Replace a known information template's items |
| `updateInformationTemplateActions(elementId:, actions:)` | `Future<void>` | Replace its text actions |
| `updateTabBarTemplates(elementId:, templates:)` | `Future<void>` | Update a known tab bar's children without resetting the root |

`setRootTemplate` already requests a native root update, and the CarPlay scene installs the retained root when it connects. `forceUpdateRootTemplate` is available for an explicit refresh; it is not a compulsory second call after every setter. Avoid resetting the root repeatedly during modal presentation or connection callbacks.

CarPlay `push`, `pop`, and `popToRoot` do not wait for an animation-completion callback. A push can return `false` if there is no connected interface or root, and pops can return `false` at the root. The void update methods also do not provide a per-update visible-render confirmation.

#### Android Auto controller API

| Method | Dart result | Use |
| --- | --- | --- |
| `setRootTemplate(template:)` | `Future<void>` | Install list, grid, tabs, pane, message, or long-message content |
| `push(template:)` | `Future<bool>` | Push list, grid, pane, message, or long-message screens |
| `pop()` / `popToRoot()` | `Future<bool>` | Pop screens using the host's screen manager |
| `showAlert(template:)` | `Future<void>` | Push a full-screen alert message; `onPresent(bool)` reports its state |
| `popModal()` | `Future<bool>` | Pop the currently managed alert screen |
| `updateTabBarTemplates(template:)` | `Future<void>` | Rebuild tab content using the supplied tab bar |
| `updatePaneTemplate(template:)` | `Future<bool>` | Replace pane content using the same template ID |
| `showSharedNowPlaying()` | `Future<bool>` | Currently returns `false`; use your app's media integration instead |
| `forceUpdateRootTemplate()` | `Future<void>` | Instance method that invalidates the current root screen |
| `updateListTemplateSections(elementId:, sections:)` | `Future<void>` | Instance method that replaces a known list's sections |

Android Auto commands have no `animated` parameter. Native navigation can throw for a missing car context, popping at the root, or a missing alert instead of returning `false`. Root templates are built immediately: preparing one before a car session exists can select tab fallback content and skip string-based raster artwork. The connected screen reuses that built template, so submit the root again after `connected` if it was prepared early. `forceUpdateRootTemplate` only invalidates the screen; it does not rebuild those context-dependent fields. Pushing and alerts also need a live car context. Await channel calls and handle errors rather than treating completion of a void method as a presentation-success flag.

<details>
<summary>Complete push, pop, and return-to-root functions</summary>

Call these from an app that retains the matching controller and already has a connected root.

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> openCarPlayDetails() => FlutterCarplay.push(
  template: CPListTemplate(
    title: 'Details',
    sections: [
      CPListSection(items: [CPListItem(text: 'Ready to explore')]),
    ],
  ),
  animated: true,
);

Future<bool> backOnCarPlay() => FlutterCarplay.pop(animated: true, count: 1);
Future<bool> homeOnCarPlay() => FlutterCarplay.popToRoot(animated: true);

Future<bool> openAndroidDetails() => FlutterAndroidAuto.push(
  template: AAListTemplate(
    title: 'Details',
    sections: [
      AAListSection(items: [AAListItem(title: 'Ready to explore')]),
    ],
  ),
);

Future<bool> backOnAndroidAuto() => FlutterAndroidAuto.pop();
Future<bool> homeOnAndroidAuto() => FlutterAndroidAuto.popToRoot();
```

</details>

### Finish selection callbacks

`CPListItem`, CarPlay image-row selections, `AAListItem`, and `AAGridButton` callbacks receive a **completion function**. Call it when handling ends, including failed operations, so the host can stop its selection/loading state. Android Auto uses a temporary loading template during list and grid handling; `loadingMessage` provides its title.

Use `try`/`finally` for asynchronous selection work. Do not block Dart's event loop with `sleep` or a busy loop. Simple CarPlay grid buttons, alert actions, text buttons, pane actions, voice buttons, toggles, and section-selection callbacks do not receive that same completion function.

Search has its own callback ordering: `onUpdatedSearchText(text, update)` supplies results; `onSelectedResult(item, complete)` finishes a chosen result. See [Search](#carplay-search).

### Update content without rebuilding everything

Keep template and item IDs stable when updating existing content. Many constructors accept `id:`; otherwise the package generates an ID. Read it with `uniqueId`. This is identity for native lookup and event routing, not an index or a visible label.

For CarPlay rows, methods such as `setText`, `setDetailText`, `setImage`, `setImageTint`, `setTrailingImage`, `setAccessoryImage`, `setPlaybackProgress`, `setIsPlaying`, `setPlayingIndicatorLocation`, `setAccessoryType`, and `update` send item updates. They return `void`; they are not awaitable native acknowledgements. Progress setters accept values from 0.0 through 1.0.

`CPListTemplate.updateSections`, `CPTabBarTemplate.updateTemplates`, and `CPInformationTemplate.updateInformationItems`/`updateActions` mutate the Dart models. To update an already installed native template, use the corresponding controller method. Android Auto follows the same distinction for `AAListTemplate.updateSections` and `AATabBarTemplate.updateTabs`; message models' asynchronous `update`, `setTitle`, and `setMessage` send native updates themselves.

When creating replacements, retain callback-bearing models or supply the new callbacks as well as their stable IDs. Mutating plain Dart collections alone is not a host refresh. Android Auto has no equivalent per-row setter family; replace its list sections instead.

## Images and icons

Use Flutter assets for predictable offline artwork, and raster URLs or local files where the native field supports them. Declare assets in the **consuming app's** `pubspec.yaml`.

The catalogue's asset-backed examples use files already bundled by this repository's example app:

```yaml
flutter:
  assets:
    - images/logo_flutter_1080px_clr.png
    - images/svg_navigation.svg
    - images/svg_media.svg
    - images/svg_poi.svg
    - images/svg_warning.svg
    - images/svg_navigation_glyph.svg
    - images/voice_microphone.svg
```

If you copy a catalogue function into another app, copy and declare those assets too, or replace them with your own declared files. No image asset is required for the opening example.

| Source or field | Behavior |
| --- | --- |
| Raster Flutter assets | Native lookup using the asset key |
| Local `file://` raster images | Available in native image-loader fields; ensure the file exists and is accessible |
| HTTP/HTTPS raster images | Available in native image-loader fields; configure app network permissions and prefer HTTPS |
| Local Flutter asset `.svg` files | Rasterized to PNG before supported image payloads reach the native bridge |
| Remote SVG URLs | Not rasterized by the package; provide a raster image instead |
| `file://` SVGs | Not a supported SVG-asset path; bundle as a Flutter asset or convert to raster first |
| CarPlay POI pin image | Use a Flutter asset or asset SVG; this native path does not use the general URL/file loader |
| Tab `systemIcon` | Not an SVG image field; CarPlay uses native SF Symbols, with image-source fallback on list/grid tabs |
| Android tab `iconUrl` | Native raster image-source lookup; it is not included in the SVG rasterizer's handled keys |

Supported SVG payloads include row images and trailing images, CarPlay grid buttons, POI pins, image-row image collections and elements, Android grid buttons and pane images, and nested voice-state/action images. Both controllers default `svgRasterSize` to 120 pixels; set it before creating image-bearing templates when you need a different raster resolution. A rasterized SVG is static even if the template offers an animation option.

`AutoImageTint` supports `platform`, `primary`, `secondary`, named colors, and custom light/dark colors. Use it for glyphs rather than multicolored artwork. CarPlay pre-renders tinted images; Android uses native `CarColor` metadata, so the host still controls appearance. `selectedSafe` controls the CarPlay contrast treatment; it is not a guarantee of identical selected colors on both platforms.

<details>
<summary>Complete asset and tint example</summary>

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

CPListItem makeNavigationRow() => CPListItem(
  text: 'Saved places',
  image: 'images/svg_navigation_glyph.svg',
  imageTint: const AutoImageTint.custom(
    color: UIColor(red: 20, green: 100, blue: 190),
    darkColor: UIColor(red: 150, green: 205, blue: 255),
  ),
  accessoryType: CPListItemAccessoryType.disclosureIndicator,
  onPress: (complete, item) async {
    try {
      item.setDetailText('Places ready');
    } finally {
      await complete();
    }
  },
);
```

</details>

Most CarPlay list images can appear after their placeholder. Voice presentation is different: it waits for its images, and an image-loading failure rejects presentation. Keep voice images small and readily available. Host artwork limits still apply regardless of how an image was supplied.

## Templates

Start with the catalogue below, then build the platform-specific tree your app category permits. Each Dart block is a complete function or class with its imports. Presentation functions are intended to be called from your integrated app with the matching event controller alive; they do not replace native setup.

### CarPlay templates

![CarPlay's native template overview](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/templates.webp)

| Template | Use | Placement |
| --- | --- | --- |
| [List](#carplay-list) | Content browsing and hierarchical menus | Root, push, tab child |
| [Image row](#carplay-image-rows) | Artwork collections within a list | List item, not a standalone template |
| [Grid](#carplay-grid) | A small set of visual choices | Root, push, tab child |
| [Tabs](#carplay-tabs) | Top-level sections | Root; list, grid, information, and POI children |
| [Information](#carplay-information) | Concise details and text actions | Root, push, tab child |
| [Point of interest](#carplay-point-of-interest) | Places on a native map | Root, push, tab child |
| [Alert](#carplay-alert) | A short status or decision | Modal |
| [Action sheet](#carplay-action-sheet) | Contextual choices or confirmation | Modal |
| [Search](#carplay-search) | Native search field and results | Root or push, not a tab child |
| [Voice control](#carplay-voice-control) | Visual voice states and eligible voice controls | Modal only |
| [Now Playing](#carplay-now-playing) | System media controls | Shared native instance through controller |

#### CarPlay list

![Native CarPlay list](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/list_template.webp)

Use `CPListTemplate` for rows organized into `CPListSection`s. Rows can carry detail text, artwork, an accessory/disclosure indicator, playback progress, and playing status. `sectionIndexEnabled` controls whether a section header participates in the index. Empty-title and subtitle variants provide a useful screen when no sections are present.

The vehicle can reduce how many rows are shown, including a 12-item limit on some hosts. Query `CPListTemplate.getMaximumItemCount()` and `getMaximumSectionCount()` where useful, and put essential content first. These return `Future<int?>`, not a promise that every vehicle presents your entire data set.

<details>
<summary>List with an updating row and back button</summary>

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> openCarPlayLibrary() => FlutterCarplay.push(
  template: CPListTemplate(
    title: 'Library',
    emptyViewTitleVariants: ['Your library'],
    emptyViewSubtitleVariants: ['Save an item on your phone to begin'],
    backButton: CPBarButton(
      title: 'Back',
      buttonStyle: CPBarButtonStyle.none,
      onPress: () => FlutterCarplay.pop(),
    ),
    sections: [
      CPListSection(
        header: 'Saved',
        sectionIndexEnabled: false,
        items: [
          CPListItem(
            id: 'library-featured',
            text: 'Featured collection',
            detailText: 'Available offline',
            image: 'images/logo_flutter_1080px_clr.png',
            playbackProgress: 0.25,
            isPlaying: false,
            playingIndicatorLocation: CPListItemPlayingIndicatorLocation.trailing,
            accessoryType: CPListItemAccessoryType.disclosureIndicator,
            onPress: (complete, item) async {
              try {
                item.update(detailText: 'Selected', isPlaying: true);
              } finally {
                await complete();
              }
            },
          ),
        ],
      ),
    ],
  ),
);
```

</details>

#### CarPlay image rows

`CPListImageRowItem` adds a horizontal image collection to a list section. `onPress(complete, item)` handles the row; `onItemPress(complete, item, index)` handles an image selection. Finish both kinds of selection with their completion callback.

For the classic layout, use `gridImages`, optional per-image `gridImageTints`, and `imageTitles`. Image titles are used on iOS 17.4 or later. Query `CPListImageRowItem.getMaximumNumberOfGridImages()` before building a larger collection; the host can truncate the visible slots.

On iOS 26, `elements` provides five native layouts:

| Dart element | Content |
| --- | --- |
| `CPListImageRowItemCardElement` | Image, optional title/subtitle, card presentation |
| `CPListImageRowItemCondensedElement` | Image and title, optional subtitle/accessory, circular or rounded shape |
| `CPListImageRowItemGridElement` | Image-only grid element |
| `CPListImageRowItemImageGridElement` | Image and title, optional accessory, selectable shape |
| `CPListImageRowItemRowElement` | Image with optional title and subtitle |

Use **one element type per row**: the native initializer selects the layout from the first element and filters for that type. If older iOS versions must show the row, supply `gridImages` as a fallback as well as the newer `elements`. `setText` and `setElements` send row updates; element setters such as `setImage` and `setTitle` send updates on iOS 26. These methods return `void`.

<details>
<summary>Artwork row with an iOS 26 card layout and classic fallback</summary>

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> openCarPlayArtwork() => FlutterCarplay.push(
  template: CPListTemplate(
    title: 'Collections',
    sections: [
      CPListSection(items: [
        CPListImageRowItem(
          text: 'Pick a collection',
          gridImages: [
            'images/svg_navigation.svg',
            'images/svg_media.svg',
          ],
          imageTitles: ['Places', 'Audio'],
          elements: [
            CPListImageRowItemCardElement(
              image: 'images/svg_navigation.svg',
              title: 'Places',
              subtitle: 'Saved for later',
            ),
            CPListImageRowItemCardElement(
              image: 'images/svg_media.svg',
              title: 'Audio',
              subtitle: 'Your collection',
            ),
          ],
          onPress: (complete, item) async => complete(),
          onItemPress: (complete, item, index) async => complete(),
        ),
      ]),
    ],
  ),
);
```

</details>

#### CarPlay grid

![Native CarPlay grid](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/grid_template.webp)

`CPGridTemplate` presents a compact visual menu of up to eight `CPGridButton`s. Supply image assets and title variants. A CarPlay grid button uses `onPress()` without a selection-completion argument.

<details>
<summary>Two-choice grid</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> openCarPlayChoices() => FlutterCarplay.push(
  template: CPGridTemplate(
    title: 'Explore',
    buttons: [
      CPGridButton(
        titleVariants: ['Places'],
        image: 'images/svg_navigation.svg',
        onPress: () => debugPrint('Places selected'),
      ),
      CPGridButton(
        titleVariants: ['Audio'],
        image: 'images/svg_media.svg',
        onPress: () => debugPrint('Audio selected'),
      ),
    ],
  ),
);
```

</details>

In 1.7.0, Dart's CarPlay grid-button event lookup searches directly retained grid templates, not grid children inside a tab bar. Prefer a standalone root/pushed grid when you need its Dart button callback.

#### CarPlay tabs

![Native CarPlay tab bar](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/tabbar_template.webp)

`CPTabBarTemplate` groups top-level content. Its native parser accepts list, grid, information, and point-of-interest children, subject to your category. Search, voice control, alerts, and action sheets do not belong in this container. The plugin checks Apple's `maximumTabCount`; stay within that host limit, ordinarily up to five tabs.

Child templates can set `tabTitle`, `systemIcon`, and `showsTabBadge`. To change the installed tabs, call the controller's `updateTabBarTemplates(elementId:, templates:)` with the existing tab bar ID. Do not confuse it with the model's local `updateTemplates` method. In this version, information and POI text-action dispatch also searches direct templates rather than those nested in tabs; use a root/pushed template for those actions.

<details>
<summary>Two list tabs and a native tab update</summary>

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

Future<void> installCarPlayTabs(FlutterCarplay controller) async {
  final home = CPListTemplate(
    title: 'Home',
    tabTitle: 'Home',
    systemIcon: 'house.fill',
    sections: [
      CPListSection(items: [
        CPListItem(
          text: 'Saved content',
          onPress: (complete, item) async => complete(),
        ),
      ]),
    ],
  );
  final settings = CPListTemplate(
    title: 'Settings',
    tabTitle: 'Settings',
    systemIcon: 'gear',
    sections: [],
    emptyViewTitleVariants: ['Manage settings on your phone'],
  );
  final tabs = CPTabBarTemplate(templates: [home, settings]);
  await FlutterCarplay.setRootTemplate(rootTemplate: tabs);
  await controller.updateTabBarTemplates(
    elementId: tabs.uniqueId,
    templates: [home, settings],
  );
}
```

</details>

#### CarPlay information

![Native CarPlay information template](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/information_template.webp)

`CPInformationTemplate` displays up to ten concise information items and up to three `CPTextButton` actions. Choose `leading` or `twoColumn` layout. It is a details surface, not a general-purpose Flutter form.

<details>
<summary>Information screen with native item and action updates</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<void> openCarPlayInformation(FlutterCarplay controller) async {
  final information = CPInformationTemplate(
    title: 'Collection',
    layout: CPInformationTemplateLayout.twoColumn,
    informationItems: [
      CPInformationItem(title: 'Status', detail: 'Saved'),
      CPInformationItem(title: 'Availability', detail: 'Offline'),
    ],
    actions: [
      CPTextButton(
        title: 'Open',
        textstyle: CPTextButtonStyle.confirm,
        onPress: () => debugPrint('Open selected'),
      ),
    ],
  );
  if (!await FlutterCarplay.push(template: information)) return;
  await controller.updateInformationTemplateItems(
    elementId: information.uniqueId,
    items: [CPInformationItem(title: 'Status', detail: 'Ready')],
  );
  await controller.updateInformationTemplateActions(
    elementId: information.uniqueId,
    actions: [
      CPTextButton(title: 'Done', onPress: () => FlutterCarplay.pop()),
    ],
  );
}
```

</details>

#### CarPlay point of interest

![Native CarPlay point-of-interest template](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/point_of_interest_template.webp)

`CPPointOfInterestTemplate` combines a native map with a list of up to twelve places. Each `CPPointOfInterest` supplies coordinates, concise summary/detail text, an optional pin image, and primary/secondary text buttons. It is not a turn-by-turn navigation or custom map template.

The example uses the parking entitlement for this flow. An available Dart constructor is not permission to use this template in every category. Pin artwork uses Flutter assets or asset SVGs; the native implementation fits oversized pins to 40 by 40 points.

<details>
<summary>A place with a details action</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> openCarPlayPlaces() => FlutterCarplay.push(
  template: CPPointOfInterestTemplate(
    title: 'Saved places',
    poi: [
      CPPointOfInterest(
        latitude: 51.5052,
        longitude: 7.4938,
        title: 'City parking',
        subtitle: 'Saved place',
        summary: 'View details',
        detailTitle: 'City parking',
        detailSubtitle: 'Your saved location',
        detailSummary: 'Manage this place on your phone',
        image: 'images/svg_poi.svg',
        primaryButton: CPTextButton(
          title: 'Select',
          onPress: () => debugPrint('Place selected'),
        ),
      ),
    ],
  ),
);
```

</details>

#### CarPlay alert

![Native CarPlay alert](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/alert_template.webp)

`CPAlertTemplate` is a modal for a brief status or decision. Actions use `CPAlertActionStyle.normal`, `cancel`, or `destructive`. `showAlert` returns `Future<void>`; use `onPresent(bool)` for its presentation result. Your action handler can call `popModal` to dismiss it.

<details>
<summary>Alert with a presentation callback</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<void> showCarPlayNotice() => FlutterCarplay.showAlert(
  template: CPAlertTemplate(
    titleVariants: ['Saved for your next trip'],
    onPresent: (completed) => debugPrint('Alert presented: $completed'),
    actions: [
      CPAlertAction(
        title: 'Done',
        onPress: () => FlutterCarplay.popModal(),
      ),
    ],
  ),
);
```

</details>

#### CarPlay action sheet

![Native CarPlay action sheet](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/actionsheet_template.webp)

`CPActionSheetTemplate` adds context and a message to a small set of choices. It uses the same alert-action models, but `showActionSheet` does not expose a presentation boolean or an `onPresent` callback. CarPlay allows one modal at a time; a competing or pending modal can prevent the request from being presented.

<details>
<summary>Contextual choices</summary>

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

Future<void> showCarPlayChoices() => FlutterCarplay.showActionSheet(
  template: CPActionSheetTemplate(
    title: 'This collection',
    message: 'Choose what to do next',
    actions: [
      CPAlertAction(
        title: 'Keep',
        onPress: () => FlutterCarplay.popModal(),
      ),
      CPAlertAction(
        title: 'Cancel',
        style: CPAlertActionStyle.cancel,
        onPress: () => FlutterCarplay.popModal(),
      ),
    ],
  ),
);
```

</details>

#### CarPlay search

![Native CarPlay search](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/search_template.webp)

`CPSearchTemplate` gives you the native search UI. It can be the root or a pushed screen. Return rows through `onUpdatedSearchText(text, update)`, finish selections through `onSelectedResult(item, complete)`, and optionally handle `onSearchTemplateSearchButtonPressed`.

Always supply results, including an empty list for no matches or an error, so the pending native search callback can finish. When querying a service asynchronously, keep the result tied to the latest query; the plugin stores a pending native completion rather than giving your app an independent completion for every overlapping request.

<details>
<summary>Complete local search root</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<void> installCarPlaySearch() async {
  const places = ['City parking', 'Harbor parking', 'Station parking'];
  await FlutterCarplay.setRootTemplate(
    rootTemplate: CPSearchTemplate(
      onUpdatedSearchText: (text, update) {
        final query = text.trim().toLowerCase();
        update([
          for (final place in places)
            if (query.isEmpty || place.toLowerCase().contains(query))
              CPListItem(text: place, detailText: 'Saved place'),
        ]);
      },
      onSelectedResult: (item, complete) {
        try {
          debugPrint('Selected ${item.text}');
        } finally {
          complete();
        }
      },
      onSearchTemplateSearchButtonPressed: () => debugPrint('Search submitted'),
    ),
  );
}
```

</details>

#### CarPlay voice control

![Native CarPlay voice control with an explicit microphone action](https://raw.githubusercontent.com/oguzhnatly/flutter_carplay/fee3ac3be1905c5dc8b831b8c419b90ac7f9e00f/previews/voice_control_template.webp)

`CPVoiceControlTemplate` gives a voice interaction a native visual presence: ready, listening, processing, speaking, or another state your app defines. Present it with `showVoiceControl`. It is **modal only**, never a root, pushed screen, or tab child.

The template does not record audio, transcribe speech, request microphone permission, start Siri, or supply a speech service. Your application owns those operations and their consent, privacy, interruption, and cleanup behavior.

**Category and version:** eligible navigation apps can use the basic indicator with the package's iOS 14 deployment floor. Voice-based conversational apps are a separate approved category from iOS 26.4, using `com.apple.developer.carplay-voice-based-conversation`. The CarPlay guide also describes other category/version combinations; follow the eligibility for your approved app, not just the presence of a Dart API. Its recording exception concerns eligible navigation/conversational use while the voice template is visible, not a blanket recording permission for any CarPlay app.

Action buttons and navigation bar buttons need **iOS 26.4 and Xcode 26.4 or later**. The native bridge uses compiler and runtime guards; it rejects unsupported controls with `PlatformException(code: 'unsupported_version')` rather than removing them silently.

| Contract | Requirement |
| --- | --- |
| States | One to five, with distinct nonempty identifiers; the first state is the initial presentation state |
| Titles | Omit title variants or supply a nonempty list of nonempty strings |
| Collections | States, title variants, and button collections are copied and immutable |
| State actions | `CPButton` image controls, not `CPTextButton`; maximum validated against native `CPVoiceControlState.maximumActionButtonCount` |
| Navigation controls | Up to two `CPBarButton`s per side, with distinct nonempty IDs and titles |
| Shared actions | Reuse the same `CPButton` object across states if it represents the same action; do not give unrelated buttons the same ID |
| State images | Fit within 150 by 150 points; native bridge scales down larger images |
| `repeats` | Applies to an animated native image, not a static PNG or rasterized SVG |

<details>
<summary>Basic indicator with presentation and state results</summary>

This function shows and changes the visual indicator only. It does not start audio.

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> showCarPlayActivity() async {
  var ownsPresentation = false;
  final voice = CPVoiceControlTemplate(
    voiceControlStates: [
      CPVoiceControlState(identifier: 'ready', titleVariants: ['Ready']),
      CPVoiceControlState(identifier: 'processing', titleVariants: ['Processing']),
    ],
    onDismiss: () {
      ownsPresentation = false;
      debugPrint('Voice indicator closed');
    },
  );
  try {
    if (!await FlutterCarplay.showVoiceControl(template: voice)) return false;
    ownsPresentation = true;
    final active = await voice.activateState('processing');
    debugPrint('Processing indicator active: $active');
    return active;
  } on PlatformException catch (error) {
    debugPrint('Voice presentation failed: ${error.code}: ${error.message}');
    return false;
  } finally {
    if (ownsPresentation) await FlutterCarplay.popModal();
  }
}
```

</details>

`voice.activateState(identifier)` is the instance convenience for `FlutterCarplay.activateVoiceControlState(elementId:, identifier:)`. Activation works only on the current presented template. Unknown state/template IDs return `false`. CarPlay rate-limits transitions and can ignore rapid requests. `true` means the native active identifier matches immediately after the call, not that speech capture, recognition, or playback succeeded. Do not start a voice operation whose necessary visual state was rejected.

`showVoiceControl` returns the native presentation result. It returns `false` when disconnected, when another modal is open/pending, or when successfully cancelled before presentation finishes. Invalid native input produces `invalid_argument`; native presentation/image errors use `carplay_error` unless they are one of the explicit validation/version errors. A category rejection is reported through the host's presentation completion.

Keep the event controller alive. `onDismiss` runs once for the owned voice request when the user dismisses it, programmatic dismissal/cancellation succeeds, or the car disconnects. A rejected presentation or failed dismissal does not invoke it. Failed dismissal preserves ownership so controls and a retry remain possible. Stop your audio immediately when initiating cancellation as well as in dismissal and connection cleanup; do not wait for a failed modal close to authorize stopping the microphone.

Voice presentation waits for all state and action images. Use bundled assets where possible and handle loading failures. Asset SVGs, file raster images, and remote raster images are supported here; remote/file SVGs are not rasterized.

##### Optional speech and conversational example

The [voice example](example/lib/voice_control_example.dart) composes `speech_to_text` and `flutter_tts` **in the example app only**. It recognizes a short request and speaks a local response, such as the time. It is not an assistant backend, a Siri integration, or a promise of on-device speech processing. A speech provider may use remote services.

Capture starts only after an explicit microphone action, permission approval, and successful native presentation or listening-state activation. CarPlay shows generic activity states; recognition text and response text are displayed only in the phone UI. Cancellation, modal dismissal, background, and disconnect stop the owned recognition and TTS operations. The example waits for native playback terminal events and releases the shared audio session before reuse; a method's speech-acceptance result is not playback completion.

The default example keeps the parking demo. Its phone **Voice control** button opens the optional voice page, but using that page in CarPlay still needs an eligible category. For an approved conversational app, use the separate [voice-first entry point](example/lib/voice_control_main.dart), which presents voice control at CarPlay launch with a microphone action rather than recording automatically.

<details>
<summary>Build the conversational simulator configuration</summary>

Use the repository example with Xcode 26.4 or later. The example's `Info.plist` already declares `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`.

```sh
cd example
flutter pub get
flutter build ios --config-only --simulator --debug --target lib/voice_control_main.dart
cd ios
pod install
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug \
  -sdk iphonesimulator FLUTTER_TARGET=lib/voice_control_main.dart \
  CARPLAY_ENTITLEMENTS_FILE=Conversational.entitlements build
```

</details>

`CARPLAY_ENTITLEMENTS_FILE` is the example's app-target setting and defaults to `Runner.entitlements`. Do not override `CODE_SIGN_ENTITLEMENTS` globally, which would also affect embedded frameworks. Device builds require your approved bundle identifier and provisioning profile containing the conversational entitlement; use navigation entitlements only for an approved navigation app.

Configure microphone and speech permissions on the phone before driving. Car microphone selection, USB/Bluetooth routing, audio interruptions, other audio resumption, and audio-session ownership belong to the speech provider and your host integration. Test them in a real vehicle; simulator template presentation does not establish vehicle audio routing. See the [example's provider and teardown notes](example/README.md#voice-conversation) before adapting its speech lifecycle.

#### CarPlay Now Playing

`FlutterCarplay.showSharedNowPlaying()` opens Apple's shared `CPNowPlayingTemplate`. There is no package Dart constructor for a custom Now Playing template. Your app supplies the actual media session, playback, metadata, remote-command handling, and appropriate audio configuration.

<details>
<summary>Open the shared media screen</summary>

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> openCarPlayNowPlaying() =>
    FlutterCarplay.showSharedNowPlaying(animated: true);
```

</details>

Repeated calls do not push duplicate shared instances. A `false` result can mean it is already in the stack, not only an error. The method does not create a player or start playback.

### Android Auto templates

These models map to the Android for Cars App Library, with host/category restrictions and Android-specific behavior. Native tabs support list/grid content; pane and message templates are standalone screens, not tab children in this package.

| Template | Use | Notes |
| --- | --- | --- |
| [List](#android-auto-list) | Rows, browsable menus, toggles, radio selection | Selectable sections require a separate single-section list |
| [Grid](#android-auto-grid) | Compact visual choices | Asynchronous button callback includes completion |
| [Tabs](#android-auto-tabs) | Top-level list/grid destinations | Car App API level 6; fallback to active child content |
| [Alert](#android-auto-alert) | A short decision or status | Full-screen `MessageTemplate` on the screen stack |
| [Message](#android-auto-message) | Brief information/empty/error state | Supports asynchronous title/message updates |
| [Long message](#android-auto-long-message) | Longer information | Host controls allowed presentation and parked-only restrictions |
| [Pane](#android-auto-pane) | Informational rows and actions | Rows are not tappable; up to two actions |
| Media UI | Playback controls from the app's media integration | Host-owned, not an implemented package Now Playing screen API |

#### Android Auto list

`AAListTemplate` contains `AAListSection`s and `AAListItem`s. A row can have a subtitle, leading/trailing images, a browsable affordance, or a toggle. `image:` is a constructor alias for `imageUrl:`; when both are supplied, `imageUrl` wins.

- A browsable row needs `onPress` and cannot contain a toggle.
- A toggle row cannot also use a row `onPress` handler.
- A selectable section uses `selectedIndex` and/or `onSelected`; its items cannot contain row click handlers or toggles.
- A selectable section must be the **only section** in its template and must have no title. Do not mix radio options into a sectioned browsing list.

An empty list with `emptyViewTitleVariants` uses the first variant as a no-items message. Without that message, empty content is presented as loading. Content limits and host validation still apply.

<details>
<summary>Browse and toggle rows</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> openAndroidBrowse() => FlutterAndroidAuto.push(
  template: AAListTemplate(
    title: 'Preferences',
    emptyViewTitleVariants: ['No preferences available'],
    sections: [
      AAListSection(
        title: 'On the road',
        items: [
          AAListItem(
            title: 'Saved content',
            subtitle: 'Browse your collection',
            isBrowsable: true,
            loadingMessage: 'Opening saved content',
            onPress: (complete, item) async {
              try {
                debugPrint('Open ${item.title}');
              } finally {
                await complete();
              }
            },
          ),
          AAListItem(
            title: 'Notifications',
            toggle: AAToggle(
              isChecked: true,
              onCheckedChange: (checked, item) =>
                  debugPrint('${item.title}: $checked'),
            ),
          ),
        ],
      ),
    ],
  ),
);
```

</details>

<details>
<summary>A separate valid radio-selection list</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> openAndroidSelection() => FlutterAndroidAuto.push(
  template: AAListTemplate(
    title: 'Choose a collection',
    sections: [
      AAListSection(
        selectedIndex: 0,
        onSelected: (index, item) => debugPrint('Selected $index: ${item.title}'),
        items: [
          AAListItem(title: 'Saved'),
          AAListItem(title: 'Recent'),
        ],
      ),
    ],
  ),
);
```

</details>

The event bridge updates the selected index and toggle state before calling your handler. Apply the choice to your own app state too. To replace installed content, call `controller.updateListTemplateSections(elementId: list.uniqueId, sections: newSections)`; section replacement is the native update path, not a per-row setter.

#### Android Auto grid

`AAGridTemplate` presents `AAGridButton`s. Keep the choices small, typically no more than eight, and follow the host's current grid constraints. Unlike CarPlay's grid callback, Android Auto's callback is asynchronous and receives `(complete, self)`.

<details>
<summary>Grid with a complete asynchronous handler</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> openAndroidChoices() => FlutterAndroidAuto.push(
  template: AAGridTemplate(
    title: 'Explore',
    emptyViewTitleVariants: ['No choices available'],
    buttons: [
      AAGridButton(
        titleVariants: ['Places'],
        image: 'images/svg_navigation.svg',
        loadingMessage: 'Opening places',
        onPress: (complete, button) async {
          try {
            debugPrint('Selected ${button.titleVariants.first}');
          } finally {
            await complete();
          }
        },
      ),
    ],
  ),
);
```

</details>

#### Android Auto tabs

`AATabBarTemplate` creates native tabs on hosts with **Car App API level 6 or later**, with two to four tabs. This package serializes list and grid children only. Native code takes at most the first four tabs; keep the list within that limit yourself rather than depending on truncation.

On an older host, or with fewer than two tabs, the native implementation displays the active child template without tab chrome. Initially that is the first child. It is not always a list: a grid child falls back to a grid. Native tab switching works, but `onTabBarItemSelected` is currently not exposed as a public Dart selection callback.

Android `systemIcon` is not an SF Symbols renderer. The plugin recognizes a small set of names for native fallback icons. Use a declared raster asset through `iconUrl` for an explicit tab icon; an SVG in that field is not rasterized by the current payload pipeline.

<details>
<summary>Two tabs and a native tab update</summary>

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

Future<void> installAndroidTabs() async {
  final browse = AAListTemplate(
    title: 'Browse',
    tabTitle: 'Browse',
    iconUrl: 'images/logo_flutter_1080px_clr.png',
    sections: [
      AAListSection(items: [AAListItem(title: 'Saved content')]),
    ],
  );
  final recent = AAListTemplate(
    title: 'Recent',
    tabTitle: 'Recent',
    iconUrl: 'images/logo_flutter_1080px_clr.png',
    sections: [],
    emptyViewTitleVariants: ['Nothing recent'],
  );
  final tabs = AATabBarTemplate(tabs: [browse, recent]);
  await FlutterAndroidAuto.setRootTemplate(template: tabs);
  tabs.updateTabs([browse, recent]);
  await FlutterAndroidAuto.updateTabBarTemplates(template: tabs);
}
```

</details>

#### Android Auto alert

`AAAlertTemplate` is rendered as a full-screen native `MessageTemplate` pushed onto the screen stack, not as a CarPlay-style overlay. Keep one managed alert at a time and dismiss it with `popModal()` before opening another; 1.7.0's Android bridge does not reject every overlapping alert request on your behalf.

Use `onPresent(bool)` to observe the request result and the subsequent `false` state when the alert screen is destroyed. It is a lifecycle callback, not an exactly-once completion notification. Actions use `AAAlertActionStyle` and do not receive a completion function. Follow the host's message-action count limits rather than copying three CarPlay alert actions into Android.

<details>
<summary>One-action alert</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<void> showAndroidNotice() => FlutterAndroidAuto.showAlert(
  template: AAAlertTemplate(
    title: 'Saved',
    message: 'Your collection is ready',
    onPresent: (presented) => debugPrint('Alert state: $presented'),
    actions: [
      AAAlertAction(
        title: 'Done',
        onPress: () => FlutterAndroidAuto.popModal(),
      ),
    ],
  ),
);
```

</details>

Because dismissal pops the host's top screen, keep the alert topmost until it is closed. Do not navigate another screen above it and expect `popModal` to remove an arbitrary screen by ID.

#### Android Auto message

`AAMessageTemplate` is a simple title and nonempty body for status, empty, or error states. Its `update`, `setTitle`, and `setMessage` methods return `Future<void>` and send native updates. `updateTemplate` only changes local model values.

<details>
<summary>Message and native update</summary>

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

Future<void> openAndroidMessage() async {
  final message = AAMessageTemplate(
    title: 'Collection',
    message: 'No saved content yet',
  );
  if (!await FlutterAndroidAuto.push(template: message)) return;
  await message.update(
    title: 'Collection ready',
    message: 'Saved content is now available',
  );
}
```

</details>

#### Android Auto long message

`AALongMessageTemplate` exposes Android's long-message surface and the same asynchronous update API as `AAMessageTemplate`. The body must be nonempty. Longer text remains subject to the host's category, API, and parked-only restrictions; it is not permission to show lengthy content while driving.

<details>
<summary>Long message and native update</summary>

```dart
import 'package:flutter_carplay/flutter_carplay.dart';

Future<void> openAndroidLongMessage() async {
  final message = AALongMessageTemplate(
    title: 'Before you begin',
    message: 'Manage your saved content on the phone before your journey. '
        'The car interface provides focused actions for the road.',
  );
  if (!await FlutterAndroidAuto.push(template: message)) return;
  await message.setTitle('About this collection');
}
```

</details>

#### Android Auto pane

`AAPaneTemplate` is a compact information screen, the closest supported Android counterpart to CarPlay's information template. It contains informational `AAPaneItem` rows, an optional larger image, and up to two `AAPaneAction`s, with at most one primary action. Rows cannot be tapped; actions handle interaction.

A loading pane has `isLoading: true` and no items. A loaded pane has items and `isLoading: false`. For native updates, construct the replacement with the **same `id`**, then call `FlutterAndroidAuto.updatePaneTemplate`.

<details>
<summary>Loading pane replaced with content under the same ID</summary>

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

Future<bool> openAndroidPane() async {
  final loading = AAPaneTemplate(
    title: 'Collection',
    items: [],
    isLoading: true,
  );
  if (!await FlutterAndroidAuto.push(template: loading)) return false;
  return FlutterAndroidAuto.updatePaneTemplate(
    template: AAPaneTemplate(
      id: loading.uniqueId,
      title: 'Collection',
      items: [
        AAPaneItem(title: 'Status', detail: 'Available offline'),
        AAPaneItem(title: 'Source', detail: 'Saved on your phone'),
      ],
      actions: [
        AAPaneAction(
          title: 'Open',
          isPrimary: true,
          onPress: () => debugPrint('Open selected'),
        ),
      ],
    ),
  );
}
```

</details>

## Example app

The [example project](example) is the fastest way to explore the integration. Its [default entry point](example/lib/main.dart) includes native list browsing, selectable Android lists, toggles, image/SVG/tint demonstrations, messages, panes, CarPlay search, information, and point-of-interest flows, alongside phone controls for the demo. Not every phone demo button has an Android implementation.

```sh
cd example
flutter pub get
flutter run
```

Running the app on the phone is only the first surface. For CarPlay, connect the simulator's CarPlay display or use Apple's CarPlay Simulator with the intended entitlement configuration. For Android Auto, follow Google's [Desktop Head Unit testing instructions](https://developer.android.com/training/cars/testing). A phone emulator showing Flutter widgets is not an Android Auto host.

Check launch from the car, phone-first launch, reconnect, back navigation, selection completion, empty states, and your app's permitted templates. Test both appearance modes and different display sizes. Use a real vehicle for audio routing and vehicle-specific behavior.

### More documentation

| Guide | Covers |
| --- | --- |
| [Getting Started](https://github.com/oguzhnatly/flutter_carplay/wiki/Getting-Started) | Installation and first integration |
| [iOS Setup](https://github.com/oguzhnatly/flutter_carplay/wiki/iOS-Setup) | Scene and entitlement setup |
| [Android Auto Setup](https://github.com/oguzhnatly/flutter_carplay/wiki/Android-Auto-Setup) | Service and Android host setup |
| [Templates](https://github.com/oguzhnatly/flutter_carplay/wiki/Templates) | Template-focused guides |
| [Troubleshooting](https://github.com/oguzhnatly/flutter_carplay/wiki/Troubleshooting) | Setup and runtime diagnosis |
| [FAQ](https://github.com/oguzhnatly/flutter_carplay/wiki/FAQ) | Common integration questions |
| [API reference](https://pub.dev/documentation/flutter_carplay/latest/) | Public Dart API |
| [Changelog](CHANGELOG.md) | Release history and migration notes |

### When a screen does not appear

| Symptom | First things to check |
| --- | --- |
| CarPlay scene does not connect | Exact scene delegate name, Runner target membership, shared engine registration, entitlement/profile match |
| Root exists but a push fails | Connected host, installed root, legal template type, stack depth, approved category |
| Row stays loading | Completion callback called on success and failure; current controller subscription still alive |
| Android selectable list is rejected | One untitled selectable section only; no item clicks/toggles; selected index in range |
| Android tab bar is absent | Host Car App API level, at least two valid list/grid children, fallback behavior |
| Artwork is missing | Consuming-app asset declaration, valid raster URL/file, field-specific SVG support, network permission |
| Voice controls are rejected | iOS/SDK version, approved category, control counts, image load, competing modal |

For a setup problem, include a minimal example and the platform/host configuration in a [GitHub issue](https://github.com/oguzhnatly/flutter_carplay/issues/new). For vulnerabilities, use the [private reporting process](SECURITY.md), not a public issue.

## Limitations and roadmap

The package gives you native template integration, not automatic feature parity or a finished car app. Playback, navigation engines, network services, consent, and category compliance stay with your application.

| Platform | Available today | Not implemented or still planned |
| --- | --- | --- |
| CarPlay | The catalogue above, including search and voice-state presentation | Map/navigation template, contact template, Siri integration and hands-free activation |
| Android Auto | List, grid, tabs, alerts, message, long message, and pane | Action sheet, point-of-interest, map, search, voice-control/“Hey Google” activation, and contact templates |

Android panes already cover the supported information-screen use case; that is not an unfinished CarPlay-style information port. Android's system media UI is also not a plugin-owned Now Playing implementation. Source-specific callback, image, and fallback limitations are noted at the relevant catalogue entries so you can choose a working composition.

Roadmap items describe directions, not release commitments. See [open issues](https://github.com/oguzhnatly/flutter_carplay/issues) for discussion, and the [changelog](CHANGELOG.md) for what has actually shipped. Recent releases also added Android alerts/grid/tabs, stable list identities and selection/toggles, message/pane updates, SVG asset handling, and iOS SwiftPM support.

## Community and support

Questions, small fixes, native-host testing, and reviews all help this package move forward.

- [Report an issue or request a feature](https://github.com/oguzhnatly/flutter_carplay/issues)
- [Read the contribution guide](CONTRIBUTING.md)
- [Join the Discord community](https://discord.gg/Xz6WVezFfh)
- [Sponsor ongoing development](https://github.com/sponsors/oguzhnatly)
- [See everyone who has contributed](https://github.com/oguzhnatly/flutter_carplay/graphs/contributors)

For a more active contribution, contact [info@oguzhanatalay.com](mailto:info@oguzhanatalay.com).

[![Sponsor on GitHub](https://img.shields.io/badge/Sponsor-GitHub-ea4aaa?logo=github)](https://github.com/sponsors/oguzhnatly)

## Star history

[![Star History Chart](https://star-history.dera.page/svg?repos=oguzhnatly/flutter_carplay&type=Date)](https://star-history.dera.page/#oguzhnatly/flutter_carplay&Date)

![Contributors](https://contrib.rocks/image?repo=oguzhnatly/flutter_carplay)

## License

`flutter_carplay` is released under the [MIT License](LICENSE). See [Licensing](LICENSING.md) for a plain-language guide and the full original terms.

Copyright (c) 2021 Oğuzhan Atalay
