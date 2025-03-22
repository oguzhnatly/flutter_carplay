#import "FlutterCarplayPlugin.h"
#if __has_include(<car_play/car_play-Swift.h>)
#import <car_play/car_play-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "car_play-Swift.h"
#endif

@implementation FlutterCarplayPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterCarplayPlugin registerWithRegistrar:registrar];
}
@end
