#import <beacon_broadcast/BeaconBroadcastPlugin.h>
@import BeaconBroadcastSwift;

@implementation BeaconBroadcastPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftBeaconBroadcastPlugin registerWithRegistrar:registrar];
}
@end
