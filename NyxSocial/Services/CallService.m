#import "CallService.h"
#import "RealtimeClient.h"
#import <CallKit/CallKit.h>

@interface CallService ()
@property (nonatomic, strong) CXProvider *provider;
@end

@implementation CallService
+ (instancetype)shared { static id s; static dispatch_once_t once; dispatch_once(&once, ^{ s=[self new];}); return s; }

- (instancetype)init {
    if ((self=[super init])) {
        CXProviderConfiguration *cfg = [[CXProviderConfiguration alloc] initWithLocalizedName:@"NyxSocial"];
        cfg.supportsVideo = YES;
        cfg.maximumCallsPerCallGroup = 1;
        cfg.supportedHandleTypes = [NSSet setWithObject:@(CXHandleTypeGeneric)];
        _provider = [[CXProvider alloc] initWithConfiguration:cfg];
    }
    return self;
}

- (NSString *)startOutgoingCallToUid:(NSNumber *)toUid media:(NSString *)media {
    NSString *callId = [NSUUID UUID].UUIDString;
    [[RealtimeClient shared] sendJSON:@{@"type":@"call_offer", @"toUid":toUid?:@0, @"callId":callId, @"sdp":@"", @"media":media?:@"audio"}];
    return callId;
}

- (void)handleWS:(NSDictionary *)json {
    NSString *type = json[@"type"];
    if (!type) return;
    if ([type isEqualToString:@"call_offer"]) {
        NSString *callId = json[@"callId"];
        NSString *fromUsername = json[@"fromUsername"] ?: @"Unknown";
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:callId] ?: [NSUUID UUID];

        CXCallUpdate *u = [CXCallUpdate new];
        u.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:fromUsername];
        u.hasVideo = [[[json[@"media"] ?: @"audio"] lowercaseString] isEqualToString:@"video"];

        [self.provider reportNewIncomingCallWithUUID:uuid update:u completion:^(NSError * _Nullable error) {
            if (error) NSLog(@"report incoming error: %@", error);
        }];
    }
}
@end
