#import "FlutterMicroSvcUtilPlugin.h"
#if __has_include(<flutter_microsvc_util/flutter_microsvc_util-Swift.h>)
#import <flutter_microsvc_util/flutter_microsvc_util-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_microsvc_util-Swift.h"
#endif

@implementation FlutterMicroSvcUtilPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterMicroSvcUtilPlugin registerWithRegistrar:registrar];
}
@end
